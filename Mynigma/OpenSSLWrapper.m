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





#import "OpenSSLWrapper.h"
#import "EncryptionHelper.h"
#import "KeychainHelper.h"
#import "MynigmaPublicKey+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "ThreadHelper.h"
#import "MynigmaFeedback.h"




#import <openssl/err.h>
#import <openssl/pkcs12.h>
#import <openssl/pkcs7.h>
#import <openssl/x509.h>
#import <openssl/x509v3.h>
#import <openssl/bio.h>
#import <openssl/pem.h>
#import <openssl/stack.h>
#import <openssl/safestack.h>
#import <openssl/evp.h>
#import <openssl/hmac.h>
#import <openssl/rsa.h>
#import <openssl/cms.h>
#import <openssl/ossl_typ.h>
#import <openssl/bn.h>


//@interface MynigmaPrivateKey()
//
//+ (NSArray*)dataForPrivateKeyWithLabel:(NSString *)keyLabel;
//
//@end
//
//
//@interface MynigmaPublicKey()
//
//+ (NSArray*)dataForExistingMynigmaPublicKeyWithLabel:(NSString *)keyLabel;
//
//@end



static BOOL loadedOpenSSL = NO;

@implementation OpenSSLWrapper

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

+ (NSData*)DERFileFromPEMKey:(NSData*)PEMData withPassphrase:(NSString*)passphrase
{
    if(!PEMData)
        return nil;
    
    NSString* PEMString = [[NSString alloc] initWithData:PEMData encoding:NSUTF8StringEncoding];
    
    PEMString = [PEMString stringByReplacingOccurrencesOfString:@" RSA PUBLIC " withString:@" PUBLIC "];
    
    PEMData = [PEMString dataUsingEncoding:NSUTF8StringEncoding];
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    BIO* PEMBio = BIO_new_mem_buf((void*)PEMData.bytes, (int)PEMData.length);
    
    EVP_PKEY* pubKey = PEM_read_bio_PUBKEY(PEMBio, NULL, NULL, NULL);
    
    if(!pubKey)
    {
        unsigned long error_code = ERR_get_error();
        
        const char* error_string = ERR_error_string(error_code, NULL);
        
        NSLog(@"Error: %@", [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding]);
        
        return nil;
    }
    
    X509* x509 = X509_new();
    
    X509_set_pubkey(x509, pubKey);
    
    X509_set_notAfter(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]+2*365*24*60*60));
    
    X509_set_notBefore(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]));
    
    BIO* DERBio = BIO_new(BIO_s_mem());
    
    i2d_X509_bio(DERBio, x509);
    
    int len = BIO_pending(DERBio);
    
    char *new_key = malloc(len);
    
    BIO_read(DERBio, new_key, len);
    
    NSData* outputData = [NSData dataWithBytes:new_key length:len];
    
    return outputData;
}

+ (NSData*)PKCS12FileFromPKCS8Key:(NSData*)PKCS8Data withPassphrase:(NSString*)passphrase
{
    if(!PKCS8Data)
        return nil;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    BIO* PKCS8BIO = BIO_new_mem_buf((void*)PKCS8Data.bytes, (int)PKCS8Data.length);
    
    const char* cStringPassphrase = [passphrase cStringUsingEncoding:NSUTF8StringEncoding];
    
    X509_SIG* p8 = PEM_read_bio_PKCS8(PKCS8BIO, NULL, NULL, NULL);
    
    if(!p8)
    {
        unsigned long error_code = ERR_get_error();
        
        const char* error_string = ERR_error_string(error_code, NULL);
        
        NSLog(@"Error: %@", [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding]);
        
        return nil;
    }
    
    EVP_PKEY* privKey = NULL;
    
    PKCS8_PRIV_KEY_INFO* p8inf = PKCS8_decrypt(p8, cStringPassphrase, (int)strlen(cStringPassphrase));
    
    X509* x509 = NULL;
    
    if(p8inf)
    {
        privKey = EVP_PKCS82PKEY(p8inf);
        
        x509 = X509_new();
        
        X509_set_pubkey(x509, privKey);
        
    }
    else
    {
        unsigned long error_code = ERR_get_error();
        
        const char* error_string = ERR_error_string(error_code, NULL);
        
        NSLog(@"Error: %@", [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding]);
        
        return nil;
    }
    
    
    
    X509_set_notAfter(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]+2*365*24*60*60));
    
    X509_set_notBefore(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]));
    
    const char* nameString = [@"Mynigma" cStringUsingEncoding:NSUTF8StringEncoding];
    
    PKCS12* pkcs12 = PKCS12_create((char*)cStringPassphrase, (char*)nameString, privKey, x509, NULL, NID_pbe_WithSHA1And3_Key_TripleDES_CBC, NID_pbe_WithSHA1And3_Key_TripleDES_CBC, PKCS12_DEFAULT_ITER, PKCS12_DEFAULT_ITER, 0);
    
    BIO* PKCS12Bio = BIO_new(BIO_s_mem());
    
    i2d_PKCS12_bio(PKCS12Bio, pkcs12);
    
    int len = BIO_pending(PKCS12Bio);
    
    char *new_key = malloc(len);
    
    BIO_read(PKCS12Bio, new_key, len);
    
    NSData* outputData = [NSData dataWithBytes:new_key length:len];
    
    return outputData;
}

+ (NSData*)PEMFileForRSAPublicKey:(RSA*)RSAKey
{
    if(!RSAKey)
        return nil;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    BIO* publicKeyBIO = BIO_new(BIO_s_mem());
    
    PEM_write_bio_RSAPublicKey(publicKeyBIO, RSAKey);
    
    //    BIO* privateKeyBIO = BIO_new(BIO_s_mem());
    //
    //    PEM_write_bio_RSAPrivateKey(privateKeyBIO, RSAKey, NULL, NULL, 0, NULL, NULL);
    
    
    int len = BIO_pending(publicKeyBIO);
    
    char *keyBytes = malloc(len);
    
    BIO_read(publicKeyBIO, keyBytes, len);
    
    NSData* publicKeyData = [NSData dataWithBytes:keyBytes length:len];
    
    free(keyBytes);
    
    if(publicKeyData)
        return publicKeyData;
    
    return nil;
}

+ (NSData*)PEMFileForRSAPrivateKey:(RSA*)RSAKey
{
    if(!RSAKey)
        return nil;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    //    BIO* publicKeyBIO = BIO_new(BIO_s_mem());
    //
    //    PEM_write_bio_RSAPublicKey(publicKeyBIO, RSAKey);
    
    BIO* privateKeyBIO = BIO_new(BIO_s_mem());
    
    PEM_write_bio_RSAPrivateKey(privateKeyBIO, RSAKey, NULL, NULL, 0, NULL, NULL);
    
    
    int len = BIO_pending(privateKeyBIO);
    
    char *keyBytes = malloc(len);
    
    BIO_read(privateKeyBIO, keyBytes, len);
    
    NSData* privateKeyData = [NSData dataWithBytes:keyBytes length:len];
    
    free(keyBytes);
    
    if(privateKeyData)
        return privateKeyData;
    
    return nil;
}

+ (RSA*)openSSLPublicEncryptionKeyWithLabel:(NSString*)keyLabel
{
    NSArray* dataArray = [KeychainHelper dataForPublicKeychainItemWithLabel:keyLabel];
    
    NSData* PEMData = dataArray[0];
    
    NSString* PEMString = [[NSString alloc] initWithData:PEMData encoding:NSUTF8StringEncoding];
    
    PEMString = [PEMString stringByReplacingOccurrencesOfString:@" RSA PUBLIC " withString:@" PUBLIC "];
    
    PEMData = [PEMString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    if(!PEMData)
        return nil;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    BIO* PEMBio = BIO_new_mem_buf((void*)PEMData.bytes, (int)PEMData.length);
    
    RSA* rsa = PEM_read_bio_RSA_PUBKEY(PEMBio, NULL, NULL, NULL);
    
    return rsa;
}


+ (RSA*)openSSLPublicVerificationKeyWithLabel:(NSString*)keyLabel
{
    NSArray* dataArray = [KeychainHelper dataForPublicKeychainItemWithLabel:keyLabel];
    
    NSData* PEMData = dataArray[1];
    
    NSString* PEMString = [[NSString alloc] initWithData:PEMData encoding:NSUTF8StringEncoding];
    
    PEMString = [PEMString stringByReplacingOccurrencesOfString:@" RSA PUBLIC " withString:@" PUBLIC "];
    
    PEMData = [PEMString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    if(!PEMData)
        return nil;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    BIO* PEMBio = BIO_new_mem_buf((void*)PEMData.bytes, (int)PEMData.length);
    
    RSA* rsa = PEM_read_bio_RSA_PUBKEY(PEMBio, NULL, NULL, NULL);
    
    return rsa;
}


+ (RSA*)openSSLPrivateSignatureKeyWithLabel:(NSString*)keyLabel
{
    NSString* passphrase = @"password";
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }

    NSArray* dataArray = [KeychainHelper dataForPrivateKeychainItemWithLabel:keyLabel passphrase:passphrase];
    
    if(!dataArray)
    {
        //try it without a passphrase...
        dataArray = [KeychainHelper dataForPrivateKeychainItemWithLabel:keyLabel];
        
        if(!dataArray)
            return nil;
        
        NSData* PKCS8Data = dataArray[1];
        
        if(!PKCS8Data)
            return nil;
        
        
        BIO* PKCS8BIO = BIO_new_mem_buf((void*)PKCS8Data.bytes, (int)PKCS8Data.length);
        
//        const char* cStringPassphrase = [passphrase cStringUsingEncoding:NSUTF8StringEncoding];
        
        RSA* rsa = PEM_read_bio_RSAPrivateKey(PKCS8BIO, NULL, NULL, NULL);
        
        return rsa;
    }
    
    NSData* PKCS8Data = dataArray[1];
    
    if(!PKCS8Data)
        return nil;
    
    
    BIO* PKCS8BIO = BIO_new_mem_buf((void*)PKCS8Data.bytes, (int)PKCS8Data.length);
    
    const char* cStringPassphrase = [passphrase cStringUsingEncoding:NSUTF8StringEncoding];
    
    RSA* rsa = PEM_read_bio_RSAPrivateKey(PKCS8BIO, NULL, NULL, (char*)cStringPassphrase);
    
    return rsa;
}

+ (RSA*)openSSLPrivateDecryptionKeyWithLabel:(NSString*)keyLabel
{
    NSString* passphrase = @"password";
    
    NSArray* dataArray = [KeychainHelper dataForPrivateKeychainItemWithLabel:keyLabel passphrase:passphrase];
    
    NSData* PKCS8Data = dataArray[0];
    
    if(!PKCS8Data)
        return nil;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    BIO* PKCS8BIO = BIO_new_mem_buf((void*)PKCS8Data.bytes, (int)PKCS8Data.length);
    
    const char* cStringPassphrase = [passphrase cStringUsingEncoding:NSUTF8StringEncoding];
    
    RSA* rsa = PEM_read_bio_RSAPrivateKey(PKCS8BIO, NULL, NULL, (char*)cStringPassphrase);
    
    return rsa;
}

+ (MynigmaFeedback*)PSS_RSAverifySignature:(NSData*)signature ofHash:(NSData*)dataHash withKeyLabel:(NSString*)keyLabel
{
    @try
    {
    if(!keyLabel)
        return [MynigmaFeedback feedback:MynigmaVerificationErrorNoKeyLabel];
    
    RSA* rsa = [OpenSSLWrapper openSSLPublicVerificationKeyWithLabel:keyLabel];
    
    if(!rsa || !signature || !dataHash || !keyLabel)
        return [MynigmaFeedback feedback:MynigmaVerificationErrorNoKey];
    
    unsigned char decryptedData[RSA_size(rsa)];
    
    //first step
    
    //the first stage of verification takes no padding
    //that's unwrapped in the second step below
    int status = RSA_public_decrypt((unsigned int)signature.length, signature.bytes, decryptedData, rsa, RSA_NO_PADDING);
    if (status == -1)
    {
        printf("RSA_public_decrypt failed with error %s\n", ERR_error_string(ERR_get_error(), NULL));
        return [MynigmaFeedback feedback:MynigmaVerificationErrorRSACannotSetPadding];
    }
    
    //second step
    
    // verify the data
    // hashing algorithm set to SHA-512
    // MGF also set to SHA-512
    // salt length is autorecovered from signature
    status = RSA_verify_PKCS1_PSS(rsa, dataHash.bytes, EVP_sha512(), decryptedData, -2);
    if (status == 1)
    {
        return [MynigmaFeedback feedback:MynigmaVerificationSuccess];
    }
    else
    {
        NSLog(@"RSA_verify_PKCS1_PSS failed with error %s\n", ERR_error_string(ERR_get_error(), NULL));
        return [MynigmaFeedback feedback:MynigmaVerificationErrorInvalidSignature];
    }
    }
    @catch(NSException* exception)
    {
        return [MynigmaFeedback feedback:MynigmaVerificationErrorRSAExceptionCaught];
    }
}

+ (NSData*)PSS_RSAsignHash:(NSData*)mHash withKeyWithLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    @try
    {
    RSA* rsa = [OpenSSLWrapper openSSLPrivateSignatureKeyWithLabel:keyLabel];
    
    if(!rsa)
    {
#warning TO DO: error
        return nil;
    }
    
    unsigned char EM[RSA_size(rsa)];
    unsigned char signature[RSA_size(rsa)];
    
    //add PSS padding with SHA-512
    //salt length 32 bytes = 256 bits
    int status = RSA_padding_add_PKCS1_PSS(rsa, EM, mHash.bytes, EVP_sha512(), 32);
    if (!status)
    {
        NSLog(@"RSA_padding_add_PKCS1_PSS failed with error %s\n", ERR_error_string(ERR_get_error(), NULL));
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotSetPadding];
        
        return nil;
    }
    
    // sign the data
    // no padding required, as it has already been added in the previous step
    status = RSA_private_encrypt(512, EM, signature, rsa, RSA_NO_PADDING);
    if (status == -1)
    {
        NSLog(@"RSA_private_encrypt failed with error %s\n", ERR_error_string(ERR_get_error(), NULL));
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotExecuteTransform];
        
        return nil;
    }
    
    NSData* returnValue = [NSData dataWithBytes:signature length:512];
    
    return returnValue;
    }
    @catch(NSException* exception)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSAExceptionCaught];
        
        return nil;
    }
}

+ (BOOL)verifySignature:(NSData*)signature ofHash:(NSData*)dataHash withKeyLabel:(NSString*)keyLabel
{
    RSA* rsa = [OpenSSLWrapper openSSLPublicVerificationKeyWithLabel:keyLabel];
    
    if(!rsa)
        return NO;
    
    BOOL result = RSA_verify(NID_sha512, dataHash.bytes, (unsigned int)dataHash.length, (unsigned char*)signature.bytes, (unsigned int)signature.length, rsa);
    
    return result;
}

+ (NSData*)signHash:(NSData*)mHash withKeyWithLabel:(NSString*)keyLabel
{
    RSA* rsa = [OpenSSLWrapper openSSLPrivateSignatureKeyWithLabel:keyLabel];
    
    if(!rsa)
        return nil;
    
    unsigned char signature[512];
    
    unsigned int length;
    
    RSA_sign(NID_sha512, mHash.bytes, (unsigned int)mHash.length, signature, &length, rsa);
    
    NSData* returnValue = [NSData dataWithBytes:signature length:512];
    
    return returnValue;
}

//+ (NSData*)LEGACY_RSAencryptData:(NSData*)data withPublicKeyWithLabel:(NSString*)keyLabel
//{
//    RSA* rsa = [OpenSSLWrapper openSSLPublicEncryptionKeyWithLabel:keyLabel];
//
//    unsigned char* result = malloc(RSA_size(rsa));
//
//    RSA_public_encrypt((int)data.length, data.bytes, result, rsa, RSA_PKCS1_OAEP_PADDING);
//
//    return nil;
//}
//
//+ (NSData*)LEGACY_RSAdecryptData:(NSData*)data withPublicKeyWithLabel:(NSString*)keyLabel
//{
//    RSA* rsa = [OpenSSLWrapper openSSLPublicEncryptionKeyWithLabel:keyLabel];
//
//    unsigned char* result = malloc(RSA_size(rsa));
//
//    RSA_public_decrypt((int)data.length, data.bytes, result, rsa, RSA_PKCS1_OAEP_PADDING);
//
//    return nil;
//}

+ (NSData*)RSAencryptData:(NSData*)data withPublicKeyWithLabel:(NSString*)keyLabel
{
    RSA* rsa = [OpenSSLWrapper openSSLPublicEncryptionKeyWithLabel:keyLabel];
    
    int resultLength = RSA_size(rsa);
    //    unsigned char result[resultLength];
    
    //    RSA_padding_add_PKCS1_OAEP(result, resultLength, data.bytes, (int)data.length, NULL, 0);
    
    unsigned char encryptedData[resultLength];
    
    RSA_public_encrypt((int)data.length, data.bytes, encryptedData, rsa, RSA_PKCS1_OAEP_PADDING);
    
    return [NSData dataWithBytes:encryptedData length:resultLength];
}

+ (NSData*)RSAdecryptData:(NSData*)data withPublicKeyWithLabel:(NSString*)keyLabel
{
    RSA* rsa = [OpenSSLWrapper openSSLPublicEncryptionKeyWithLabel:keyLabel];
    
    unsigned char* result = malloc(RSA_size(rsa));
    
    RSA_public_decrypt((int)data.length, data.bytes, result, rsa, RSA_PKCS1_OAEP_PADDING);
    
    return nil;
}

+ (NSData*)HMACForMessage:(NSData *)message withSecret:(NSData *)secret
{
    unsigned int outputLength = 0;
    unsigned char* outputBytes = HMAC(EVP_sha512(), secret.bytes, (int)secret.length, message.bytes, message.length, NULL, &outputLength);
    
    NSData* outputData = [NSData dataWithBytes:outputBytes length:outputLength];
    
    return outputData;
}

#pragma clang diagnostic pop


+ (X509*)x509CertificateForData:(NSData*)keyData
{
    NSString* PEMString = [[NSString alloc] initWithData:keyData encoding:NSUTF8StringEncoding];
    
    PEMString = [PEMString stringByReplacingOccurrencesOfString:@" RSA PUBLIC " withString:@" PUBLIC "];
    
    NSData* PEMData = [PEMString dataUsingEncoding:NSUTF8StringEncoding];
    
    //    NSData* PEMData = keyData;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    BIO* PEMBio = BIO_new_mem_buf((void*)PEMData.bytes, (int)PEMData.length);
    
    EVP_PKEY* pubKey = PEM_read_bio_PUBKEY(PEMBio, NULL, NULL, NULL);
    
    if(!pubKey)
    {
        unsigned long error_code = ERR_get_error();
        
        const char* error_string = ERR_error_string(error_code, NULL);
        
        NSLog(@"Error: %@", [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding]);
        
        return nil;
    }
    
    X509* x509 = X509_new();
    
    X509_set_pubkey(x509, pubKey);
    
    X509_set_notAfter(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]+2*365*24*60*60));
    
    X509_set_notBefore(x509, ASN1_TIME_set(NULL, [[NSDate date] timeIntervalSince1970]));
    
    return x509;
}


+ (X509*)x509CertificateWithPublicKeyLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    NSArray* keyDataArray = [MynigmaPublicKey dataForExistingMynigmaPublicKeyWithLabel:keyLabel];
    
    NSData* keyData = nil;
    
    if(forEncryption)
        keyData = keyDataArray.firstObject;
    else
        keyData = keyDataArray.lastObject;
    
    if(!keyData)
        return nil;
    
    return [OpenSSLWrapper x509CertificateForData:keyData];
}

+ (X509*)x509CertificateWithPrivateKeyLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    NSArray* keyDataArray = [MynigmaPrivateKey dataForPrivateKeyWithLabel:keyLabel];
    
    NSData* keyData = nil;
    
    if(keyDataArray.count < 4)
        return nil;
    
    if(forEncryption)
        keyData = keyDataArray[0];
    else
        keyData = keyDataArray[1];
    
    if(!keyData)
        return nil;
    
    return [OpenSSLWrapper x509CertificateForData:keyData];
}

+ (EVP_PKEY*)EVP_PKEYWithPrivateKeyLabel:(NSString*)keyLabel forEncryption:(BOOL)forEncryption
{
    NSArray* keyDataArray = [MynigmaPrivateKey dataForPrivateKeyWithLabel:keyLabel];
    
    NSData* keyData = nil;
    
    if(keyDataArray.count < 4)
        return nil;
    
    if(forEncryption)
        keyData = keyDataArray[0];
    else
        keyData = keyDataArray[1];
    
    if(!keyData)
        return nil;
    
    if(!loadedOpenSSL)
    {
        ERR_load_crypto_strings();
        ERR_load_ERR_strings();
        
        OpenSSL_add_all_algorithms();
        
        OPENSSL_config(NULL);
        
        loadedOpenSSL = YES;
    }
    
    //    NSString* PEMString = [[NSString alloc] initWithData:keyData encoding:NSUTF8StringEncoding];
    //
    //    PEMString = [PEMString stringByReplacingOccurrencesOfString:@" RSA PRIVATE " withString:@" PRIVATE "];
    //
    //    keyData = [PEMString dataUsingEncoding:NSUTF8StringEncoding];
    
    
    BIO* outputBIO = BIO_new(BIO_s_mem());
    BIO_write(outputBIO, keyData.bytes, (int)keyData.length);
    
    EVP_PKEY* privKey = 0;
    PEM_read_bio_PrivateKey(outputBIO, &privKey, 0, 0);
    
    BIO_free(outputBIO);
    
    return privKey;
}



#pragma mark - Cryptographic Message Syntax (CMS) & S/MIME

+ (NSData*)encryptData:(NSData*)data withPublicKeyLabels:(NSArray*)publicKeyLabels error:(NSError**)error
{
    STACK_OF(X509) *sk = sk_X509_new_null();
    
    for(NSString* keyLabel in publicKeyLabels)
    {
        X509* X509Certificate = [OpenSSLWrapper x509CertificateWithPublicKeyLabel:keyLabel forEncryption:YES];
        
        sk_X509_push(sk, X509Certificate);
    }
    
    BIO* dataBIO = BIO_new_mem_buf((void*)data.bytes, (int)data.length);
    
    BIO* outputBIO = BIO_new(BIO_s_mem());
    
    CMS_ContentInfo* contentInfo = CMS_encrypt(sk, dataBIO, EVP_aes_128_cbc(), 0);
    
    int result = SMIME_write_CMS(outputBIO, contentInfo, dataBIO, 0);
    
    if(result != 1)
    {
        //TO DO: better error feedback
        
        long errorCode = ERR_get_error();
        
        if(error)
            *error = [NSError errorWithDomain:@"S/MIME parse error" code:errorCode userInfo:@{}];
    }
    
    int len = BIO_pending(outputBIO);
    
    char *resultBytes = malloc(len);
    
    BIO_read(outputBIO, resultBytes, len);
    
    NSData* resultData = [NSData dataWithBytes:resultBytes length:len];
    
    free(resultBytes);
    
    return resultData;
}

+ (NSData*)decryptData:(NSData*)data withKeyLabel:(NSString*)keyLabel error:(NSError**)error
{
    X509* x509Cert = [OpenSSLWrapper x509CertificateWithPrivateKeyLabel:keyLabel forEncryption:YES];
    
    EVP_PKEY* privKey = [OpenSSLWrapper EVP_PKEYWithPrivateKeyLabel:keyLabel forEncryption:YES];
    
    BIO* dataBIO = BIO_new_mem_buf((void*)data.bytes, (int)data.length);
    
    BIO* outputBIO = BIO_new(BIO_s_mem());
    
    BIO *cont = NULL;
    
    CMS_ContentInfo* contentInfo = SMIME_read_CMS(dataBIO, &cont);
    
    int decryptionResult = CMS_decrypt(contentInfo, privKey, x509Cert, cont, outputBIO, 0);
    
    if(decryptionResult != 1)
    {
        //TO DO: better error feedback
        
        long errorCode = ERR_get_error();
        
        if(error)
            *error = [NSError errorWithDomain:@"S/MIME parse error" code:errorCode userInfo:@{}];
    }
    
    int len = BIO_pending(outputBIO);
    
    char *resultBytes = malloc(len);
    
    BIO_read(outputBIO, resultBytes, len);
    
    NSData* resultData = [NSData dataWithBytes:resultBytes length:len];
    
    free(resultBytes);
    
    return resultData;
}

+ (NSData*)signData:(NSData*)data withPrivateKeyLabel:(NSString*)keyLabel error:(NSError**)error
{
    STACK_OF(X509) *sk = sk_X509_new_null();
    
    X509* X509Certificate = [OpenSSLWrapper x509CertificateWithPublicKeyLabel:keyLabel forEncryption:YES];
    
    sk_X509_push(sk, X509Certificate);
    
    EVP_PKEY* privKey = [OpenSSLWrapper EVP_PKEYWithPrivateKeyLabel:keyLabel forEncryption:YES];
    
    BIO* dataBIO = BIO_new_mem_buf((void*)data.bytes, (int)data.length);
    
    BIO* outputBIO = BIO_new(BIO_s_mem());
    
    CMS_ContentInfo* contentInfo = CMS_sign(X509Certificate, privKey, NULL, dataBIO, 0);
    
    int result = SMIME_write_CMS(outputBIO, contentInfo, dataBIO, 0);
    
    if(result != 1)
    {
        //TO DO: better error feedback
        
        long errorCode = ERR_get_error();
        
        if(error)
            *error = [NSError errorWithDomain:@"S/MIME parse error" code:errorCode userInfo:@{}];
    }
    
    int len = BIO_pending(outputBIO);
    
    char *resultBytes = malloc(len);
    
    BIO_read(outputBIO, resultBytes, len);
    
    NSData* resultData = [NSData dataWithBytes:resultBytes length:len];
    
    free(resultBytes);
    
    return resultData;
}

+ (NSData*)verifySignedData:(NSData*)data withPublicKeyLabel:(NSString*)keyLabel error:(NSError**)error
{
    STACK_OF(X509) *sk = sk_X509_new_null();
    
    X509* X509Certificate = [OpenSSLWrapper x509CertificateWithPublicKeyLabel:keyLabel forEncryption:YES];
    
    sk_X509_push(sk, X509Certificate);
    
    X509_STORE* store = X509_STORE_new();
    
    X509_STORE_add_cert(store, X509Certificate);
    
    BIO* dataBIO = BIO_new_mem_buf((void*)data.bytes, (int)data.length);
    
    BIO* outputBIO = BIO_new(BIO_s_mem());
    
    BIO *cont = NULL;
    
    CMS_ContentInfo* contentInfo = SMIME_read_CMS(dataBIO, &cont);
    
    if(!contentInfo)
    {
        long errorCode = ERR_get_error();
        
        const char* error_string = ERR_error_string(errorCode, NULL);
        
        NSLog(@"Error: %@", [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding]);
        
        return nil;
    }
    
    int result = CMS_verify(contentInfo, sk, store, NULL, outputBIO, 0);
    
    if(result != 1)
    {
        //TO DO: better error feedback
        
        long errorCode = ERR_get_error();
        
        const char* error_string = ERR_error_string(errorCode, NULL);
        
        NSLog(@"Error: %@", [NSString stringWithCString:error_string?error_string:"" encoding:NSUTF8StringEncoding]);
        
        if(error)
            *error = [NSError errorWithDomain:@"S/MIME signature verification fail" code:errorCode userInfo:@{}];
        
        return nil;
    }
    
    int len = BIO_pending(outputBIO);
    
    char *resultBytes = malloc(len);
    
    BIO_read(outputBIO, resultBytes, len);
    
    NSData* resultData = [NSData dataWithBytes:resultBytes length:len];
    
    free(resultBytes);
    
    return resultData;
}



#pragma mark - Importing S/MIME keys

+ (void)importSMIMEKeyFromData:(NSData*)fileData withPassphraseCallback:(void(^)(NSString* passphrase))passPhraseCallback andResultCallback:(void(^)(NSArray* importedKeyLabels))resultCallback
{
    //To DO: implement
    
    //PEM_read_bio_PrivateKey(<#BIO *bp#>, <#EVP_PKEY **x#>, <#pem_password_cb *cb#>, <#void *u#>)
    
    
    
}






#pragma mark - Key generation

+ (NSArray*)generateRSAKeyPairData
{
    RSA* RSAKey = RSA_new();
    
    BIGNUM* exponent = BN_new();
    
    BN_set_word(exponent, 3);
    
    int result = RSA_generate_key_ex(RSAKey, 4096, exponent, NULL);
    
    if(result != 1)
    {
        NSLog(@"Error generating RSA key!!!");
        
        if(exponent)
            BN_free(exponent);
        
        exponent = nil;
        
        if(RSAKey)
            RSA_free(RSAKey);
        
        RSAKey = nil;
        
        return nil;
    }
    
    if(exponent)
        BN_free(exponent);
    
    exponent = NULL;
    
    NSData* publicKeyData = [OpenSSLWrapper PEMFileForRSAPublicKey:RSAKey];
    
    NSData* privateKeyData = [OpenSSLWrapper PEMFileForRSAPrivateKey:RSAKey];
    
    if(RSAKey)
        RSA_free(RSAKey);
    
    RSAKey = nil;
    
    if(publicKeyData && privateKeyData)
        return @[publicKeyData, privateKeyData];
    
    return nil;
}


+ (void)generateNewPrivateKeyPairForEmailAddress:(NSString*)email withCallback:(void(^)(NSString* keyLabel, NSData* encPersRef, NSData* verPersRef, NSData* decPersRef, NSData* sigPersRef))callback
{
    //use the current date for the second part of the keyLabel
    __block NSDate* currentDate = [NSDate date];
    
    //the email address is the first part
    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f",email,[currentDate timeIntervalSince1970]];
    
    [OpenSSLWrapper generateNewPrivateKeyPairWithKeyLabel:keyLabel withCallback:callback];
}


+ (void)generateNewPrivateKeyPairWithKeyLabel:(NSString*)keyLabel withCallback:(void(^)(NSString* keyLabel, NSData* encPersRef, NSData* verPersRef, NSData* decPersRef, NSData* sigPersRef))callback
{
    [ThreadHelper runAsyncFreshLocalChildContext:^(NSManagedObjectContext *localContext) {
        
        NSArray* signatureKeyData = [self generateRSAKeyPairData];
        NSArray* encryptionKeyData = [self generateRSAKeyPairData];
        
        if(!signatureKeyData || !encryptionKeyData)
        {
            NSLog(@"Failed to generate RSA key with OpenSSL!!");
            if(callback)
                callback(nil, nil, nil, nil, nil);
            return;
        }
        
        [ThreadHelper runAsyncOnMain:^{
            
            NSData* encData = encryptionKeyData.firstObject;
            NSData* decData = encryptionKeyData.lastObject;
            
            NSData* verData = signatureKeyData.firstObject;
            NSData* sigData = signatureKeyData.lastObject;
            
            NSArray* persistentRefs = [KeychainHelper addPrivateKeyWithLabel:keyLabel toKeychainWithEncData:encData verData:verData decData:decData sigData:sigData];
            
            if(persistentRefs.count != 4)
            {
                NSLog(@"Failed add private key to keychain!!");
                if(callback)
                    callback(nil, nil, nil, nil, nil);
                return;
            }
            
            NSData* privDecr = persistentRefs[0];
            NSData* privSign = persistentRefs[1];
            NSData* pubEncr = persistentRefs[2];
            NSData* pubVer = persistentRefs[3];
            
            //now return the result
            if(callback)
                callback(keyLabel, pubEncr, pubVer, privDecr, privSign);
        }];
    }];
}



@end
