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





#import "SMIMEPublicKey+Category.h"
#import "NSData+Base64.h"
#import <openssl/pem.h>
#import <openssl/safestack.h>
#import <openssl/pkcs12.h>
#import <openssl/pkcs7.h>
#import <openssl/asn1.h>
#import <openssl/asn1t.h>
#import <openssl/asn1_mac.h>
#import <openssl/err.h>
#import <openssl/conf.h>



static NSNumber* loadedOpenSSL;



@implementation SMIMEPublicKey (Category)




//a dictionary describing a Mynigma public key corresponding to the specified label - this dictionary is used for adding a key to the keychain and contains more attributes than the search dictionary, just to be on the safe side, since attributes might change in future versions
+ (NSMutableDictionary*)publicKeyAdditionDictForLabel:(NSString*)keyLabel
{
#if TARGET_OS_IPHONE
    
    NSMutableDictionary* passDict = [NSMutableDictionary new];
    
    NSString* attrLabel = [NSString stringWithFormat:@"Mynigma S/MIME key %@", keyLabel];
    
    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrApplicationTag];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    
    return passDict;
    
#else
    
    NSMutableDictionary* passDict = [NSMutableDictionary new];
    [passDict setObject:(id)kSecAttrKeyTypeRSA forKey:(id)kSecAttrKeyType];
    [passDict setObject:@4096 forKey:(id)kSecAttrKeySizeInBits];
    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    
    //    SecAccessRef accessRef = [KeychainHelper accessRef:NO];
    //    if(accessRef)
    //        [passDict setObject:(__bridge id)accessRef forKey:kSecAttrAccess];
    
    NSString* attrLabel = [NSString stringWithFormat:@"Mynigma S/MIME key %@", keyLabel];
    
    
        [passDict setObject:@"Mynigma S/MIME key" forKey:(__bridge id)kSecAttrDescription];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];
        [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
        [passDict setObject:@YES forKey:(__bridge id)kSecAttrCanEncrypt];
    
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    
    [passDict setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];
    
    [passDict setObject:@YES forKey:kSecAttrIsPermanent];
    
    return passDict;
    
#endif
}


int passwordCallback(char *buf, int size, int rwflag, void *u)
{
    return -1;
}

+ (NSString*)stringFromASN1Integer:(ASN1_INTEGER*)ASN1Integer
{
    BIGNUM *bn = ASN1_INTEGER_to_BN(ASN1Integer, NULL);
    
    char *result;
    result = BN_bn2hex(bn);
    
    return [[NSString alloc] initWithCString:result encoding:NSUTF8StringEncoding];
}

+ (NSString*)stringFromASN1String:(ASN1_STRING*)ASN1String
{
    char *data,*result;
    BIO *bio = BIO_new(BIO_s_mem());
    ASN1_STRING_print(bio, ASN1String);
    
    long n = BIO_get_mem_data(bio, &data);
    result = (char *) malloc (n+1);
    result[n]='\0';
    memcpy(result,data,n);
    
    BIO_free(bio);
    bio=NULL;
    return [[NSString alloc] initWithCString:result encoding:NSASCIIStringEncoding];
}

+ (NSDate*)dateFromASN1Time:(ASN1_TIME*)time
{
    char *data,*result;
    BIO *bio = BIO_new(BIO_s_mem());
    ASN1_TIME_print(bio, time);
    
    long n = BIO_get_mem_data(bio, &data);
    result = (char *) malloc (n+1);
    result[n]='\0';
    memcpy(result,data,n);
    
    NSString *date = [[NSString alloc] initWithCString:result encoding:NSASCIIStringEncoding];
    
    //Jan 21 10:20:56 2010 GMT
    NSDateFormatter *format=[[NSDateFormatter alloc] init];
    [format setFormatterBehavior: NSDateFormatterBehavior10_4];
    
    [format setDateFormat:@"LLL d HH:mm:ss yyyy z"];
    
    NSDate *cdate=[format dateFromString:date];
    
    BIO_free(bio);
    bio=NULL;
    
    return cdate;
}

+ (NSData*)dataForEVPPrivateKey:(EVP_PKEY*)privateKeyEVP
{
    BIO* privateKeyBIO = BIO_new(BIO_s_mem());

//    PEM_write_bio_PrivateKey(privateKeyBIO, privateKeyEVP, NULL, NULL, 0, NULL, NULL);

    PEM_write_bio_PKCS8PrivateKey(privateKeyBIO, privateKeyEVP, NULL, NULL, 0, NULL, NULL);

    int len = BIO_pending(privateKeyBIO);

    char *keyBytes = malloc(len);

    BIO_read(privateKeyBIO, keyBytes, len);

    NSData* privateKeyData = [NSData dataWithBytes:keyBytes length:len];

    if(keyBytes)
        free(keyBytes);
    
    return privateKeyData;
}

+ (NSData*)dataForEVPPublicKey:(EVP_PKEY*)publicKeyEVP
{
    BIO* publicKeyBIO = BIO_new(BIO_s_mem());

    PEM_write_bio_PUBKEY(publicKeyBIO, publicKeyEVP);


    int len = BIO_pending(publicKeyBIO);

    char *keyBytes = malloc(len);

    BIO_read(publicKeyBIO, keyBytes, len);

    NSData* publicKeyData = [NSData dataWithBytes:keyBytes length:len];

    if(keyBytes)
        free(keyBytes);

    return publicKeyData;
}

+ (BOOL)parseASN1DataIntoImportedCertificate:(NSData*)pemData withPasswordCallback:(void(^)(pem_password_cb *passwordReturnCallback))passwordCallback
{
    BIO* pemBIO = BIO_new_mem_buf((void*)pemData.bytes, (int)pemData.length);
    
    pem_password_cb* pwCallback = objc_unretainedPointer(passwordCallback);
    
    
//    X509* cert = 

    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();

        OpenSSL_add_all_algorithms();

        OPENSSL_config(NULL);

        loadedOpenSSL = @YES;
    }

    STACK_OF(X509_INFO)* stackOfCerts = PEM_X509_INFO_read_bio(pemBIO, NULL, pwCallback, NULL);

    int numberOfCerts = sk_X509_INFO_num(stackOfCerts);




    unsigned long error_code = ERR_get_error();

    const char* error_string = ERR_error_string(error_code, NULL);

    NSLog(@"Error: %@", [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding]);





    for(int i = 0; i < numberOfCerts; i++)
    {
        X509_INFO* x509Info = sk_X509_INFO_value(stackOfCerts, i);
        
        X509* certificate = x509Info->x509;
        
        X509_PKEY* privateKey = x509Info->x_pkey;
        
        if(privateKey)
        {
            //there is a private key(!!)
            
//            x509_

//            ASN1_OCTET_STRING* encryptedKey = privateKey->enc_pkey;

            EVP_PKEY* privateKeyEVP = privateKey->dec_pkey;

            X509_PUBKEY* publicKeyEVP = NULL;

            X509_PUBKEY_set(&publicKeyEVP, privateKeyEVP);

//            NSData* publicKeyData = [self dataForEVPPublicKey:privateKeyEVP];

//            NSData* privateKeyData = [self dataForEVPPrivateKey:privateKeyEVP];

            return YES;
        }
        else if(certificate)
        {
            //if there is no private key, there should at least be a certificate

            //first try to get the public key data
            X509_CINF* certInfo = certificate->cert_info;

            X509_PUBKEY* publicKey = certInfo->key;

            EVP_PKEY* publicKeyEVP = X509_PUBKEY_get(publicKey);


            NSData* publicKeyData = [self dataForEVPPublicKey:publicKeyEVP];


            if(publicKeyData.length)
            {
                //OK, let's go ahead with the key creation(!)
//            NSString* version = [self stringFromASN1Integer:certInfo->version];
//            NSString* serialNumber = [self stringFromASN1Integer:certInfo->serialNumber];


//            X509_VAL* validity = certInfo->validity;

//            ASN1_TIME* notAfter = validity->notAfter;
//
//            ASN1_TIME* notBefore = validity->notBefore;

//            NSDate* notBeforeDate = [self dateFromASN1Time:notBefore];
//
//            NSDate* notAfterDate = [self dateFromASN1Time:notAfter];
//
//
//            X509_NAME* issuerName = certInfo->issuer;
//
//            X509_NAME* subjectName = certInfo->subject;



            }
//            NSLog(@"%@ %@ %p %p %@ %@", version, serialNumber, issuerName, validity, notBeforeDate, notAfterDate);

//            NSString* name = [self stringFromASN1String:];

            return YES;
        }
        else
        {
            NSLog(@"Error parsing X509 info object!!");
        }
    }

    if(numberOfCerts < 1)
    {
        //try a different format
        EVP_PKEY* privateKey = PEM_read_bio_PrivateKey(pemBIO, NULL, NULL, NULL);

        if(privateKey)
        {
            return YES;
        }
        else
        {
//            PKCS12* pkcs12 = PKCS12_new();
//            PKCS12_se
//            PKCS12_parse(<#PKCS12 *p12#>, <#const char *pass#>, <#EVP_PKEY **pkey#>, <#X509 **cert#>, <#struct stack_st_X509 **ca#>)
//            PEM_read_bio_PKCS8_PRIV_KEY_INFO(pemBIO, <#PKCS8_PRIV_KEY_INFO **x#>, <#pem_password_cb *cb#>, <#void *u#>)
        }
    }

    return NO;
}



+ (BOOL)importKeyFromFileWithURL:(NSURL*)fileURL
{
    NSData* data = [NSData dataWithContentsOfURL:fileURL];
    
    //we first need to work out what kind of data it is...
    NSString* dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    //check for an armour
    NSArray* armourComponents = [dataString componentsSeparatedByString:@"-----"];

    BOOL isArmoured = armourComponents.count >= 4;

    //we want the data to be in base64 and armoured
    //if the provided data is not in this format, we will adjust it
    NSData* armouredBase64Data = data;

    if(!isArmoured)
    {
        NSString* unarmouredString = nil;

        //try base64-decoding the data
        //if this works, we'll assume that it is indeed base64
        NSData* base64DecodedData = [NSData dataWithBase64String:dataString];

        if(base64DecodedData.length)
        {
            //dataString is already base64-encoded data
            unarmouredString = dataString;
        }
        else
        {
            //assume it's raw data - encode it in base64
            unarmouredString = [data base64In64ByteChunks];
        }

        NSString* armourType = @"CERTIFICATE";

        //use "RSA PRIVATE KEY" even for DSS keys, just "PRIVATE KEY" won't work
        if([@[@"pri", @"key"] containsObject:fileURL.pathExtension])
            armourType = @"RSA PRIVATE KEY";

        NSString* armouredString = [NSString stringWithFormat:@"-----BEGIN %@-----\r\n%@\r\n-----END %@-----\r\n", armourType, dataString, armourType];

        armouredBase64Data = [armouredString dataUsingEncoding:NSUTF8StringEncoding];
    }

    return [self parseASN1DataIntoImportedCertificate:armouredBase64Data withPasswordCallback:nil];

//
//
//    //first try base64-decoding the data
//    //if this works, we'll assume that it is indeed base64
//    
//    NSData* rawData = [NSData dataWithBase64String:base64String];
//    
//    if(rawData)
//        return [self parseASN1DataIntoImportedCertificate:rawData withPasswordCallback:nil];
//    else
//        return [self parseASN1DataIntoImportedCertificate:data withPasswordCallback:nil];
//    

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    //#if TARGET_OS_IPHONE
    //
    //    NSData* DERData = [OpenSSLWrapper DERFileFromPEMKey:data withPassphrase:nil];
    //
    //    dataString = [[NSString alloc] initWithData:DERData encoding:NSUTF8StringEncoding];
    //
    //    //     NSLog(@"DER data string: %@", dataString);
    //
    //    if(!DERData)
    //    {
    //        NSLog(@"Cannot add public key: DERData is nil!!");
    //
    //        return;
    //    }
    //
    //    SecCertificateRef cert = SecCertificateCreateWithData (kCFAllocatorDefault, (__bridge CFDataRef)(DERData));
    //    CFArrayRef certs = CFArrayCreate(kCFAllocatorDefault, (const void **) &cert, 1, NULL);
    //
    //    SecTrustRef trustRef;
    //    SecPolicyRef policy = SecPolicyCreateBasicX509();
    //    SecTrustCreateWithCertificates(certs, policy, &trustRef);
    //    SecTrustResultType trustResult;
    //    SecTrustEvaluate(trustRef, &trustResult);
    //    SecKeyRef publicKeyRef = SecTrustCopyPublicKey(trustRef);
    //
    //    __block NSMutableDictionary* passDict = [self publicKeyAdditionDictForLabel:keyLabel];
    //
    //    [passDict setObject:(__bridge id)(publicKeyRef) forKey:(__bridge id)kSecValueRef];
    //    [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnPersistentRef];
    //
    //    CFTypeRef result = NULL;
    //    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);
    //
    //    if (status != noErr)
    //    {
    //        if(result)
    //            CFRelease(result);
    //        NSLog(@"Error adding keychain item! %@",[NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
    //        return;
    //    }
    //
    //    [SMIMEPublicKey make]
    //
    //#else
    //
    //    if([self havePublicKeychainItemWithLabel:keyLabel])
    //    {
    //        NSArray* dataArray = [KeychainHelper persistentRefsForPublicKeychainItemWithLabel:keyLabel];
    //        if(dataArray.count<2)
    //            return nil;
    //
    //        return forEncryption?dataArray[0]:dataArray[1];
    //    }
    //
    //
    //    //first import the key: turn the PEM file into a SecKeyRef
    //    SecItemImportExportKeyParameters params = [self importExportParams:forEncryption];
    //
    //    SecExternalItemType itemType = kSecItemTypePublicKey;
    //    SecExternalFormat externalFormat = kSecFormatPEMSequence;
    //    int flags = 0;
    //
    //    CFArrayRef temparray;
    //    OSStatus oserr = SecItemImport((__bridge CFDataRef)data, NULL, &externalFormat, &itemType, flags, &params, NULL /*don't add to a keychain*/, &temparray);
    //    if (oserr != noErr || CFArrayGetCount(temparray)<1)
    //    {
    //        NSLog(@"Error importing key! %@",[NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    //        return nil;
    //    }
    //
    //    SecKeyRef encrKeyRef = (SecKeyRef)CFArrayGetValueAtIndex(temparray, 0);
    //
    //    //now add it to the keychain - without a label at first (using a label doesn't work on add, so need to update the item later...)
    //    __block NSMutableDictionary* passDict = [self publicKeyAdditionDictForLabel:keyLabel forEncryption:forEncryption];
    //
    //    [passDict setObject:(__bridge id)(encrKeyRef) forKey:kSecValueRef];
    //
    //    [passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];
    //
    //    [passDict removeObjectForKey:(__bridge id)kSecAttrLabel];
    //
    //    CFTypeRef result;
    //
    //    oserr = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);
    //
    //    if(oserr != noErr)
    //    {
    //        NSLog(@"Error adding public keychain item: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    //    }
    //
    //    NSData* persistentRef = CFArrayGetValueAtIndex(result, 0);
    //
    //    //almost done - just need to add the missing label
    //    NSMutableDictionary* query = [NSMutableDictionary dictionaryWithDictionary:@{(__bridge id)kSecValuePersistentRef:persistentRef}];
    //
    //    query[(__bridge id)kSecClass] = (__bridge id)kSecClassKey;
    //
    //    NSMutableDictionary* newAttributes = [NSMutableDictionary new];
    //
    //    NSString* attrLabel = forEncryption?[NSString stringWithFormat:@"Mynigma encryption key %@", keyLabel]:[NSString stringWithFormat:@"Mynigma signature key %@", keyLabel];
    //
    //    newAttributes[(__bridge id)kSecAttrLabel] = attrLabel;
    //
    //    SecKeychainItemRef itemRef = (SecKeychainItemRef)[KeychainHelper keyRefForPersistentRef:persistentRef];
    //
    //    oserr = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)newAttributes);
    //    if (oserr != noErr)
    //    {
    //        NSLog(@"Error updating keychain item! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
    //    }
    //    
    //    [self setAccessRightsForKey:itemRef withDescription:@"Mynigma public key"];
    //    
    //    return persistentRef;
    //    
    //#endif
}



+ (BOOL)havePublicKeyWithLabel:(NSString*)keyLabel
{
    return NO;
}

@end
