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
#import "MynigmaPrivateKey+Category.h"
#import "TestHarness.h"
#import <OCMock/OCMock.h>
#import "AppleEncryptionWrapper.h"
#import "TestHelper.h"
#import "NSString+EmailAddresses.h"
#import "EmailAddress+Category.h"
#import "AppDelegate.h"


@interface EmailAddress()

+ (EmailAddress*)emailAddressForEmail:(NSString*)emailString inContext:(NSManagedObjectContext*)keyContext makeIfNecessary:(BOOL)shouldCreate;

- (void)associateKeyWithEmail:(NSString*)emailString forceMakeCurrent:(BOOL)makeCurrent inContext:(NSManagedObjectContext*)keyContext;

@end


@interface MynigmaPublicKey()

+ (MynigmaPublicKey*)syncMakeNewPublicKeyWithEncKeyData:(NSData*)encKeyData andVerKeyData:(NSData*)verKeyData forEmail:(NSString*)email keyLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

@end

@interface MynigmaPrivateKey()

+ (MynigmaPrivateKey*)privateKeyWithLabel:(NSString*)keyLabel inContext:(NSManagedObjectContext*)keyContext;

@end



@interface MynigmaPrivateKey_Tests : TestHarness

@end

@implementation MynigmaPrivateKey_Tests

- (void)testThatGenerationOfANewPrivateKeyForcesAssociationWithEmailAddress
{
    NSString* testEmail = @"someTestEmail3472935@mynigma.org";

    NSString* mockedKeyLabel = @"someKeyLabel34732492";

    NSArray* mockedPrivateKeyData = [TestHelper privateKeySampleData:@1];


    //pretend the private key doesn't currently exist, even if it happens to be in the store...
    id privateKeyClassMock = OCMClassMock([MynigmaPrivateKey class]);
    OCMStub([privateKeyClassMock havePrivateKeyWithLabel:mockedKeyLabel]).andReturn(NO);


    //mock the key generation
    id appleEncryptionWrapperMock = OCMClassMock([AppleEncryptionWrapper class]);

    OCMExpect([appleEncryptionWrapperMock generateNewPrivateKeyPairForEmailAddress:[testEmail canonicalForm] withCallback:[OCMArg any]]).andDo(^(NSInvocation* invocation){

        //the callback is parameter number 2, so argument index number 3, according to the NSInvocation reckoning
        __unsafe_unretained void (^callback)(NSString *keyLabel, NSData *encPersRef, NSData *verPersRef, NSData *decPersRef, NSData *sigPersRef) = nil;
        [invocation getArgument:&callback atIndex:3];

        //pretend the user clicked OK
        if(callback)
            callback(mockedKeyLabel, mockedPrivateKeyData[2], mockedPrivateKeyData[3], mockedPrivateKeyData[0], mockedPrivateKeyData[1]);
    });

    XCTestExpectation* finishedCreatingKey = [self expectationWithDescription:@"did finish creating key"];


    //make sure a current key is set
    EmailAddress* emailAddress = [EmailAddress emailAddressForEmail:[testEmail canonicalForm] inContext:MAIN_CONTEXT makeIfNecessary:YES];

    //make new public key
    [ThreadHelper runSyncOnKeyContext:^(NSManagedObjectContext *keyContext){

        NSArray* newPublicKeyData = [TestHelper publicKeySampleData:@2];
    MynigmaPublicKey* publicCurrentKey = [MynigmaPublicKey syncMakeNewPublicKeyWithEncKeyData:newPublicKeyData.firstObject andVerKeyData:newPublicKeyData.lastObject forEmail:testEmail keyLabel:@"someOtherKeyLabel342539@mynigma.org" inContext:keyContext];
    [publicCurrentKey associateKeyWithEmail:testEmail forceMakeCurrent:YES inContext:keyContext];
    }];

    XCTAssertEqualObjects(emailAddress.currentKey.keyLabel, @"someOtherKeyLabel342539@mynigma.org");

    [MynigmaPrivateKey asyncCreateNewMynigmaPrivateKeyForEmail:testEmail withCallback:^{

        NSString* actualKeyLabel = [MynigmaPrivateKey privateKeyLabelForEmailAddress:testEmail];
        XCTAssertEqualObjects(actualKeyLabel, mockedKeyLabel);

        [privateKeyClassMock stopMocking];

        XCTAssert([MynigmaPrivateKey havePrivateKeyWithLabel:mockedKeyLabel]);

        [finishedCreatingKey fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];

    OCMVerifyAll(appleEncryptionWrapperMock);
}


- (void)testRemovalOfPrivateKeyBeforeIndexCompilation
{
    
}


@end
