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





#import <XCTest/XCTest.h>
#import "TestHarness.h"
#import "AppDelegate.h"
#import <openssl/pkcs12.h>
#import <openssl/pkcs7.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>
#import <openssl/bio.h>
#import <openssl/pem.h>
#import <openssl/err.h>
#import <openssl/stack.h>
#import <openssl/safestack.h>
#import <openssl/evp.h>
#import "DataWrapHelper.h"
#import "KeychainHelper.h"
#import "EncryptionHelper.h"
#import <Security/Security.h>
#import "OpenSSLWrapper.h"
#import "AppleEncryptionWrapper.h"
#import "NSData+Base64.h"
#import "TestHelper.h"
#import "AppDelegate.h"
#import "MynigmaFeedback.h"





@interface Certificate_Parser_Tests : TestHarness

@end

@implementation Certificate_Parser_Tests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAppleSignatureAndOpenSSLVerification
{
    NSString* keyLabel = [self keyLabel1];

    NSData* someData = [@"dje3J@*ej@(j(j2" dataUsingEncoding:NSUTF8StringEncoding];

    NSData* hash = [AppleEncryptionWrapper SHA512DigestOfData:someData];
    
    MynigmaFeedback* feedback = nil;

    NSData* signedHash = [EncryptionHelper signHash:hash withKeyWithLabel:keyLabel withFeedback:&feedback];
    
    XCTAssertNil(feedback);

    XCTAssert(signedHash);

    MynigmaFeedback* result = [EncryptionHelper verifySignature:signedHash ofHash:hash version:MYNIGMA_VERSION withKeyLabel:keyLabel];

    XCTAssertNil(result);

    BOOL openSSLResult = [OpenSSLWrapper verifySignature:signedHash ofHash:hash withKeyLabel:keyLabel];

    XCTAssert(openSSLResult);
}


- (void)d_testKeyBackUpUnwrap
{
    NSURL* fileURL = [BUNDLE URLForResource:@"Key-Backup-PKCS12-Password-Armour" withExtension:@"myn"];

    NSData* fileData = [NSData dataWithContentsOfURL:fileURL];

    XCTAssertNotNil(fileData);

    [DataWrapHelper unwrapAccountDataPackage:fileData withCallback:^(NSArray *importedPrivateKeyLabels, NSArray *errorLabels) {

        XCTAssertTrue(importedPrivateKeyLabels.count>0);
        XCTAssertTrue(errorLabels.count==0);

    }];
}


- (void)addPEM:(NSData*)PEMData forKeyLabel:(NSString*)keyLabel
{
    CFArrayRef results = NULL;

    NSString* passphrase = @"password";

    NSDictionary* optionsDict = @{(__bridge id)kSecImportExportPassphrase:passphrase};

    OSStatus status = SecPKCS12Import((__bridge CFDataRef)PEMData, (__bridge CFDictionaryRef)optionsDict, &results);

    if (status != errSecSuccess || !results)
    {
        if(results)
            CFRelease(results);

        NSLog(@"Failed to import private key!! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);

    }
    else
    {
        CFDictionaryRef myIdentityAndTrust = CFArrayGetValueAtIndex (results, 0);
        const void *tempIdentity = NULL;
        tempIdentity = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemIdentity);
        CFRetain(tempIdentity);

        SecIdentityRef outIdentity = (SecIdentityRef)tempIdentity;
        const void *tempTrust = NULL;
        tempTrust = CFDictionaryGetValue (myIdentityAndTrust, kSecImportItemTrust);

        CFRetain(tempTrust);
        //SecTrustRef outTrust = (SecTrustRef)tempTrust;

        SecKeyRef privateKeyRef = NULL;

        SecIdentityCopyPrivateKey(outIdentity, &privateKeyRef);

        if(privateKeyRef)
        {
            NSLog(@"SSSSSUUUUUUCCCCCCCCCCCCCCCCEEEEEEEESSSSSSSSSSSSS!!!!!!!");
        }
    }



    BOOL forEncryption = YES;

    NSMutableDictionary* passDict = [NSMutableDictionary new];

    NSString* attrLabel = [NSString stringWithFormat:@"%@%@", forEncryption?@"Mynigma encryption key ":@"Mynigma signature key ", keyLabel];

    [passDict setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrApplicationTag];
    [passDict setObject:attrLabel forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [passDict setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];
    

    [passDict setObject:PEMData forKey:(__bridge id)kSecValueRef];
    //[passDict setObject:@YES forKey:(__bridge id)kSecReturnPersistentRef];


//    CFTypeRef result = NULL;
//    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)passDict, &result);
//
//    if (status != errSecSuccess || !result)
//    {
//        if(result)
//            CFRelease(result);
//        NSLog(@"Error adding keychain item!!! %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
//    }


}

- (void)d_testDirectImportOfPKCS12KeyFile
{
    NSURL* fileURL = [BUNDLE URLForResource:@"Key-File-PKCS12-Password-New" withExtension:@"txt"];

    NSData* keyData = [NSData dataWithContentsOfURL:fileURL];

    XCTAssertNotNil(keyData);
    
    [self addPEM:keyData forKeyLabel:@"keyLabel34049@mynigma.org|2314"];

}


- (void)testKeyParsing
{
    NSURL* fileURL = [BUNDLE URLForResource:@"Key-File-WrappedPKCS8-Password-Armour" withExtension:@"txt"];

    NSData* keyData = [NSData dataWithContentsOfURL:fileURL];

    XCTAssertNotNil(keyData);

    NSString* unUTF8edString = [[NSString alloc] initWithData:keyData encoding:NSUTF8StringEncoding];

    NSString* pemString = unUTF8edString;//[NSString stringWithFormat:@"-----BEGIN RSA PRIVATE KEY-----\r\n%@\r\n-----END RSA PRIVATE KEY-----", unbase64edString];

    pemString = [pemString stringByReplacingOccurrencesOfString:@"RSA PUBLIC" withString:@"PUBLIC"];
    pemString = [pemString stringByReplacingOccurrencesOfString:@"RSA PRIVATE" withString:@"PRIVATE"];

    NSData* pemData = keyData; //[pemString dataUsingEncoding:NSUTF8StringEncoding]; //keyData;//[[NSData alloc] initWithBase64EncodedString:pemString options:0];

    //NSData* pemData = [pemString dataUsingEncoding:NSUTF8StringEncoding];

    ERR_load_crypto_strings();
    ERR_load_ERR_strings();

    //const EVP_CIPHER* cipher = EVP_get_cipherbyname("PKCS5_v2_PBE_keyivgen");

    OpenSSL_add_all_algorithms();

    //EVP_add_cipher(cipher);
    //PKCS5_v2_PBE_keyivgen

    OPENSSL_config(NULL);

    BIO* pemBIO = BIO_new_mem_buf((void*)pemData.bytes, (int)pemData.length);

    //RSA* pemRSA = RSA_new();

    const char* cStringPassphrase = "password";//[passphrase cStringUsingEncoding:NSUTF8StringEncoding];


    unsigned long buflen = strlen(cStringPassphrase); //excluding NULL terminating char
    char* buffer = malloc((buflen + 1) * sizeof(char));
    memcpy(buffer, cStringPassphrase, buflen);
    buffer[buflen] = '\0';

    //PKCS8_PRIV_KEY_INFO* privKey = PEM_read_bio_PKCS8_PRIV_KEY_INFO(pemBIO, NULL, NULL, cStringPassphrase);

    X509_SIG* p8 = PEM_read_bio_PKCS8(pemBIO, NULL, NULL, NULL);

    //X509_SIG *p8 = d2i_PKCS8_bio(pemBIO, NULL);

    unsigned long error_code = ERR_get_error();

    const char* error_string = ERR_error_string(error_code, NULL);

    NSString* errorString = [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding];

    NSLog(@"Error: %@", errorString);


    if(p8)
    {

        PKCS8_PRIV_KEY_INFO* p8inf = PKCS8_decrypt(p8, cStringPassphrase, (int)strlen(cStringPassphrase));

        EVP_PKEY* privKey = EVP_PKCS82PKEY(p8inf);

        //X509_ATTRIBUTE_new();

        //X509_VAL* val = X509_VAL_new();

        //val->notAfter = ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]);

        //X509_ATTRIBUTE_set1_object(X509_ATTRIBUTE *attr, <#const ASN1_OBJECT *obj#>)

        //X509_ATTRIBUTE* attr = X509_ATTRIBUTE_create(<#int nid#>, <#int atrtype#>, <#void *value#>)

        //int result = EVP_PKEY_add1_attr(privKey, val);


        //int result = sk_push(&privKey->attributes->stack, val);

        //NSLog(@"Result of setting attribute: %ld", (long)result);

        //X509_PUBKEY* pubKey = X509_PUBKEY_new();

        //X509_PUBKEY_set(&pubKey, privKey);

        X509* x509 = X509_new();

        //X509_PKEY_new();

        //X509_set

        X509_set_pubkey(x509, privKey);

        X509_set_notAfter(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]+2*365*24*60*60));

        X509_set_notBefore(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]));

        ///X509_CINF* certInfo = x509->cert_info;

        //certInfo->validity->notAfter = ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]);

        //struct stack_st_X509* x509_stack = sk_X509_new_null();

        //sk_X509_push(x509_stack, x509);

        //PKCS12_SAFEBAG* safeBag = PKCS12_MAKE_KEYBAG(p8inf);

        //PKCS12_SAFEBAG* safeBag = PKCS12_SAFEBAG_new();

        //X509* cert = PKCS12_pack_p7data(<#struct stack_st_PKCS12_SAFEBAG *sk#>)

        //STACK_OF(PKCS12_SAFEBAG)* sk = sk_PKCS12_SAFEBAG_new_null();

        //sk_PKCS12_SAFEBAG_push(sk, safeBag);

        //PKCS7* pkcs7 = PKCS12_pack_p7data(sk);

        //PKCS12_add_key(&sk, privKey, 0, 1, 0, (char*)cStringPassphrase);

        const char* nameString = [@"Mynigma" cStringUsingEncoding:NSUTF8StringEncoding];
        //unsigned long buflen = strlen(nameString); //excluding NULL terminating char
                                                   //char* nameBuffer = malloc((buflen + 1) * sizeof(char));
                                                   //memcpy(buffer, nameString, buflen);
                                                   // buffer[buflen] = '\0';

        //PKCS12_new();

        //STACK_OF(PKCS12_SAFEBAG)* bags = NULL;

		//PKCS12_SAFEBAG* bag = PKCS12_add_cert(&bags, cert);

        //bag = PKCS12_add_key(&bags, privKey, <#int key_usage#>, <#int iter#>, <#int key_nid#>, <#char *pass#>)

        PKCS12* pkcs12 = PKCS12_create((char*)cStringPassphrase, (char*)nameString, privKey, x509, NULL, NID_pbe_WithSHA1And3_Key_TripleDES_CBC, NID_pbe_WithSHA1And3_Key_TripleDES_CBC, PKCS12_DEFAULT_ITER, PKCS12_DEFAULT_ITER, 0);



        //PKCS7* authSafes = pkcs12->authsafes;



        //PKCS12_add_key(<#struct stack_st_PKCS12_SAFEBAG **pbags#>, <#EVP_PKEY *key#>, <#int key_usage#>, <#int iter#>, <#int key_nid#>, <#char *pass#>)

        //PKCS12

        /*int ret2 = */

        //PKCS12_set_mac(pkcs12, cStringPassphrase, (int)strlen(cStringPassphrase), NULL, 0, PKCS12_DEFAULT_ITER, 0);

        

        //PEM_write_bio_PKCS7(<#BIO *bp#>, <#PKCS7 *x#>)

        //PKCS12* pkcs12 = PKCS12_new();

        //PKCS12_add_key(<#struct stack_st_PKCS12_SAFEBAG **pbags#>, <#EVP_PKEY *key#>, <#int key_usage#>, <#int iter#>, <#int key_nid#>, <#char *pass#>)





        BIO* newPEM = BIO_new(BIO_s_mem());

        //1i2d_PKCS12_SAFEBAG(<#PKCS12_SAFEBAG *a#>, <#unsigned char **out#>)

        i2d_PKCS12_bio(newPEM, pkcs12);

        //BIO_write(<#BIO *b#>, <#const void *data#>, <#int len#>)

        //PEM_write_bio_PKCS8_PRIV_KEY_INFO(newPEM, p8inf);

        int len = BIO_pending(newPEM);

        char *new_key = malloc(len);

        BIO_read(newPEM, new_key, len);

        //new_key[len] = '\0';

        //NSString* output = [NSString stringWithCString:new_key encoding:NSUTF8StringEncoding];

        NSData* outputData = [NSData dataWithBytes:new_key length:len];

        NSString* outputString = [NSString stringWithFormat:@"-----BEGIN RSA PRIVATE KEY-----\n%@\n-----END RSA PRIVATE KEY-----", [outputData base64]];

        NSData* newOutputData = [outputString dataUsingEncoding:NSUTF8StringEncoding];

        [TestHelper putData:newOutputData intoDesktopFile:@"test-output.txt"];

        [TestHelper putData:outputData intoDesktopFile:@"raw-test-output.txt"];

        [self addPEM:outputData forKeyLabel:@"keyLabel34049@mynigma.org|2314"];

        //X509_SIG

        NSLog(@"SUCCESS!!!!!");

        error_code = ERR_get_error();

        const char* error_string = ERR_error_string(error_code, NULL);

        errorString = [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding];

        NSLog(@"Error: %@", errorString);



        //PKCS8_PRIV_KEY_INFO *p8inf = PKCS12_item_decrypt_d2i(p8->algor, ASN1_ITEM_rptr(PKCS8_PRIV_KEY_INFO), cStringPassphrase, (int)buflen-1, p8->digest, 1);

    }
    //pemRSA = PEM_read_bio_RSAPrivateKey(pemBIO, 0, pass_cb, buffer);

    //if(!pemRSA)
    {

    }

    BIO_free(pemBIO);
    

}

/*
 - (void)testDecryptPKCS8
 {
 NSURL* fileURL = [BUNDLE URLForResource:@"Mynigma encryption key wilhelm.schuettelspeer@gmail.com|1374071660.432515" withExtension:@"pem"];

 NSData* fileData = [NSData dataWithContentsOfURL:fileURL];

 NSString* pemString = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];

 pemString = [pemString stringByReplacingOccurrencesOfString:@"RSA PUBLIC" withString:@"PUBLIC"];

 NSData* pemData = [pemString dataUsingEncoding:NSUTF8StringEncoding];

 BIO* pemBIO = BIO_new_mem_buf((void*)pemData.bytes, (int)pemData.length);

 pemBIO = NULL;

 RSA* pemRSA = RSA_new();

 PEM_read_bio_RSAPublicKey(pemBIO, &pemRSA, NULL, NULL);

 BIO_free(pemBIO);

 pemBIO = NULL;

 fileURL = [BUNDLE URLForResource:@"Mynigma encryption key wilhelm.schuettelspeer@gmail.com|1374071660.432515" withExtension:@"p12"];

 NSData* p12Data = [NSData dataWithContentsOfURL:fileURL];

 BIO* p12BIO = BIO_new_mem_buf((void*)pemData.bytes, (int)pemData.length);

 RSA* p12RSA = RSA_new();

 X509_SIG* x509SIG = X509_SIG_new();

 p12Data = nil;

 p12BIO = NULL;

 p12RSA = NULL;

 x509SIG = NULL;

 //PKCS8_

 //PKCS8_decrypt(<#X509_SIG *p8#>, <#const char *pass#>, <#int passlen#>)



 //PEM_write_bio_PrivateKey(bp, key, EVP_des_ede3_cbc(), NULL, 0, 0, NULL)


 //PEM_write_bio_RSAPrivateKey(<#BIO *bp#>, <#RSA *x#>, <#const EVP_CIPHER *enc#>, <#unsigned char *kstr#>, <#int klen#>, <#pem_password_cb *cb#>, <#void *u#>)

 //X509 *cert = PEM_read_bio_X509(bio);



 //X509_SIG* x509_sig = X509_SIG_new();

 //const char password[] = "password";

 //PKCS8_PRIV_KEY_INFO* privKeyInfo = PKCS8_decrypt(x509_sig, password, 8);



 //XCTFail(@"No implementation for \"%s\"", __PRETTY_FUNCTION__);
 }*/

#if TARGET_OS_IPHONE

#else

- (NSInteger)formatValueForString:(NSString*)string
{
    NSArray* strings = @[@"WrappedPKCS8", @"WrappedOpenSSL", @"WrappedSSH", @"WrappedLSH", @"X509Cert", @"PEMSequence", @"PKCS7", @"PKCS12"];

    NSInteger index = [strings indexOfObject:string];

    switch (index) {
        case 0:
            return kSecFormatWrappedPKCS8;
        case 1:
            return kSecFormatWrappedOpenSSL;
        case 2:
            return kSecFormatWrappedSSH;
        case 3:
            return kSecFormatWrappedLSH;
        case 4:
            return kSecFormatX509Cert;
        case 5:
            return kSecFormatPEMSequence;
        case 6:
            return kSecFormatPKCS7;
        case 7:
            return kSecFormatPKCS12;
        default:
            XCTAssert(nil);
            return 0;
    }
}

- (void)d_testPutKeyFilesOnDesktop
{
    NSString* keyLabel = [self keyLabel1];

    NSArray* persistentRefs = [KeychainHelper persistentRefsForPrivateKeychainItemWithLabel:keyLabel];

    XCTAssert(persistentRefs.count>0);

    NSData* persistentRef = persistentRefs[0];

    NSArray* strings = @[@"WrappedPKCS8", @"WrappedOpenSSL", @"WrappedSSH", @"WrappedLSH", @"X509Cert", @"PEMSequence", @"PKCS7", @"PKCS12"];

    for(NSNumber* armour in @[@YES, @NO])
    {
        for(NSString* typeString in strings)
        {
            NSString* fileName = [NSString stringWithFormat:@"Key-File-%@-Password%@.txt", typeString, armour.boolValue?@"-Armour":@""];

            //first get a SecKeyRef from the persistent reference
            SecKeyRef keyRef = [KeychainHelper keyRefForPersistentRef:persistentRef];

            XCTAssert(keyRef);
            
            if(!keyRef)
                continue;

            SecItemImportExportKeyParameters params = {0};
            params.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;

            SecExternalFormat externalFormat = kSecFormatPEMSequence;



            NSString* passphrase = @"password";
            params.passphrase = (__bridge_retained CFStringRef)passphrase;
            externalFormat = (unsigned int)[self formatValueForString:typeString];
            //params.keyAttributes = (__bridge CFArrayRef)(@[(__bridge id)kSecAttrIsExtractable, (__bridge id)kSecAttrIsPermanent, (__bridge id)kSecAttrIsSensitive]);

            int armourValue = armour.boolValue?kSecItemPemArmour:0;

            CFDataRef keyData = NULL;
            OSStatus oserr = SecItemExport(keyRef, externalFormat, armourValue , &params, &keyData);
            if(passphrase)
                CFRelease(params.passphrase);

            if(oserr == noErr) {

                [self putData:(__bridge NSData*)keyData intoDesktopFile:fileName];

                if(keyData)
                    CFRelease(keyData);
            }
            else
            {
                if(keyData)
                    CFRelease(keyData);
                
                NSLog(@"Error exporting key: %@, %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil], fileName);
            }
        }
    }
}

#endif

@end
