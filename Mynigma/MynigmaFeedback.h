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





#import <Foundation/Foundation.h>

@class EmailMessage;



typedef NS_ENUM(NSInteger, MynigmaFeedbackCode)
{
    /* DO NOT CHANGE THESE VALUES*/
    /* IT WOULD AFFECT ERROR CODES ALREADY STORED IN MESSAGES */
    /* ADDING NEW VALUES IS OK */
    MynigmaErrorUnspecified = 101,
    
    
    MynigmaEncryptionErrorAttachmentHasNoData = 201,
    MynigmaEncryptionErrorKeyAndLabelCountMismatch = 202,
    MynigmaEncryptionErrorEmptyPayload = 203,
    MynigmaEncryptionErrorNoMessageForObjectID = 304,
    MynigmaEncryptionErrorSavingLocalContext = 305,
    
    
    
    MynigmaEncryptionErrorRSACannotCreateTransform = 221,
    MynigmaEncryptionErrorRSACannotSetInput = 222,
    MynigmaEncryptionErrorRSACannotSetPadding = 223,
    MynigmaEncryptionErrorRSACannotExecuteTransform = 224,
    MynigmaEncryptionErrorRSANoPublicKeyForLabel = 225,
    MynigmaEncryptionErrorRSAPacketTooLarge = 226,
    
    
    MynigmaEncryptionErrorAESTooFewBytesEncrypted = 241,
    MynigmaEncryptionErrorAESCCCryptorFail = 242,
    
    MynigmaEncryptionErrorNoCurrentPrivateKeyLabel = 251,
    MynigmaEncryptionErrorSavingContext = 252,
    MynigmaEncryptionErrorObtainingPermanentObjectID = 253,
    MynigmaEncryptionErrorNoPublicKeyLabels = 254,
    MynigmaEncryptionErrorNoExpectedPublicKeyLabels = 255,

    
    
    MynigmaDecryptionErrorNoKeyLabel = 301,
    MynigmaDecryptionErrorNoKey = 302,
    MynigmaDecryptionErrorNoSessionKey = 303,
    MynigmaDecryptionErrorMessageCorrupt = 304,
    MynigmaDecryptionErrorNoData = 305,
    MynigmaDecryptionErrorNoMessageData = 306,
    MynigmaDecryptionErrorInvalidAttachmentObjectID = 307,
    MynigmaDecryptionErrorAttachmentNotDownloaded = 308,
    MynigmaDecryptionErrorInternalError = 309,
    MynigmaDecryptionErrorAttachmentHashIsEmpty = 310,
    MynigmaDecryptionErrorNoHashValue = 311,
    MynigmaDecryptionErrorInvalidHash = 312,
    MynigmaDecryptionErrorNoMessageForObjectID = 313,
    MynigmaDecryptionErrorSavingLocalContext = 314,
    MynigmaFeedbackDecryptionErrorNoAttachmentForObjectID = 315,
    
    MynigmaDecryptionErrorOldEncryptionFormat = 316,
    MynigmaDecryptionErrorInvalidHMAC = 317,
    MynigmaDecryptionErrorWrongAttachmentCount = 318,
    
    MynigmaDecryptionErrorRSACannotExecuteTransform = 321,
    MynigmaDecryptionErrorRSANoPublicKeyForLabel = 322,
    MynigmaDecryptionErrorRSAPacketTooLarge = 323,
    MynigmaDecryptionErrorRSAWithOSStatus = 324,
    MynigmaDecryptionErrorRSACannotCreateTransform = 325,
    MynigmaDecryptionErrorRSACannotSetInput = 326,
    MynigmaDecryptionErrorRSACannotSetPadding = 327,
 
    
    MynigmaDecryptionErrorAESDataTooShort = 341,
    MynigmaDecryptionErrorAESCCCryptorFail = 342,
    
    
    
    MynigmaSignatureErrorNoKeyLabel = 401,
    MynigmaSignatureErrorNoKey = 402,
    MynigmaSignatureErrorInvalidKeys = 403,
    MynigmaSignatureErrorNoKeyForKeyLabel = 404,
    MynigmaSignatureErrorEmptySignedData = 405,
    
    
    
    MynigmaSignatureErrorRSACannotCreateTransform = 421,
    MynigmaSignatureErrorRSACannotSetInput = 422,
    MynigmaSignatureErrorRSACannotSetPadding = 423,
    MynigmaSignatureErrorRSACannotExecuteTransform = 424,
    MynigmaSignatureErrorRSACannotSetInputTypeToDigest = 425,
    MynigmaSignatureErrorRSACannotSetDigest = 426,
    MynigmaSignatureErrorRSACannotSetDigestLength = 427,
    MynigmaSignatureErrorRSANoData = 428,
    MynigmaSignatureErrorRSAPacketTooLarge = 429,
    MynigmaSignatureErrorRSAWithOSStatus = 430,
    MynigmaSignatureErrorRSAExceptionCaught = 431,
    
    
    MynigmaVerificationErrorNoKeyLabel = 501,
    MynigmaVerificationErrorPreviouslyValidKey = 502,
    MynigmaVerificationErrorNoKeyLabelData = 503,
    MynigmaVerificationErrorNoKey = 504,
    MynigmaVerificationErrorInvalidSignature = 505,
    
    
    
    
  
    MynigmaVerificationErrorRSACannotCreateTransform = 521,
    MynigmaVerificationErrorRSACannotSetInput = 522,
    MynigmaVerificationErrorRSACannotSetPadding = 523,
    MynigmaVerificationErrorRSACannotExecuteTransform = 524,
    MynigmaVerificationErrorRSACannotSetInputTypeToDigest = 525,
    MynigmaVerificationErrorRSACannotSetDigest = 526,
    MynigmaVerificationErrorRSACannotSetDigestLength = 527,
    MynigmaVerificationErrorRSAInvalidSignature = 528,
    MynigmaVerificationErrorRSAExceptionCaught = 529,
    
    
    
    MynigmaSignatureWarningNoUserRecipient = 1001,
    MynigmaSignatureWarningSomeInvalidKeys = 1002,
    
    
    MynigmaOverriddenErrorWarningPreviouslyValidKey = 1100,
    MynigmaOverriddenErrorWarningNoKey = 1101,
    MynigmaOverriddenErrorWarningOldEncryptionFormat = 1102,
    MynigmaOverriddenErrorWarningInvalidSignature = 1103,
    
    MynigmaStatusDownloading = 2001,
    MynigmaStatusDownloadedAndDecrypted = 2002,
    MynigmaStatusDecrypting = 2003,
    MynigmaStatusNotDownloaded = 2004,
    
    MynigmaEncryptionSuccess = 3201,
    MynigmaDecryptionSuccess = 3301,
    MynigmaSignatureSuccess = 3401,
    MynigmaVerificationSuccess = 3501,
};



@interface MynigmaFeedback : NSError

@property EmailMessage* message;

//some errors can be overridden
//this is the code of the error that should be presented after override
@property NSNumber* additionalCode;


- (BOOL)isSuccess;
- (BOOL)isError;
- (BOOL)isWarning;


- (BOOL)showMessage;
- (BOOL)showFeedbackWindow;
- (BOOL)showAlert;
- (BOOL)showProgressIndicator;

- (NSString*)archivableString;


#pragma mark - Generic MynigmaFeedback generation

+ (MynigmaFeedback*)feedbackWithArchivedString:(NSString*)stringValue message:(EmailMessage*)message;
+ (MynigmaFeedback*)feedback:(MynigmaFeedbackCode)feedbackCode;
+ (MynigmaFeedback*)feedback:(MynigmaFeedbackCode)feedbackCode message:(EmailMessage*)message;
+ (MynigmaFeedback*)feedback:(MynigmaFeedbackCode)feedbackCode withOSStatus:(OSStatus)status;


- (MynigmaFeedback*)override;


#pragma mark - Recovery attempts

- (IBAction)recoveryOption0Picked:(id)sender;
- (IBAction)recoveryOption1Picked:(id)sender;
- (IBAction)recoveryOption2Picked:(id)sender;
- (IBAction)recoveryOption3Picked:(id)sender;
- (IBAction)recoveryOption4Picked:(id)sender;
- (IBAction)recoveryOption5Picked:(id)sender;



@end
