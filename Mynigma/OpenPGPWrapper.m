//
//	Copyright © 2012 - 2015 Roman Priebe
//
//	This file is part of M - Safe email made simple.
//
//	M is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	M is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with M.  If not, see <http://www.gnu.org/licenses/>.
//





#import "OpenPGPWrapper.h"
#import "MynigmaFeedback.h"
#import "PGPMessage.h"
#import "fmemopen.h"
#import "netpgp.h"
#import "types.h"
#import "keyring.h"
#import "memory.h"
#import "AddressDataHelper.h"
#import <MailCore/MailCore.h>
#import "EmailRecipient.h"
#import "crypto.h"
#import "MynigmaPrivateKey+Category.h"
#import "MynigmaPublicKey+Category.h"


#import "crypto.h"






static netpgp_t* _netPGP;


static NSURL* _publicKeyRingURL;
static NSURL* _privateKeyRingURL;
static NSURL* _homeDirectory;

static NSString* _password;

static dispatch_queue_t _OpenPGPWrapper_queue;


@implementation OpenPGPWrapper

#pragma mark -
#pragma mark - Private methods


#pragma mark - NetPGP initialisation

+ (netpgp_t*)buildnetpgp
{
    _OpenPGPWrapper_queue = dispatch_queue_create("OpenPGPWrapper lock queue", NULL);

    netpgp_t *netpgp = calloc(0x1, sizeof(netpgp_t));

    NSURL* applicationSupportDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];

    NSURL* keyRingDirectory = [applicationSupportDirectory URLByAppendingPathComponent:@"PGPKeyRing" isDirectory:YES];

    NSURL* publicKeyRingURL = [keyRingDirectory URLByAppendingPathComponent:@"PGPPublic.keyring"];
    NSURL* privateKeyRingURL = [keyRingDirectory URLByAppendingPathComponent:@"PGPPublic.keyring"];

    //prevent iCloud syncing for key rings
    NSError* error = nil;
    [keyRingDirectory setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    if(error)
        NSLog(@"Error setting NSURLIsExcludedFromBackupKey for key ring directory: %@", error);

    error = nil;
    [publicKeyRingURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    if(error)
        NSLog(@"Error setting NSURLIsExcludedFromBackupKey for public key ring: %@", error);

    error = nil;
    [privateKeyRingURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error];
    if(error)
        NSLog(@"Error setting NSURLIsExcludedFromBackupKey for private key ring: %@", error);

    error = nil;

    //create the key ring directory, if necessary...
    NSDictionary *properties = [keyRingDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];

    if(!properties)
    {
        BOOL ok = NO;
        if([error code] == NSFileReadNoSuchFileError)
        {
            ok = [[NSFileManager defaultManager] createDirectoryAtPath:[keyRingDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if(!ok)
        {
            NSLog(@"Error creating directory: %@", error);
            return nil;
        }
    }

    _homeDirectory = keyRingDirectory;
    _publicKeyRingURL = publicKeyRingURL;
    _privateKeyRingURL = privateKeyRingURL;
    
    if(_homeDirectory.path)
    {
        char *directory_path = calloc(_homeDirectory.path.length+1, sizeof(char));
        strcpy(directory_path, _homeDirectory.path.UTF8String);

        netpgp_set_homedir(netpgp, directory_path, NULL, 0);

        free(directory_path);
    }

    if (_privateKeyRingURL.path)
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:_privateKeyRingURL.path])
        {
            [[NSFileManager defaultManager] createFileAtPath:_privateKeyRingURL.path contents:nil attributes:@{NSFilePosixPermissions: [NSNumber numberWithShort:0600]}];
        }
        netpgp_setvar(netpgp, "secring", _privateKeyRingURL.path.UTF8String);
    }

    if (_publicKeyRingURL.path)
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:_publicKeyRingURL.path])
        {
            [[NSFileManager defaultManager] createFileAtPath:_publicKeyRingURL.path contents:nil attributes:@{NSFilePosixPermissions: [NSNumber numberWithShort:0600]}];
        }
        netpgp_setvar(netpgp, "pubring", _publicKeyRingURL.path.UTF8String);
    }

    if (_password)
    {
        const char* cstr = [_password stringByAppendingString:@"\n"].UTF8String;
        netpgp->passfp = fmemopen((void *)cstr, sizeof(char) * (_password.length + 1), "r");
    }

    /* 4 MiB for a memory file */
    netpgp_setvar(netpgp, "max mem alloc", "4194304");

    //FIXME: use sha1 because sha256 crashing, don't know why yet
    netpgp_setvar(netpgp, "hash", "sha256");

    // Custom variable
    //netpgp_setvar(netpgp, "dont use subkey to encrypt", "1");

#if DEBUG
    netpgp_incvar(netpgp, "verbose", 1);
    netpgp_set_debug(NULL);
#endif

    if (!netpgp_init(netpgp))
    {
        NSLog(@"Can't initialize netpgp stack");
        free(netpgp);
        return nil;
    }

    return netpgp;
}

+ (void)finishnetpgp:(netpgp_t*)netpgp
{
    if (!netpgp) {
        return;
    }

    netpgp_end(netpgp);
    free(netpgp);
}



+ (netpgp_t*)netPGP
{
    if(_netPGP)
        _netPGP = [OpenPGPWrapper buildnetpgp];

    return _netPGP;
}

/* resolve the userid */
static const __ops_key_t *
resolve_userid(netpgp_t *netpgp, const __ops_keyring_t *keyring, const char *userid)
{
    const __ops_key_t	*key;
    __ops_io_t		*io;

    if (userid == NULL) {
        userid = netpgp_getvar(netpgp, "userid");
        if (userid == NULL)
            return NULL;
    } else if (userid[0] == '0' && userid[1] == 'x') {
        userid += 2;
    }
    io = netpgp->io;
    if ((key = __ops_getkeybyname(io, keyring, userid)) == NULL) {
        (void) fprintf(io->errs, "Can't find key '%s'\n", userid);
    }
    return key;
}


+ (const __ops_key_t*)publicKeyForKeyLabel:(NSString*)keyLabel
{
    netpgp_t *netpgp = [self netPGP];
    return resolve_userid(netpgp, netpgp->pubring, keyLabel.UTF8String);
}


//+ (NSData*)encryptData:(NSData*)inData options:(OpenPGPEncryptionOption)options withKeyLabels:(NSArray*)keyLabels
//{
//    return nil;
//
//    __block NSData *result = nil;
//
//    dispatch_sync(_OpenPGPWrapper_queue, ^{
//        netpgp_t *netpgp = [self netPGP];
//        if (netpgp) {
//
//            if (options & OpenPGPEncryptionOptionDontUseSubkeys)
//            {
//                netpgp_setvar(netpgp, "dont use subkey to encrypt", "1");
//            }

//            int insize = (int)inData.length;
//            void *inbuf = calloc(inData.length, sizeof(Byte));
//            memcpy(inbuf, inData.bytes, inData.length);
//
//    dispatch_sync(_OpenPGPWrapper_queue, ^{
//        netpgp_t *netpgp = [self netPGP];
//        if (netpgp) {
//
//            if (options & OpenPGPEncryptionOptionDontUseSubkeys)
//            {
//                netpgp_setvar(netpgp, "dont use subkey to encrypt", "1");
//            }
//
////            int insize = (int)inData.length;
////            void *inbuf = calloc(inData.length, sizeof(Byte));
////            memcpy(inbuf, inData.bytes, inData.length);
////
////            NSNumber* encryptWithArmourOption = [[NSUserDefaults standardUserDefaults] objectForKey:@"OpenPGPWrapper encrypt with armour"];
////
////            NSInteger maxsize = (unsigned)atoi(netpgp_getvar(netpgp, "max mem alloc"));
////            void *outbuf = calloc(sizeof(Byte), maxsize);
////            int outsize = 0;
////
////            const __ops_key_t* keypair;
////            __ops_memory_t* enc;
////                size_t			 m;
////
////                __ops_io_t* io = netpgp->io;
//
//                __ops_io_t* io = netpgp->io;

//            if((keypair = [OpenPGPWrapper publicKeyForKeyLabel:keyLabels.firstObject]) != NULL)
//            {
//                enc = __ops_encrypt_buf(io, inbuf, insize, keypair, (unsigned)encryptWithArmourOption.boolValue, netpgp_getvar(netpgp, "cipher"), netpgp_getvar(netpgp, "dont use subkey to encrypt") != NULL ? 1 : 0);
//                m = MIN(__ops_mem_len(enc), outsize);
//                (void) memcpy(outbuf, __ops_mem_data(enc), m);
//                __ops_memory_free(enc);
//                outsize = (int)m;
//            }
//
//            if (outsize > 0)
//            {
//                result = [NSData dataWithBytesNoCopy:outbuf length:outsize freeWhenDone:YES];
//            }
//
//            [self finishnetpgp:netpgp];
//
//            if (inbuf)
//                free(inbuf);
//        }
//    });
//
//    return result;
//}



+ (NSData*)signData:(NSData*)inData withKeyLabel:(NSString*)keyLabel
{
    return nil;

//    __block NSData *result = nil;
//
//    dispatch_sync(lock_queue, ^{
//        netpgp_t *netpgp = [self buildnetpgp];
//        if (netpgp) {
//            void *inbuf = calloc(inData.length, sizeof(Byte));
//            memcpy(inbuf, inData.bytes, inData.length);
//
//            NSInteger maxsize = (unsigned)atoi(netpgp_getvar(netpgp, "max mem alloc"));
//            void *outbuf = calloc(sizeof(Byte), maxsize);
//            int outsize = netpgp_sign_memory(netpgp, self.userId.UTF8String, inbuf, inData.length, outbuf, maxsize, self.armored ? 1 : 0, 0 /* !cleartext */);
//
//            if (outsize > 0) {
//                result = [NSData dataWithBytesNoCopy:outbuf length:outsize freeWhenDone:YES];
//            }
//
//            [self finishnetpgp:netpgp];
//
//            if (inbuf)
//                free(inbuf);
//        }
//    });
//
//    return result;
}









//+ (NSData*)encryptMessage:(PGPMessage*)message withFeedback:(MynigmaFeedback*)feedback
//{
//    //first collect the data to be signed & encrypted, as well as the keys
//
//    EmailRecipient* sender = [AddressDataHelper senderAsEmailRecipientForMessage:message addIfNotFound:YES];
//
//    NSString* senderKeyLabel = [MynigmaPrivateKey privateKeyLabelForEmailAddress:sender.email];
//
//
//    NSArray* emailRecipients = [AddressDataHelper nonSenderEmailRecipientsForMessage:message];
//
//    NSArray* encryptionKeyLabels = [MynigmaPublicKey encryptionKeyLabelsForRecipients:emailRecipients allowErrors:NO];
//
//
//    MCOMessageBuilder* messageBuilder = [MCOMessageBuilder new];
//
//
//
//
//
//    NSData* dataToBeSigned = [messageBuilder dataForEncryption];
//
//    NSData* signature = [self signData:dataToBeSigned withKeyLabel:senderKeyLabel];
//
//    //then encrypt it
//    NSData* dataToBeEncrypted = [messageBuilder openPGPSignedMessageDataWithSignatureData:signature];
//
//
//    NSData* encryptedData = [self encryptData:dataToBeEncrypted options:0 withKeyLabels:encryptionKeyLabels];
//
//    NSData* encryptedOpenPGPMessageData = [messageBuilder openPGPEncryptedMessageDataWithEncryptedData:encryptedData];
//
//    return encryptedOpenPGPMessageData;
//}

+ (PGPMessage*)decryptData:(NSData*)data withFeedback:(MynigmaFeedback*)feedback;
{
    

    return nil;
}


@end
