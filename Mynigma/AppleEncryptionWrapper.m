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





#import "AppleEncryptionWrapper.h"
#import <CommonCrypto/CommonCrypto.h>
#import "AppDelegate.h"
#import "MynigmaPublicKey+Category.h"
#import "KeychainHelper.h"
#import "PublicKeyManager.h"
#import "MynigmaPrivateKey+Category.h"
#import "NSData+Base64.h"
#import "MynigmaFeedback.h"
#import "SessionKeys.h"




@implementation AppleEncryptionWrapper



#pragma mark - RSA IMPLEMENTATION

//encrypts a block of NSData using RSA with OAEP padding and SHA-512 as hashing algorithm
+ (NSData*)RSAencryptData:(NSData*)data withPublicKeyLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{

    SecKeyRef publicEncryptionKeyRef = [MynigmaPublicKey publicSecKeyRefWithLabel:keyLabel forEncryption:YES];

    if(!publicEncryptionKeyRef)
    {
//        NSLog(@"No public encryption key ref for key label %@", keyLabel);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorRSANoPublicKeyForLabel];
        return nil;
    }

#if TARGET_OS_IPHONE

    OSStatus status = noErr;

    size_t cipherBufferSize = SecKeyGetBlockSize(publicEncryptionKeyRef);
    uint8_t *cipherBuffer = (uint8_t*)malloc(cipherBufferSize);

    //  Error handling

    if (cipherBufferSize < sizeof(data))
    {
//        NSLog(@"Could not encrypt.  Packet too large.\n");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorRSAPacketTooLarge];
        return nil;
    }

    // Encrypt using RSA with OAEP padding
    status = SecKeyEncrypt(publicEncryptionKeyRef, kSecPaddingOAEP, (uint8_t*)data.bytes, (size_t) data.length, cipherBuffer, &cipherBufferSize);

    NSData *encryptedData = nil;

    if(status==noErr && cipherBufferSize)
    {
        encryptedData = [NSData dataWithBytes:cipherBuffer length:cipherBufferSize];
    }
    else
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSAWithOSStatus withOSStatus:status];
    }

    free(cipherBuffer);

    return encryptedData;

#else

    //create encryption transform
    CFErrorRef errorRef;
    SecTransformRef rsaEncryptionRef = SecEncryptTransformCreate(publicEncryptionKeyRef, &errorRef);

    if(errorRef)
    {
//        NSLog(@"Error creating RSA transform: %@",errorRef);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorRSACannotCreateTransform];
        if(rsaEncryptionRef)
            CFRelease(rsaEncryptionRef);
        return nil;
    }

    //input is the data argument provided
    SecTransformSetAttribute(rsaEncryptionRef, kSecTransformInputAttributeName, (__bridge CFDataRef)data, &errorRef);
    if(errorRef)
    {
//        NSLog(@"Error setting RSA input: %@",errorRef);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorRSACannotSetInput];
        if(rsaEncryptionRef)
            CFRelease(rsaEncryptionRef);
        return nil;
    }

    //set padding to OAEP
    SecTransformSetAttribute(rsaEncryptionRef, kSecPaddingKey, kSecPaddingOAEPKey, &errorRef);
    if(errorRef)
    {
//        NSLog(@"Error setting padding to OAEP: %@",errorRef);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorRSACannotSetPadding];
        if(rsaEncryptionRef)
            CFRelease(rsaEncryptionRef);
        return nil;
    }

    //SHA1 no longer recommended for new applications, so set digest algorithm to SHA2 instead
    /*SecTransformSetAttribute(rsaEncryptionRef, kSecOAEPMGF1DigestAlgorithmAttributeName, kSecDigestSHA2, &errorRef);
     if(errorRef)
     {
     NSLog(@"Error setting OAEP digest algorithm to sha2: %@",errorRef);
     return nil;
     }*/

    //perform the encryption
    NSData* encryptedData = CFBridgingRelease(SecTransformExecute(rsaEncryptionRef, &errorRef));
    if(errorRef)
    {
//        NSLog(@"Error RSA encrypting session key: %@",errorRef);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorRSACannotExecuteTransform];
        if(rsaEncryptionRef)
            CFRelease(rsaEncryptionRef);
        return nil;
    }

    CFRelease(rsaEncryptionRef);

    //return the result
    return encryptedData;

#endif

}



//decrypt data encrypted by the previous method
+ (NSData*)LEGACY_RSAdecryptData:(NSData*)data withPrivateKeyLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{

    SecKeyRef privateDecryptionKeyRef = [MynigmaPrivateKey privateSecKeyRefWithLabel:keyLabel forEncryption:YES];

    if(!privateDecryptionKeyRef)
    {
//        NSLog(@"Private SecKeyRef invalid!!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSANoPublicKeyForLabel];
        return nil;
    }

#if TARGET_OS_IPHONE

    size_t plainBufferSize = SecKeyGetBlockSize(privateDecryptionKeyRef);
    uint8_t* plainBuffer = (uint8_t*)malloc(plainBufferSize);

    if(plainBufferSize < sizeof(data))
    {
        // Ordinarily, you would split the data up into blocks
        // equal to plainBufferSize, with the last block being
        // shorter. For simplicity, this example assumes that
        // the data is short enough to fit.
//        NSLog("Could not decrypt.  Packet too large.\n");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSAPacketTooLarge];
        return nil;
    }

    //  Error handling

    OSStatus status = SecKeyDecrypt(privateDecryptionKeyRef, kSecPaddingOAEP, (uint8_t*)data.bytes, (size_t)data.length, plainBuffer, &plainBufferSize);

    NSData* decryptedData = nil;

    if(status==noErr && plainBufferSize)
    {
        decryptedData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];
    }
    else
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSAWithOSStatus withOSStatus:status];
    }

    free(plainBuffer);

    return decryptedData;

#else

    //create decryption transform
    CFErrorRef errorRef;
    SecTransformRef rsaDecryptionRef = SecDecryptTransformCreate(privateDecryptionKeyRef, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotCreateTransform];
//        NSLog(@"Error creating RSA transform: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }

    //input is the data to be decrypted
    SecTransformSetAttribute(rsaDecryptionRef, kSecTransformInputAttributeName, (__bridge CFDataRef)data, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotSetInput];
//        NSLog(@"Error setting RSA input: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }

    //set padding to OAEP
    SecTransformSetAttribute(rsaDecryptionRef, kSecPaddingKey, kSecPaddingOAEPKey, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotSetPadding];
//        NSLog(@"Error setting padding to OAEP: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }

    //set digest algorithm to SHA2
    /*SecTransformSetAttribute(rsaDecryptionRef, kSecOAEPMGF1DigestAlgorithmAttributeName, kSecDigestSHA2, &errorRef);
     if(errorRef)
     {
     NSLog(@"Error setting OAEP digest algorithm to sha2: %@",errorRef);
     return nil;
     }*/

    //perform decryption
    NSData* decryptedData = (__bridge_transfer NSData*)SecTransformExecute(rsaDecryptionRef, &errorRef);

    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotExecuteTransform];
//        NSLog(@"Error RSA decrypting session key: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }

    if(rsaDecryptionRef)
        CFRelease(rsaDecryptionRef);

    //return result
    return decryptedData;

#endif

}

//decrypt data encrypted by the previous method
+ (SessionKeys*)RSAdecryptData:(NSData*)data withPrivateKeyLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    
    SecKeyRef privateDecryptionKeyRef = [MynigmaPrivateKey privateSecKeyRefWithLabel:keyLabel forEncryption:YES];
    
    if(!privateDecryptionKeyRef)
    {
        //        NSLog(@"Private SecKeyRef invalid!!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSANoPublicKeyForLabel];
        return nil;
    }
    
#if TARGET_OS_IPHONE
    
    size_t plainBufferSize = SecKeyGetBlockSize(privateDecryptionKeyRef);
    uint8_t* plainBuffer = (uint8_t*)malloc(plainBufferSize);
    
    if(plainBufferSize < sizeof(data))
    {
        // Ordinarily, you would split the data up into blocks
        // equal to plainBufferSize, with the last block being
        // shorter. For simplicity, this example assumes that
        // the data is short enough to fit.
        //        NSLog("Could not decrypt.  Packet too large.\n");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSAPacketTooLarge];
        return nil;
    }
    
    //  Error handling
    
    OSStatus status = SecKeyDecrypt(privateDecryptionKeyRef, kSecPaddingOAEP, (uint8_t*)data.bytes, (size_t)data.length, plainBuffer, &plainBufferSize);
    
    NSData* decryptedData = nil;
    
    if(status==noErr && plainBufferSize)
    {
        decryptedData = [NSData dataWithBytes:plainBuffer length:plainBufferSize];
    }
    else
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSAWithOSStatus withOSStatus:status];
    }
    
    free(plainBuffer);

    SessionKeys* sessionKeys = [SessionKeys sessionKeysFromData:decryptedData];

    return sessionKeys;
    
#else
    
    //create decryption transform
    CFErrorRef errorRef;
    SecTransformRef rsaDecryptionRef = SecDecryptTransformCreate(privateDecryptionKeyRef, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotCreateTransform];
        //        NSLog(@"Error creating RSA transform: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }
    
    //input is the data to be decrypted
    SecTransformSetAttribute(rsaDecryptionRef, kSecTransformInputAttributeName, (__bridge CFDataRef)data, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotSetInput];
        //        NSLog(@"Error setting RSA input: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }
    
    //set padding to OAEP
    SecTransformSetAttribute(rsaDecryptionRef, kSecPaddingKey, kSecPaddingOAEPKey, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotSetPadding];
        //        NSLog(@"Error setting padding to OAEP: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }
    
    //set digest algorithm to SHA2
    /*SecTransformSetAttribute(rsaDecryptionRef, kSecOAEPMGF1DigestAlgorithmAttributeName, kSecDigestSHA2, &errorRef);
     if(errorRef)
     {
     NSLog(@"Error setting OAEP digest algorithm to sha2: %@",errorRef);
     return nil;
     }*/
    
    //perform decryption
    NSData* decryptedData = (__bridge_transfer NSData*)SecTransformExecute(rsaDecryptionRef, &errorRef);
    
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorRSACannotExecuteTransform];
        //        NSLog(@"Error RSA decrypting session key: %@",errorRef);
        if(rsaDecryptionRef)
            CFRelease(rsaDecryptionRef);
        return nil;
    }
    
    if(rsaDecryptionRef)
        CFRelease(rsaDecryptionRef);
    
    SessionKeys* sessionKeys = [SessionKeys sessionKeysFromData:decryptedData];
    
    //return result
    return sessionKeys;
    
#endif
    
}


//sign some (already hashed) data using RSA and SHA-512 as hashing algorithm
+ (NSData*)RSASignHash:(NSData*)mHash withKeyLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback
{

    SecKeyRef privateSigningKeyRef = [MynigmaPrivateKey privateSecKeyRefWithLabel:keyLabel forEncryption:NO];

#if TARGET_OS_IPHONE

    if(!privateSigningKeyRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorNoKeyForKeyLabel];
        return nil;
    }

    size_t signedDataBufferSize = SecKeyGetBlockSize(privateSigningKeyRef);
    uint8_t* signedDataBuffer = (uint8_t*)malloc(signedDataBufferSize);

    if (signedDataBufferSize < sizeof(mHash))
    {
        // Ordinarily, you would split the data up into blocks
        // equal to plainBufferSize, with the last block being
        // shorter. For simplicity, this example assumes that
        // the data is short enough to fit.
//        NSLog(@"Could not decrypt.  Packet too large.\n");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSAPacketTooLarge];
        
        return nil;
    }

    OSStatus status = SecKeyRawSign(privateSigningKeyRef, kSecPaddingPKCS1SHA512, (uint8_t*)mHash.bytes, mHash.length, signedDataBuffer, &signedDataBufferSize);

    NSData* signedData = nil;

    if(status==noErr && signedDataBufferSize)
    {
        signedData = [NSData dataWithBytes:signedDataBuffer length:signedDataBufferSize];
    }
    else
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSAWithOSStatus withOSStatus:status];
//        NSLog(@"Error signing data: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
    }

    free(signedDataBuffer);

    return signedData;

#else

    CFErrorRef errorRef;
    SecTransformRef rsaSigningRef = SecSignTransformCreate(privateSigningKeyRef, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotCreateTransform];
//        NSLog(@"Error creating RSA signature transform");
        if(rsaSigningRef)
            CFRelease(rsaSigningRef);
        return nil;
    }

    //CFRelease(privateSigningKeyRef);

    SecTransformSetAttribute(rsaSigningRef, kSecTransformInputAttributeName, (__bridge CFDataRef)mHash, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotSetInput];
//        NSLog(@"Error setting RSA signature input: %@",errorRef);
        if(rsaSigningRef)
            CFRelease(rsaSigningRef);
        return nil;
    }

    //CFStringRef typeRef = (CFStringRef)SecTransformGetAttribute(rsaSigningRef, kSecInputIsAttributeName);

    //NSLog(@"Input: %@", (__bridge NSString*)typeRef);


    SecTransformSetAttribute(rsaSigningRef, kSecInputIsAttributeName, kSecInputIsDigest, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotSetInputTypeToDigest];
//        NSLog(@"Error setting input type to digest: %@",errorRef);
        return nil;
    }

    SecTransformSetAttribute(rsaSigningRef, kSecPaddingKey, kSecPaddingPKCS1Key, &errorRef);
    if (errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotSetPadding];
        return nil;
    }

    SecTransformSetAttribute(rsaSigningRef, kSecDigestTypeAttribute, kSecDigestSHA2, &errorRef);
    if(errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotSetDigest];
        return nil;
    }


    Boolean set = SecTransformSetAttribute(rsaSigningRef, kSecDigestLengthAttribute, (__bridge CFNumberRef)@512, &errorRef);
    if (!set || errorRef)
    {
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotSetDigestLength];
        return nil;
    }


    NSData* rsaSignature = CFBridgingRelease(SecTransformExecute(rsaSigningRef, &errorRef));
    if(errorRef)
    {
//        NSLog(@"Error RSA signing message digest: %@",errorRef);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaSignatureErrorRSACannotExecuteTransform];
        if(rsaSigningRef)
            CFRelease(rsaSigningRef);
        return nil;
    }
    CFRelease(rsaSigningRef);

    //NSLog(@"Signature: %@",rsaSignature);

    return rsaSignature;

#endif

}

//verifies a signature produced by the previous method
+ (MynigmaFeedback*)RSAVerifySignature:(NSData*)signature ofHash:(NSData*)dataHash version:(NSString*)version withKeyLabel:(NSString*)keyLabel
{

    SecKeyRef publicVerificationKeyRef = [MynigmaPublicKey publicSecKeyRefWithLabel:keyLabel forEncryption:NO];

    if(!publicVerificationKeyRef)
        return [MynigmaFeedback feedback:MynigmaVerificationErrorNoKey];

#if TARGET_OS_IPHONE

    OSStatus status = SecKeyRawVerify(publicVerificationKeyRef, kSecPaddingPKCS1SHA512, (uint8_t*)dataHash.bytes, (size_t)dataHash.length, (uint8_t*)signature.bytes, (size_t)signature.length);

    if(status==errSecSuccess)
    {
        return nil;
    }
    
    return [MynigmaFeedback feedback:MynigmaVerificationErrorRSAInvalidSignature];

#else

    CFErrorRef errorRef = nil;
    SecTransformRef rsaVerificationRef = SecVerifyTransformCreate(publicVerificationKeyRef, (__bridge CFDataRef)signature, &errorRef);
    if(errorRef)
    {
//        NSLog(@"Error creating RSA signature transform: %@ = %@ = %@",errorRef, dataHash, publicVerificationKeyRef);
        if(rsaVerificationRef)
            CFRelease(rsaVerificationRef);
        return [MynigmaFeedback feedback:MynigmaVerificationErrorRSACannotCreateTransform];
    }

    //CFRelease(publicVerificationKeyRef);

    SecTransformSetAttribute(rsaVerificationRef, kSecTransformInputAttributeName, (__bridge CFTypeRef)dataHash, &errorRef);
    if(errorRef)
    {
//        NSLog(@"Error setting RSA signature input: %@",errorRef);
        if(rsaVerificationRef)
            CFRelease(rsaVerificationRef);
        return [MynigmaFeedback feedback:MynigmaVerificationErrorRSACannotSetInput];
    }

    SecTransformSetAttribute(rsaVerificationRef, kSecPaddingKey, kSecPaddingPKCS1Key, &errorRef);
    if(errorRef)
    {
//        NSLog(@"Error setting padding to PKCS1: %@",errorRef);
        if(rsaVerificationRef)
            CFRelease(rsaVerificationRef);
        return [MynigmaFeedback feedback:MynigmaVerificationErrorRSACannotSetPadding];
    }

    @try
    {

        if(CFBridgingRelease(SecTransformExecute(rsaVerificationRef, &errorRef)))
        {
            if(rsaVerificationRef)
                CFRelease(rsaVerificationRef);

            if(errorRef)
            {
                return [MynigmaFeedback feedback:MynigmaVerificationErrorRSACannotExecuteTransform];
            }
            
            //NSLog(@"Signature is OK!!");
            return [MynigmaFeedback feedback:MynigmaVerificationSuccess];
        }
    }
    @catch(NSException* exception)
    {
//        NSLog(@"Exception raised while trying to verify signature!!! %@", exception);
        return [MynigmaFeedback feedback:MynigmaVerificationErrorRSAExceptionCaught];
    }
    
    if(rsaVerificationRef)
        CFRelease(rsaVerificationRef);
    
//    NSLog(@"Signature does not match!! %@",errorRef);

    return [MynigmaFeedback feedback:MynigmaVerificationErrorRSAInvalidSignature];
    
#endif
    
}


//+ (BOOL)LEGACY_RSAverifySignature:(NSData*)signature ofHash:(NSData*)dataHash withKeyLabel:(NSString*)keyLabel
//{
//    SecKeyRef publicVerificationKeyRef = [MynigmaPublicKey publicSecKeyRefWithLabel:keyLabel forEncryption:NO];
//
//    if(!publicVerificationKeyRef)
//        return NO;
//
//#if TARGET_OS_IPHONE
//
//    OSStatus status = SecKeyRawVerify(publicVerificationKeyRef, kSecPaddingPKCS1SHA1, (uint8_t*)dataHash.bytes, (size_t)dataHash.length, (uint8_t*)signature.bytes, (size_t)signature.length);
//
//    BOOL returnValue = NO;
//
//    if(status==errSecSuccess)
//    {
//        returnValue = YES;
//    }
//    else
//        NSLog(@"Error verifying signature: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
//
//    return returnValue;
//
//#else
//
//    CFErrorRef errorRef = nil;
//    SecTransformRef rsaVerificationRef = SecVerifyTransformCreate(publicVerificationKeyRef, (__bridge CFDataRef)signature, &errorRef);
//    if(errorRef)
//    {
//        NSLog(@"Error creating RSA signature transform: %@ = %@ = %@",errorRef, dataHash, publicVerificationKeyRef);
//        if(rsaVerificationRef)
//            CFRelease(rsaVerificationRef);
//        return NO;
//    }
//
//    //CFRelease(publicVerificationKeyRef);
//
//    SecTransformSetAttribute(rsaVerificationRef, kSecTransformInputAttributeName, (__bridge CFTypeRef)dataHash, &errorRef);
//    if(errorRef)
//    {
//        NSLog(@"Error setting RSA signature input: %@",errorRef);
//        if(rsaVerificationRef)
//            CFRelease(rsaVerificationRef);
//        return NO;
//    }
//
//    SecTransformSetAttribute(rsaVerificationRef, kSecPaddingKey, kSecPaddingPKCS1Key, &errorRef);
//    if(errorRef)
//    {
//        NSLog(@"Error setting padding to PKCS1: %@",errorRef);
//        if(rsaVerificationRef)
//            CFRelease(rsaVerificationRef);
//        return NO;
//    }
//
//    @try
//    {
//
//        if(CFBridgingRelease(SecTransformExecute(rsaVerificationRef, &errorRef)))
//            if(!errorRef)
//            {
//                if(rsaVerificationRef)
//                    CFRelease(rsaVerificationRef);
//                //NSLog(@"Signature is OK!!");
//                return YES;
//            }
//    }
//    @catch(NSException* exception)
//    {
//        NSLog(@"Exception raised while trying to verify signature!!! %@", exception);
//        return NO;
//    }
//
//    if(rsaVerificationRef)
//        CFRelease(rsaVerificationRef);
//
//    NSLog(@"Signature does not match!! %@",errorRef);
//    
//    return NO;
//    
//#endif
//
//}



//generates a new AES session key
+ (NSData*)generateNewAESSessionKeyData
{
    uint8_t* sessionKeyBuffer = (uint8_t*)malloc(kCCBlockSizeAES128);

    int result = SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, sessionKeyBuffer);

    NSData* sessionKeyData = nil;

    if(result == 0)
    {
        sessionKeyData = [NSData dataWithBytes:sessionKeyBuffer length:kCCBlockSizeAES128];
    }
    else
    {
        NSLog(@"Error generating random data!!!");
    }

    if(sessionKeyBuffer)
        free(sessionKeyBuffer);

    return sessionKeyData;
}

//generates a new HMAC secret (length 128 bytes)
+ (NSData*)generateNewHMACSecret
{
    uint8_t* sessionKeyBuffer = (uint8_t*)malloc(128);
    
    int result = SecRandomCopyBytes(kSecRandomDefault, 128, sessionKeyBuffer);
    
    NSData* sessionKeyData = nil;
    
    if(result == 0)
    {
        sessionKeyData = [NSData dataWithBytes:sessionKeyBuffer length:128];
    }
    else
    {
        NSLog(@"Error generating random data!!!");
    }
    
    if(sessionKeyBuffer)
        free(sessionKeyBuffer);
    
    return sessionKeyData;
}


//#else
//
////generates a new AES session key
//+ (id)generateNewAESSessionKey
//{
//    NSMutableDictionary* keyCreationDict = [NSMutableDictionary dictionaryWithDictionary:
//                                            @{(id)kSecAttrKeyType:(id)kSecAttrKeyTypeAES,
//                                              (id)kSecAttrKeySizeInBits:@128,
//                                              (id)kSecAttrKeyClass:(id)kSecAttrKeyClassSymmetric,
//                                              (id)kSecAttrIsPermanent:[NSNumber numberWithBool:NO]}];
//    CFErrorRef errorRef = nil;
//    SecKeyRef sessionKeyRef = SecKeyGenerateSymmetric((__bridge CFDictionaryRef)(keyCreationDict), &errorRef);
//
//    if(errorRef)
//    {
//        NSLog(@"Error generating key: %@",(__bridge NSError*)errorRef);
//        return nil;
//    }
//    return (__bridge_transfer id)sessionKeyRef;
//}
//
////gets the bits of the session key referenced by sessionKeyRef
//+ (NSData*)getAESSessionKeyData:(id)sessionKeyRef
//{
//    SecItemImportExportKeyParameters params;
//
//    params.version = SEC_KEY_IMPORT_EXPORT_PARAMS_VERSION;
//    params.flags = 0;
//    params.passphrase = NULL;
//    params.alertTitle = NULL;
//    params.alertPrompt = NULL;
//    params.accessRef = NULL;
//
//    CFMutableArrayRef keyUsage = (__bridge CFMutableArrayRef)[NSMutableArray arrayWithObjects:(id)kSecAttrCanEncrypt, kSecAttrCanDecrypt, nil];
//    CFMutableArrayRef keyAttributes = (__bridge CFMutableArrayRef)[NSMutableArray array];
//    params.keyUsage = keyUsage;
//    params.keyAttributes = keyAttributes;
//
//    SecExternalFormat externalFormat = kSecFormatRawKey;
//    int flags = 0;
//
//    CFDataRef keyDataRef = NULL;
//    //[KeychainHelper unlockKeychain];
//    OSStatus oserr = SecItemExport((__bridge SecKeyRef)sessionKeyRef, externalFormat, flags, &params, &keyDataRef);
//    //[KeychainHelper lockKeychain];
//    if (oserr != noErr) {
//        NSLog(@"Failed to export key: %@",[NSError errorWithDomain:NSOSStatusErrorDomain code:oserr userInfo:nil]);
//        return nil;
//    }
//    NSData* keyData = (__bridge_transfer NSData*)keyDataRef;
//    return keyData;
//}
//
//#endif



#pragma mark - HASHING

//hash some data using SHA-512
+ (NSData*)SHA512DigestOfData:(NSData*)data
{
    if(!data.length)
        return nil;

    uint8_t digest[CC_SHA512_DIGEST_LENGTH];

    CC_SHA512([data bytes], (CC_LONG)[data length], digest);

    NSData* digestData = [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];

    return digestData;
}

+ (NSData*)SHA256DigestOfData:(NSData*)data
{
    if(!data.length)
        return nil;
    
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256([data bytes], (CC_LONG)[data length], digest);
    
    NSData* digestData = [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
    
    return digestData;
}



+ (NSData*)HMACForMessage:(NSData *)message withSecret:(NSData *)secret
{
    uint8_t digest[CC_SHA512_DIGEST_LENGTH];

    CCHmac(kCCHmacAlgSHA512, secret.bytes, secret.length, message.bytes, message.length, digest);

    return [NSData dataWithBytes:digest length:CC_SHA512_DIGEST_LENGTH];
}



//digest(k, m) = 􏰅[mi ∗ ki + (mi ∗ ki+1 div 2b)] mod 2b

//+ (NSData*)digestOfM:(NSData*)m
//{
//    NSInteger t = m.length / 4;
//
//    //split the data into 4-byte chunks
//    if(!m.length || m.length % 4 != 0)
//        return nil;
//
//    NSMutableArray* mInChunks = [NSMutableArray new];
//
//    for(NSInteger chunkIndex = 0; chunkIndex < t; chunkIndex++)
//    {
//        [mInChunks addObject:[m subdataWithRange:NSMakeRange(chunkIndex * 4, 4)]];
//    }
//
//    NSData* k = [AppleEncryptionWrapper randomBytesOfLength:m.length + 4];
//
//    NSMutableArray* kInChunks = [NSMutableArray new];
//
//    for(NSInteger chunkIndex = 0; chunkIndex < t + 1; chunkIndex++)
//    {
//        [kInChunks addObject:[k subdataWithRange:NSMakeRange(chunkIndex * 4, 4)]];
//    }
//
//    unsigned long long sum = 0;
//
//    for(NSInteger i = 0; i < t; i++)
//    {
//        unsigned long long m_i = 0;
//
//        [mInChunks[i] getBytes:&m_i length:sizeof(unsigned long)];
//
//        unsigned long long k_i = 0;
//
//        [kInChunks[i] getBytes:&k_i length:sizeof(unsigned long)];
//
//        unsigned long long k_i_plus_1 = 0;
//
//        [kInChunks[i] getBytes:&k_i_plus_1 length:sizeof(unsigned long)];
//
//        unsigned long long result1 = m_i * k_i;
//
//        unsigned long long result2 = m_i * k_i_plus_1;
//
//        sum += (result1 % (2ULL >> 32ULL));
//    }
//
//    return nil;
//}


//short digest chunks, formatted as four chunks of three characters each
+ (NSArray*)shortDigestChunksOfData:(NSData*)data
{
    NSData* sha512Digest = [self SHA512DigestOfData:data];

    if(!sha512Digest)
        return nil;

    NSMutableArray* digestChunks = [NSMutableArray new];

    for(NSInteger chunkIndex = 0; chunkIndex<3; chunkIndex++)
    {
        NSInteger chunkSize = 3; //24 bits = 3 bytes = 4 base64 chars

        NSData* subData = [sha512Digest subdataWithRange:NSMakeRange(chunkIndex*chunkSize, chunkSize)];

        NSString* chunk = [subData base64];

        [digestChunks addObject:chunk];
    }

    return digestChunks;
}


+ (NSString*)nonUniqueIDForEmailAddress:(NSString*)emailAddress
{
    NSString* email = [emailAddress lowercaseString];

    NSData* sha512Digest = [self SHA512DigestOfData:[email dataUsingEncoding:NSUTF8StringEncoding]];

    if(!sha512Digest)
        return @"";

    NSData* subData = [sha512Digest subdataWithRange:NSMakeRange(0, 3)];

    NSString* chunk = [subData base64];

    return chunk;
}




#pragma mark -
#pragma mark AES IMPLEMENTATION


//encrypt a block of data using AES with 256 bit key in CBC mode with random IV (sessionKeyData contains the raw data of the key)
+ (NSData*)AESencryptData:(NSData*)data withSessionKeyData:(NSData*)sessionKeyData withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    //fill IV with random data
    NSData* initialVector = [[NSFileHandle fileHandleForReadingAtPath:@"/dev/random"] readDataOfLength:16];

    return [self AESencryptData:data withSessionKeyData:sessionKeyData IV:initialVector withFeedback:mynigmaFeedback];
}

+ (NSData*)AESencryptData:(NSData*)data withSessionKeyData:(NSData*)sessionKeyData IV:(NSData*)initialVector withFeedback:(MynigmaFeedback**)mynigmaFeedback
{
    //the data buffer
    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    void* buffer = malloc(bufferSize);

    //will be set to the number of bytes actually encrypted
    size_t numBytesEncrypted = 0;

    //encrypting in CBC mode
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, [sessionKeyData bytes], kCCKeySizeAES128, (char*)[initialVector bytes], [data bytes], [data length], buffer, bufferSize, &numBytesEncrypted);

    //the number of actually encrypted bytes should never be shorter than the data
    if(numBytesEncrypted<[data length])
    {
//        NSLog(@"INCOMPLETE DATA ENCRYPTED!!!!! %ld vs. %ld bytes...",numBytesEncrypted,(unsigned long)data.length);
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorAESTooFewBytesEncrypted];
        return nil;
    }

    if (cryptStatus == kCCSuccess)
    {
        //encryption successful

        //first take the IV
        NSMutableData* encodedData = [initialVector mutableCopy];

        //then append the encrypted data
        [encodedData appendData:[[NSData alloc] initWithBytes:buffer length:numBytesEncrypted]];

        free(buffer);
        //now return the result
        return encodedData;
    }

    free(buffer);

    //error
//    NSLog(@"Error AES encrypting data!");
    if(mynigmaFeedback)
        *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaEncryptionErrorAESCCCryptorFail];

    return nil;
}

//decrypts a block containing an IV followed by some data encrypted using AES with 256 bit key in CBC mode
+ (NSData*)AESdecryptData:(NSData*)data withSessionKeyData:(NSData*)sessionKeyData withFeedback:(MynigmaFeedback **)mynigmaFeedback
{
    //IV and a single block of encrypted data should be at least 128 bits + 128 bits = 32 bytes
    if(data.length < 32)
    {
//        NSLog(@"Trying to AES-decrypt invalid data!");
        if(mynigmaFeedback)
            *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorAESDataTooShort];

        return nil;
    }

    //first 16 bytes are the IV
    NSData* initialVector = [data subdataWithRange:NSMakeRange(0, 16)];

    //the rest is data to be decrypted
    NSData* actualData = [data subdataWithRange:NSMakeRange(16,[data length]-16)];

    //the buffer for the decrypted data
    size_t bufferSize = [actualData length];
    void* buffer = malloc(bufferSize);

    //will be set to the number of bytes actually decrypted
    size_t numBytesDecrypted = 0;

    //perform decryption
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding, [sessionKeyData bytes], kCCKeySizeAES128, (char*)[initialVector bytes], [actualData bytes], [actualData length], buffer, bufferSize, &numBytesDecrypted);
    if (cryptStatus == kCCSuccess)
    {
        //decryption successful
        NSData* decodedData = [[NSData alloc] initWithBytes:buffer length:numBytesDecrypted];

        free(buffer);

        //return decoded data
        return decodedData;
    }

    free(buffer);
    
    if(mynigmaFeedback)
        *mynigmaFeedback = [MynigmaFeedback feedback:MynigmaDecryptionErrorAESCCCryptorFail];
    //error
//    NSLog(@"Error AES decrypting data!");
    return nil;
}

+ (NSData*)randomBytesOfLength:(NSInteger)length
{
    uint8_t* dataBuffer = (uint8_t*)malloc(length);

    int result = SecRandomCopyBytes(kSecRandomDefault, length, dataBuffer);

    NSData* randomData = nil;

    if(result == 0)
    {
        randomData = [NSData dataWithBytes:dataBuffer length:length];
    }
    else
    {
        NSLog(@"Error generating random data!!!");
        return nil;
    }

    if(dataBuffer)
        free(dataBuffer);

    return randomData;
}


+ (void)generateNewPrivateKeyPairForEmailAddress:(NSString*)email withCallback:(void(^)(NSString* keyLabel, NSData* encPersRef, NSData* verPersRef, NSData* decPersRef, NSData* sigPersRef))callback
{
    //use the current date for the second part of the keyLabel
    __block NSDate* currentDate = [NSDate date];

    //the email address is the first part
    __block NSString* keyLabel = [NSString stringWithFormat:@"%@|%f",email,[currentDate timeIntervalSince1970]];

    [AppleEncryptionWrapper generateNewPrivateKeyPairWithKeyLabel:keyLabel withCallback:callback];
}

+ (void)generateNewPrivateKeyPairWithKeyLabel:(NSString*)keyLabel withCallback:(void(^)(NSString* keyLabel, NSData* encPersRef, NSData* verPersRef, NSData* decPersRef, NSData* sigPersRef))callback
{
    //the dictionary of properties for the keychain items to be added

    //general
    __block NSMutableDictionary* passDict = [NSMutableDictionary new];
    [passDict setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [passDict setObject:@4096 forKey:(__bridge id)kSecAttrKeySizeInBits];


    //specific to signature keys
    NSString* label = [NSString stringWithFormat:@"Mynigma signature key %@",keyLabel];
    [passDict setObject:label forKey:(__bridge id)kSecAttrLabel];
    [passDict setObject:@"Mynigma" forKey:(__bridge id)kSecAttrApplicationLabel];
    [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecAttrIsPermanent];
    [passDict setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnRef];
    [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanDecrypt];
    [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanEncrypt];

#if TARGET_OS_IPHONE

    //on the iphone include the application tag as well
    NSData* labelData = [label dataUsingEncoding:NSUTF8StringEncoding];

    passDict[(__bridge id)kSecAttrApplicationTag] = labelData;

#else

    //on the Mac add a description
    [passDict setObject:@"Mynigma signature key" forKey:(__bridge id)kSecAttrDescription];

#endif

    SecKeyRef publicKey = NULL;
    SecKeyRef privateKey = NULL;

    //generate the signature key pair
    OSStatus status = SecKeyGeneratePair((__bridge CFDictionaryRef)passDict, &publicKey, &privateKey);
    if(status != noErr)
    {
        NSLog(@"1 Error creating key pair: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        callback(nil, nil, nil, nil, nil);
        return;
    }

    CFDataRef persistentPublicRef = NULL;
    CFDataRef persistentPrivateRef = NULL;

    //create a persistent reference for the signature public key

#if TARGET_OS_IPHONE

    NSMutableDictionary* query = [NSMutableDictionary dictionaryWithDictionary:
                                  @{(__bridge id)kSecClass:(__bridge id)kSecClassKey,
                                    (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeRSA,
                                    (__bridge id)kSecAttrLabel:label,
                                    (__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPrivate,
                                    (__bridge id)kSecReturnPersistentRef:@YES}];

    //get SecKeyRef from persistent ref
    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&persistentPrivateRef);

#else

    status = SecKeychainItemCreatePersistentReference ((SecKeychainItemRef)publicKey, &persistentPublicRef);

#endif

    if(status != noErr)
    {
        NSLog(@"2 Error creating key pair: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        callback(nil, nil, nil, nil, nil);
        return;
    }

    //create a persistent reference for the signature private key

#if TARGET_OS_IPHONE

    [query setObject:(__bridge id)kSecAttrKeyClassPublic forKey:(__bridge id)kSecAttrKeyClass];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&persistentPublicRef);

#else

    status = SecKeychainItemCreatePersistentReference ((SecKeychainItemRef)privateKey, &persistentPrivateRef);

#endif

    if(status != noErr)
    {
        NSLog(@"3 Error creating key pair: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        callback(nil, nil, nil, nil, nil);
        return;
    }

    NSData* privSign = [[NSData alloc] initWithData:CFBridgingRelease(persistentPrivateRef)];
    NSData* pubVer = [[NSData alloc] initWithData:CFBridgingRelease(persistentPublicRef)];


    //halfway done - do much the same thing for the encryption key pair

    label = [NSString stringWithFormat:@"Mynigma encryption key %@",keyLabel];
    [passDict setObject:label forKey:(__bridge id)kSecAttrLabel];
    [passDict removeObjectForKey:(__bridge id)kSecAttrCanEncrypt];
    [passDict removeObjectForKey:(__bridge id)kSecAttrCanDecrypt];
    [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanSign];
    [passDict setObject:(__bridge id)kCFBooleanFalse forKey:(__bridge id)kSecAttrCanVerify];

    publicKey = NULL;
    privateKey = NULL;

#if TARGET_OS_IPHONE

    labelData = [label dataUsingEncoding:NSUTF8StringEncoding];

    passDict[(__bridge id)kSecAttrApplicationTag] = labelData;

#else

    [passDict setObject:@"Mynigma encryption key" forKey:(__bridge id)kSecAttrDescription];

#endif

    //generate the encryption key pair
    status = SecKeyGeneratePair((__bridge CFDictionaryRef)passDict, &publicKey, &privateKey);

    if(status != noErr)
    {
        NSLog(@"4 Error creating key pair: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        callback(nil, nil, nil, nil, nil);
        return;
    }

    persistentPublicRef = NULL;
    persistentPrivateRef = NULL;

    //create a persistent reference for the public encryption key

#if TARGET_OS_IPHONE

    query = [NSMutableDictionary dictionaryWithDictionary:
             @{(__bridge id)kSecClass:(__bridge id)kSecClassKey,
               (__bridge id)kSecAttrKeyType:(__bridge id)kSecAttrKeyTypeRSA,
               (__bridge id)kSecAttrKeySizeInBits:@4096,
               (__bridge id)kSecAttrLabel:label,
               (__bridge id)kSecAttrKeyClass:(__bridge id)kSecAttrKeyClassPublic,
               (__bridge id)kSecReturnPersistentRef:@YES}];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&persistentPublicRef);

#else

    status = SecKeychainItemCreatePersistentReference ((SecKeychainItemRef)publicKey, &persistentPublicRef);

#endif

    if(status != noErr)
    {
        NSLog(@"5 Error creating key pair: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        callback(nil, nil, nil, nil, nil);
        return;
    }

    //create a persistent reference for the private encryption key

#if TARGET_OS_IPHONE

    [query setObject:(__bridge id)kSecAttrKeyClassPrivate forKey:(__bridge id)kSecAttrKeyClass];

    status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef*)&persistentPrivateRef);
#else

    status = SecKeychainItemCreatePersistentReference ((SecKeychainItemRef)privateKey, &persistentPrivateRef);

#endif

    if(status != noErr)
    {
        NSLog(@"6 Error creating key pair: %@", [NSError errorWithDomain:NSOSStatusErrorDomain code:status userInfo:nil]);
        callback(nil, nil, nil, nil, nil);
        return;
    }
    NSData* privDecr = [[NSData alloc] initWithData:CFBridgingRelease(persistentPrivateRef)];
    NSData* pubEncr = [[NSData alloc] initWithData:CFBridgingRelease(persistentPublicRef)];

    //now return the result
    callback(keyLabel, pubEncr, pubVer, privDecr, privSign);
}

@end
