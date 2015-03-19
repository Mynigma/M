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
#import "DeviceMessage+Category.h"
#import "TrustEstablishmentThread.h"
#import <OCMock/OCMock.h>
#import "MynigmaPublicKey+Category.h"
#import "AppDelegate.h"
#import "MynigmaDevice+Category.h"
#import "DataWrapHelper.h"
#import "DeviceConnectionHelper.h"
#import "TestHelper.h"
#import "EmailMessage+Category.h"
#import "KeychainHelper.h"
#import "TestHarness.h"
#import "AnnounceInfoDeviceMessage.h"
#import "ConfirmConnectionMessage.h"
#import "AlertHelper.h"
#import "AppleEncryptionWrapper.h"



#define KEY_LABEL @"someTestKeyLabel"
#define SENDER_UUID @"someTestCurrentDevice6372694231"

@interface TrustEstablishmentThread_Tests : TestHarness

@end

@implementation TrustEstablishmentThread_Tests

+ (void)setUp
{
    //pretend the current device has this UUID
    id keychainHelperMock = OCMClassMock([KeychainHelper class]);
    OCMExpect([keychainHelperMock fetchUUIDFromKeychain]).andReturn(SENDER_UUID);


    //make the current device
    [MynigmaDevice currentDevice];

    //create a matching sync key
    [TestHelper makeSampleDevicePublicKeyWithLabel:KEY_LABEL forDeviceUUID:SENDER_UUID];
}




//constructs an ANNOUNCE_INFO message and test that all infos are wrapped and parsed correctly
//almost exactly the same as the subsequent test
- (void)testThreadStartingMessageIsWrappedAndUnwrappedCorrectly
{
//    MynigmaDevice* targetDevice = [MynigmaDevice deviceWithUUID:@"7238273812323" addIfNotFound:YES];


    //create a "start new thread message"
    DeviceMessage* oldDeviceMessage = nil;
    
    //TO DO: adapt to new factoring
    //need the thread at this stage(?)
    
    //[TrustEstablishmentThread constructNewStartThreadMessageWithSenderDevice:[MynigmaDevice currentDevice] targetDevice:targetDevice inContext:MAIN_CONTEXT];


    //this must be non-nil
    XCTAssertNotNil(oldDeviceMessage);


    //wrap the device message data
    //we will then unwrap it and pretend we have just received the message
    NSData* wrappedDeviceData = [DataWrapHelper wrapDeviceMessage:oldDeviceMessage];

    DeviceMessage* newDeviceMessage = [DeviceMessage constructNewDeviceMessageInContext:MAIN_CONTEXT];

    NSDictionary* headerInfo = [oldDeviceMessage headerInfo];

    [newDeviceMessage parseHeaderInfos:headerInfo inContext:MAIN_CONTEXT];

    [DataWrapHelper unwrapData:wrappedDeviceData intoDeviceMessage:newDeviceMessage];

    //the properties of the original device message and the unwrapped one should match
    XCTAssertEqualObjects(newDeviceMessage.burnAfterReading, oldDeviceMessage.burnAfterReading);

    XCTAssertEqual([newDeviceMessage.dateSent timeIntervalSince1970], (NSInteger)[oldDeviceMessage.dateSent timeIntervalSince1970]);
    XCTAssertEqual([newDeviceMessage.expiryDate timeIntervalSince1970], (NSInteger)[oldDeviceMessage.expiryDate timeIntervalSince1970]);
    XCTAssertEqual(newDeviceMessage.hasExpired, oldDeviceMessage.hasExpired);
    XCTAssertEqualObjects(newDeviceMessage.messageCommand, oldDeviceMessage.messageCommand);
    XCTAssertEqualObjects(newDeviceMessage.payload, oldDeviceMessage.payload);
    XCTAssertEqualObjects(newDeviceMessage.sender, oldDeviceMessage.sender);
    XCTAssertEqualObjects(newDeviceMessage.targets, oldDeviceMessage.targets);
    XCTAssertEqualObjects(newDeviceMessage.threadID, oldDeviceMessage.threadID);
}


//constructs an ANNOUNCE_INFO message and test that all infos are wrapped and parsed correctly
- (void)testThatAnnounceInfoMessageIsWrappedAndUnwrappedCorrectly
{
    MynigmaDevice* targetDevice = [MynigmaDevice deviceWithUUID:@"7238273812323" addIfNotFound:YES];


    //create a new device message
    DeviceMessage* oldDeviceMessage = [AnnounceInfoDeviceMessage announceInfoMessageWithPublicKeyEncData:[TestHelper sampleData:@1] verData:[TestHelper sampleData:@2] keyLabel:@"someKeyLabel3429752425" hashData:[TestHelper sampleData:@3] threadID:@"someTestThreadID@mynigma.org" senderDevice:[MynigmaDevice currentDevice] targetDevice:targetDevice onLocalContext:MAIN_CONTEXT isResponse:NO];


    //this must be non-nil
    XCTAssertNotNil(oldDeviceMessage);


    //wrap the device message data
    //we will then unwrap it and pretend we have just received the message
    NSData* wrappedDeviceData = [DataWrapHelper wrapDeviceMessage:oldDeviceMessage];

    DeviceMessage* newDeviceMessage = [DeviceMessage constructNewDeviceMessageInContext:MAIN_CONTEXT];

    NSDictionary* headerInfo = [oldDeviceMessage headerInfo];

    [newDeviceMessage parseHeaderInfos:headerInfo inContext:MAIN_CONTEXT];

    [DataWrapHelper unwrapData:wrappedDeviceData intoDeviceMessage:newDeviceMessage];

    //the properties of the original device message and the unwrapped one should match
    XCTAssertEqualObjects(newDeviceMessage.burnAfterReading, oldDeviceMessage.burnAfterReading);
    XCTAssertEqual([newDeviceMessage.dateSent timeIntervalSince1970], (NSInteger)[oldDeviceMessage.dateSent timeIntervalSince1970]);
    XCTAssertEqual([newDeviceMessage.expiryDate timeIntervalSince1970], (NSInteger)[oldDeviceMessage.expiryDate timeIntervalSince1970]);
    XCTAssertEqual(newDeviceMessage.hasExpired, oldDeviceMessage.hasExpired);
    XCTAssertEqualObjects(newDeviceMessage.payload, oldDeviceMessage.payload);
    XCTAssertEqualObjects(newDeviceMessage.targets, oldDeviceMessage.targets);
    XCTAssertEqualObjects(newDeviceMessage.threadID, oldDeviceMessage.threadID);
}


//device messages must be enabled for the synchronisation to work
- (void)testThatDeviceMessagesAreEnabled
{
    XCTAssertTrue(PROCESS_DEVICE_MESSAGES);
    XCTAssertTrue(POST_DEVICE_MESSAGES);
}


- (void)testThatNoNewThreadCanBeStartedIfOneIsRunning
{
    
//    [TrustEstablishmentThread ]
}

- (void)testThatReceiptOfAnnounceInfoMessageResultsInSendingOfAcknowledgement
{
    MynigmaDevice* senderDevice = [MynigmaDevice deviceWithUUID:@"7238273812323" addIfNotFound:YES];


    //create a new device message
    NSArray* expectedKeyData = [TestHelper publicKeySampleData:@1];
    
//    MynigmaPublicKey* publicKey 
//    
//    dataForExistingMynigmaPublicKeyWithLabel

    DeviceMessage* oldDeviceMessage = [AnnounceInfoDeviceMessage announceInfoMessageWithPublicKeyEncData:expectedKeyData.firstObject verData:expectedKeyData.lastObject keyLabel:@"someSyncKeyLabel38499" hashData:[TestHelper sampleData:@3] threadID:@"someTestThreadID@mynigma.org" senderDevice:senderDevice targetDevice:[MynigmaDevice currentDevice] onLocalContext:MAIN_CONTEXT isResponse:NO];

//    no need to create this thread - that will be done when the message is found

    //this must be non-nil
    XCTAssertNotNil(oldDeviceMessage);


    XCTestExpectation* expectPostingOfDeviceMessageResponse = [self expectationWithDescription:@"Posting of device message response"];

    //the user will be asked to confirm
    id alertHelperMock = OCMClassMock([AlertHelper class]);
    OCMExpect([alertHelperMock showTwoOptionDialogueWithTitle:[OCMArg any] message:[OCMArg any] OKOption:[OCMArg any] cancelOption:[OCMArg any] suppressionIdentifier:[OCMArg any] callback:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        __unsafe_unretained void (^callback)(BOOL success) = nil;
        [invocation getArgument:&callback atIndex:7];

        if(callback)
            callback(YES);
    });

    //a mock for the device message
    id deviceConnectionHelperMock = OCMClassMock([DeviceConnectionHelper class]);

    id announceInfoClassMock = OCMClassMock([AnnounceInfoDeviceMessage class]);

    OCMExpect([deviceConnectionHelperMock postDeviceMessage:[OCMArg any] intoAccountSetting:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        [expectPostingOfDeviceMessageResponse fulfill];
    });


    OCMExpect([announceInfoClassMock announceInfoMessageWithPublicKeyEncData:expectedKeyData.firstObject verData:expectedKeyData.lastObject keyLabel:[MynigmaDevice currentDevice].syncKey.keyLabel hashData:[OCMArg any] threadID:oldDeviceMessage.threadID senderDevice:[OCMArg any] targetDevice:[OCMArg any] onLocalContext:[OCMArg any] isResponse:YES]).andForwardToRealObject;



    XCTestExpectation* showProgressExpectation = [self expectationWithDescription:@"Show device message progress"];

    OCMExpect([alertHelperMock showTrustEstablishmentProgress:2]).andDo(^(NSInvocation* invocation){

        [showProgressExpectation fulfill];
    });
    
    [oldDeviceMessage processMessageWithAccountSetting:nil];

    XCTAssertNotNil(oldDeviceMessage.threadID);


    [self waitForExpectationsWithTimeout:2000 handler:nil];

    TrustEstablishmentThread* thread = [TrustEstablishmentThread threadWithID:oldDeviceMessage.threadID];

    XCTAssertNotNil(thread);

    XCTAssertEqualObjects(thread.expectedMessageCommands, [NSSet setWithObject:@"1_CONFIRM_CONNECTION"]);

    OCMVerifyAll(deviceConnectionHelperMock);
    OCMVerifyAll(announceInfoClassMock);
    OCMVerifyAll(alertHelperMock);
}


- (void)testThatReceiptOfAcknowledgedAnnounceInfoMessageResultsInSendingConfirmConnectionMessage
{
    MynigmaDevice* senderDevice = [MynigmaDevice deviceWithUUID:@"7238273812323" addIfNotFound:YES];


    NSString* threadID = @"someThreadID342873587";

    //create a new device message
    DeviceMessage* oldDeviceMessage = [AnnounceInfoDeviceMessage announceInfoMessageWithPublicKeyEncData:[TestHelper sampleData:@1] verData:[TestHelper sampleData:@2] keyLabel:@"someSyncKeyLabel38492849" hashData:[TestHelper sampleData:@3] threadID:threadID senderDevice:senderDevice targetDevice:[MynigmaDevice currentDevice] onLocalContext:MAIN_CONTEXT isResponse:YES];


    //need to create this thread so it can be found
    TrustEstablishmentThread* newThread = [TrustEstablishmentThread new];
    [TrustEstablishmentThread addThread:newThread withID:threadID];
    [newThread setThreadID:threadID];
    [newThread setExpectedMessageCommands:[NSSet setWithObject:@"1_ACK_ANNOUNCE_INFO"]];

    //the partner device of the thread should be the device that sent the message
    [newThread setPartnerDeviceUUID:senderDevice.deviceId];

    //need some secret data - should be 64 bytes, but we'll use this for now
    NSData* secretData = [TestHelper sampleData:@1];
    [newThread setSecretData:secretData];

    //this must be non-nil
    XCTAssertNotNil(oldDeviceMessage);


    XCTestExpectation* expectPostingOfDeviceMessageResponse = [self expectationWithDescription:@"Posting of device message response"];

    //a mock for the device message
    id deviceConnectionHelperMock = OCMClassMock([DeviceConnectionHelper class]);

    OCMExpect([deviceConnectionHelperMock postDeviceMessage:[OCMArg any] intoAccountSetting:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        [expectPostingOfDeviceMessageResponse fulfill];
    });

    id confirmConnectionClassMock = OCMClassMock([ConfirmConnectionMessage class]);

    OCMExpect([confirmConnectionClassMock confirmConnectionMessageWithSecretKeyData:secretData inThread:threadID senderDevice:[OCMArg any] targetDevice:[OCMArg any] onLocalContext:[OCMArg any] isResponse:NO]).andForwardToRealObject;

    XCTestExpectation* showProgressExpectation = [self expectationWithDescription:@"Show device message progress"];

    id alertHelperMock = OCMClassMock([AlertHelper class]);
    OCMExpect([alertHelperMock showTrustEstablishmentProgress:3]).andDo(^(NSInvocation* invocation){

        [showProgressExpectation fulfill];
    });

    [oldDeviceMessage processMessageWithAccountSetting:nil];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];

    TrustEstablishmentThread* thread = [TrustEstablishmentThread threadWithID:oldDeviceMessage.threadID];

    XCTAssertNotNil(thread);

    XCTAssertEqualObjects(thread.expectedMessageCommands, [NSSet setWithObject:@"1_ACK_CONFIRM_CONNECTION"]);

    OCMVerifyAll(deviceConnectionHelperMock);
    OCMVerifyAll(confirmConnectionClassMock);
    OCMVerifyAll(alertHelperMock);
}

- (void)testThatReceiptOfConfirmConnectionMessageResultsInSendingAcknowledgementAndDisplayOfDigestChunks
{
    MynigmaDevice* senderDevice = [MynigmaDevice deviceWithUUID:@"72382738123235646" addIfNotFound:YES];

    //need some secret data
    NSData* secretData = [[TestHelper sampleData:@1] subdataWithRange:NSMakeRange(0, 64)];
    NSData* partnerSecretData = [[TestHelper sampleData:@2] subdataWithRange:NSMakeRange(0, 64)];

    NSString* threadID = @"someThreadID342873587546";

    //create a new device message
    DeviceMessage* oldDeviceMessage = [ConfirmConnectionMessage confirmConnectionMessageWithSecretKeyData:partnerSecretData inThread:threadID senderDevice:senderDevice targetDevice:[MynigmaDevice currentDevice] onLocalContext:MAIN_CONTEXT isResponse:NO];


    //need to create this thread so it can be found
    TrustEstablishmentThread* newThread = [TrustEstablishmentThread new];
    [TrustEstablishmentThread addThread:newThread withID:threadID];
    [newThread setThreadID:threadID];
    [newThread setExpectedMessageCommands:[NSSet setWithObject:@"1_CONFIRM_CONNECTION"]];

    //the partner device of the thread should be the device that sent the message
    [newThread setPartnerDeviceUUID:senderDevice.deviceId];


    //we need to supply some data
    NSArray* keyData1 = [TestHelper publicKeySampleData:@1];
    [newThread setPublicEncKeyData:keyData1.firstObject];
    [newThread setPublicVerKeyData:keyData1.lastObject];

    [newThread setPublicKeyLabel:@"someTestKeyLabel34823957324"];

    NSArray* keyData2 = [TestHelper publicKeySampleData:@2];
    [newThread setPartnerPublicEncKeyData:keyData2.firstObject];
    [newThread setPartnerPublicVerKeyData:keyData2.lastObject];

    [newThread setPartnerPublicKeyLabel:@"someTestKeyLabel4623742356"];

    [newThread setThisDeviceUUID:[MynigmaDevice currentDevice].deviceId];
    [newThread setSecretData:secretData];
    [newThread setPartnerSecretData:partnerSecretData];

    //hash the partner device data
    NSMutableData* dataToBeHashed = [NSMutableData dataWithData:partnerSecretData];

    [dataToBeHashed appendData:[newThread.partnerDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];

    NSData* computedHash = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];

    [newThread setPartnerHashData:computedHash];



    //this must be non-nil
    XCTAssertNotNil(oldDeviceMessage);


    XCTestExpectation* expectPostingOfDeviceMessageResponse = [self expectationWithDescription:@"Posting of device message response"];

    //a mock for the device message
    id deviceConnectionHelperMock = OCMClassMock([DeviceConnectionHelper class]);

    OCMExpect([deviceConnectionHelperMock postDeviceMessage:[OCMArg any] intoAccountSetting:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        [expectPostingOfDeviceMessageResponse fulfill];
    });

    
    id confirmConnectionClassMock = OCMClassMock([ConfirmConnectionMessage class]);

    OCMExpect([confirmConnectionClassMock confirmConnectionMessageWithSecretKeyData:[OCMArg any] inThread:[OCMArg any] senderDevice:[OCMArg any] targetDevice:[OCMArg any] onLocalContext:[OCMArg any] isResponse:YES]).andForwardToRealObject;


    XCTestExpectation* showProgressExpectation = [self expectationWithDescription:@"Show device message progress"];

    id alertHelperMock = OCMClassMock([AlertHelper class]);
    OCMExpect([alertHelperMock showTrustEstablishmentProgress:4]).andDo(^(NSInvocation* invocation){

        [showProgressExpectation fulfill];
    });


    XCTestExpectation* showDigestChunks = [self expectationWithDescription:@"Show digest chunks"];
    
    NSArray* expectedChunks = @[@"I9eG", @"mzE5", @"k7b2"];

    OCMExpect([alertHelperMock showDigestChunks:expectedChunks withTargetDevice:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        [showDigestChunks fulfill];
    });

    [oldDeviceMessage processMessageWithAccountSetting:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    TrustEstablishmentThread* thread = [TrustEstablishmentThread threadWithID:oldDeviceMessage.threadID];

    XCTAssertNotNil(thread);

    XCTAssertEqualObjects(thread.expectedMessageCommands, [NSSet set]);

    OCMVerifyAll(deviceConnectionHelperMock);
    OCMVerifyAll(confirmConnectionClassMock);
    OCMVerifyAll(alertHelperMock);
}



- (void)testThatReceiptOfAcknowledgeConfirmConnectionMessageResultsInDisplayOfDigestChunks
{
    MynigmaDevice* senderDevice = [MynigmaDevice deviceWithUUID:@"7238273812323" addIfNotFound:YES];
    MynigmaDevice* currentDevice = [MynigmaDevice currentDevice];

    //change around the UUIDs to ensure that the digest chunks match the previous test
    [senderDevice setDeviceId:currentDevice.deviceId];
    [currentDevice setDeviceId:@"7238273812323"];

    //need some secret data
    NSData* partnerSecretData = [[TestHelper sampleData:@1] subdataWithRange:NSMakeRange(0, 64)];
    NSData* secretData = [[TestHelper sampleData:@2] subdataWithRange:NSMakeRange(0, 64)];

    NSString* threadID = @"someThreadID342873587";

    //create a new device message
    DeviceMessage* oldDeviceMessage = [ConfirmConnectionMessage confirmConnectionMessageWithSecretKeyData:partnerSecretData inThread:threadID senderDevice:senderDevice targetDevice:[MynigmaDevice currentDevice] onLocalContext:MAIN_CONTEXT isResponse:YES];

    //this must be non-nil
    XCTAssertNotNil(oldDeviceMessage);

    //need to create this thread so it can be found
    TrustEstablishmentThread* newThread = [TrustEstablishmentThread new];
    [TrustEstablishmentThread addThread:newThread withID:threadID];
    [newThread setThreadID:threadID];
    [newThread setExpectedMessageCommands:[NSSet setWithObject:@"1_ACK_CONFIRM_CONNECTION"]];

    //the partner device of the thread should be the device that sent the message
    [newThread setPartnerDeviceUUID:senderDevice.deviceId];


    //we need to supply some data
    NSArray* keyData1 = [TestHelper publicKeySampleData:@2];
    [newThread setPublicEncKeyData:keyData1.firstObject];
    [newThread setPublicVerKeyData:keyData1.lastObject];

    [newThread setPublicKeyLabel:@"someTestKeyLabel4623742356"];


    NSArray* keyData2 = [TestHelper publicKeySampleData:@1];
    [newThread setPartnerPublicEncKeyData:keyData2.firstObject];
    [newThread setPartnerPublicVerKeyData:keyData2.lastObject];

    [newThread setPartnerPublicKeyLabel:@"someTestKeyLabel34823957324"];

    [newThread setThisDeviceUUID:[MynigmaDevice currentDevice].deviceId];
    [newThread setSecretData:secretData];
    [newThread setPartnerSecretData:partnerSecretData];

    //hash the partner device data
    NSMutableData* dataToBeHashed = [NSMutableData dataWithData:partnerSecretData];

    [dataToBeHashed appendData:[newThread.partnerDeviceUUID dataUsingEncoding:NSUTF8StringEncoding]];

    NSData* computedHash = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];

    [newThread setPartnerHashData:computedHash];



    XCTestExpectation* showProgressExpectation = [self expectationWithDescription:@"Show device message progress"];

    id alertHelperMock = OCMClassMock([AlertHelper class]);
    OCMExpect([alertHelperMock showTrustEstablishmentProgress:4]).andDo(^(NSInvocation* invocation){

        [showProgressExpectation fulfill];
    });


    XCTestExpectation* showDigestChunks = [self expectationWithDescription:@"Show digest chunks"];

    NSArray* expectedChunks = @[@"ArRC", @"kEYH", @"1l0d"];

    OCMExpect([alertHelperMock showDigestChunks:expectedChunks withTargetDevice:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        [showDigestChunks fulfill];
    });


    [oldDeviceMessage processMessageWithAccountSetting:nil];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    TrustEstablishmentThread* thread = [TrustEstablishmentThread threadWithID:oldDeviceMessage.threadID];

    XCTAssertNotNil(thread);

    XCTAssertEqualObjects(thread.expectedMessageCommands, [NSSet set]);
    
    OCMVerifyAll(alertHelperMock);
}





@end
