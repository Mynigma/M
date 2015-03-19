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
#import "TestHelper.h"
#import <OCMock/OCMock.h>
#import "MynigmaPublicKey+Category.h"
#import "MynigmaPrivateKey+Category.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "MynigmaMessage+Category.h"
#import "MynigmaFeedback.h"
#import "AccountCreationManager.h"
#import "IMAPAccount.h"
#import "SendingManager.h"
#import "EmailMessageInstance+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "ThreadHelper.h"


//#import <Security/cssmkrapi.h>


@interface Temporary_Tests : XCTestCase

@end

@implementation Temporary_Tests

- (void)testSendEncryptedMessage
{
    //create some sample public key data
    NSArray* encryptionKeyData = [TestHelper publicKeySampleData:@1];
    
    XCTAssertNotNil(encryptionKeyData);
    
    id publicKeyClassMock = OCMClassMock([MynigmaPublicKey class]);
    
    NSString* keyLabel1 = @"wilhelm.schuettelspeer@gmail.com|123";
    
    NSString* keyLabel3 = @"mynigmaunittests@gmail.com|123";
    
    //return sample public key data for keyLabel1
    OCMStub([publicKeyClassMock dataForExistingMynigmaPublicKeyWithLabel:keyLabel1]).andReturn(encryptionKeyData);
    
    //encrypting with keyLabel1
    OCMStub([publicKeyClassMock encryptionKeyLabelsForRecipients:[OCMArg any] allowErrors:NO]).andReturn(@[keyLabel1]);

    //signing with keyLabel3 (self-signed)
    OCMStub([publicKeyClassMock introductionOriginKeyLabelsForRecipients:[OCMArg any] allowErrors:NO]).andReturn(@[keyLabel3]);

    
    //some private key data
    NSArray* signatureKeyData = [TestHelper privateKeySampleData:@3];
    
    XCTAssertNotNil(signatureKeyData);
    
    id privateKeyClassMock = OCMClassMock([MynigmaPrivateKey class]);
    
    OCMStub([privateKeyClassMock dataForPrivateKeyWithLabel:keyLabel3]).andReturn(signatureKeyData);
    
    OCMStub([privateKeyClassMock senderKeyLabelForMessage:[OCMArg any]]).andReturn(keyLabel3);
    

    
    NSString* email1 = @"mynigmaunittests@gmail.com";
    
    IMAPAccount* account1 = [AccountCreationManager temporaryAccountWithEmail:email1];
    
    [account1.quickAccessSession setPassword:@"; DROP TABLE PASSWORDS2"];
    [account1.smtpSession setPassword:@"; DROP TABLE PASSWORDS2"];
    [AccountCreationManager makeAccountPermanent:account1];
    
    XCTAssertNotNil(account1);

    XCTestExpectation* messageSentExpectation = [self expectationWithDescription:@"Message sent"];
    
    MynigmaMessage* newMessage = [MynigmaMessage findOrMakeMessageWithMessageID:@"someMessageID4365734685"];
    
    [newMessage encryptForSendingWithCallback:^(MynigmaFeedback *feedback){
       
        [ThreadHelper runSyncOnMain:^{
       
            XCTAssertTrue(feedback.isSuccess);
        
        EmailMessageInstance* newInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newMessage inFolder:account1.accountSetting.outboxFolder inContext:MAIN_CONTEXT];
        
        [SendingManager sendOutboxMessageInstance:newInstance fromAccount:account1 withCallback:^(NSInteger result, NSError *error) {
           
            
            [messageSentExpectation fulfill];
        }];
         
        }];
    }];
        
    [self waitForExpectationsWithTimeout:1200 handler:nil];
}


//- (void)testKR
//{
////CSSM_ListModules
//    uint32 number = 1;
//
//    CSSM_ListAttachedModuleManagers(&number, 0);
//
//    CSSM_RETURN CSSMAPI returnValue = CSSM_KR_QueryPolicyInfo(0, 0, 0, 0, 0);
//
//    XCTAssertEqual(number, 0);
//
////    const CSSM_MEMORY_FUNCS_PTR result = NULL;
////    void* returnValue = CSSM_GetInfo(result, &number);
//
//
////    CSSM_KR_QueryPolicyInfo(
//}

@end
