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





#import "SetupSeparateControllerTests.h"
#import "KeychainHelper.h"
#import <OCMock/OCMock.h>
#import "Setup_SeparateController.h"
#import "ConnectionItem.h"
#import <MailCore/MailCore.h>
#import "AccountCreationManager.h"
#import "AlertHelper.h"
#import "MCOIMAPSession+Category.h"



//simulate different locales
@interface Language : NSObject

@end

@implementation Language : NSObject

static NSBundle *bundle = nil;

+ (void)initialize
{
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    NSArray* languages = [defs objectForKey:@"AppleLanguages"];
    NSString *current = [languages objectAtIndex:0];
    [self setLanguage:current];

}

+ (void)setLanguage:(NSString*)l
{
    NSString *path = [[NSBundle mainBundle] pathForResource:l ofType:@"lproj"];
    bundle = [NSBundle bundleWithPath:path];
}

+ (NSString*)get:(NSString*)key alternate:(NSString*)alternate
{
    return [bundle localizedStringForKey:key value:alternate table:nil];
}

@end



@implementation SetupSeparateControllerTests

- (void)testThatAllOutletsAreConnected
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    //ensure all outlets are connected
    XCTAssertNotNil(setupController.senderNameField);
    XCTAssertNotNil(setupController.emailAddressField);
    XCTAssertNotNil(setupController.passwordField);

    //incoming
    XCTAssertNotNil(setupController.incomingServerField);
    XCTAssertNotNil(setupController.incomingUserNameField);
    XCTAssertNotNil(setupController.incomingPasswordField);
    XCTAssertNotNil(setupController.incomingAuthCheckButton);
    XCTAssertNotNil(setupController.incomingEncryptionField);
    XCTAssertNotNil(setupController.incomingPortField);
    XCTAssertNotNil(setupController.incomingDefaultPortCheckBox);

    //outgoing
    XCTAssertNotNil(setupController.outgoingServerField);
    XCTAssertNotNil(setupController.outgoingUserNameField);
    XCTAssertNotNil(setupController.outgoingPasswordField);
    XCTAssertNotNil(setupController.outgoingAuthCheckButton);
    XCTAssertNotNil(setupController.outgoingEncryptionField);
    XCTAssertNotNil(setupController.outgoingPortField);
    XCTAssertNotNil(setupController.outgoingDefaultPortCheckBox);

    //hide/reveal section checkboxes
    XCTAssertNotNil(setupController.serverNamesCheckBox);
    XCTAssertNotNil(setupController.credentialsCheckBox);
    XCTAssertNotNil(setupController.securityBox);

    //more settings button
    XCTAssertNotNil(setupController.moreSettingsButton);

    //ensure the viewsThatCanBeDisabledConnection has all items set
    //don't check each individual view, just count the total
    XCTAssertEqual(setupController.viewsThatCanBeDisabled.count, 37, @"Views that will be disabled while a connection attempt is being made incorrectly assigned");
}

- (void)testThatMoreButtonIsLocalizedInGerman
{
    //need a partial mock of the main bundle to set
    NSBundle* mainBundle = [NSBundle mainBundle];
    id mainBundleMock = OCMPartialMock(mainBundle);
    id bundleClassMock = OCMClassMock([NSBundle class]);

    //return the mocked bundle when [NSBundle mainBundle] is called
    OCMExpect([bundleClassMock mainBundle]).andReturn(mainBundleMock);

    //set the language to German
    [Language setLanguage:@"de"];

    //NSLocalizedString will call this method. Return the string in the locale to be tested instead
    OCMExpect([mainBundleMock localizedStringForKey:@"more" value:@"" table:nil]).andReturn([Language get:@"more" alternate:@""]);

    //load the storyboard
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    XCTAssertNotNil(setupController.moreSettingsButton);

    //titleForState won't be set, but attributedTitle will be...
    NSString* title = [setupController.moreSettingsButton attributedTitleForState:UIControlStateNormal].string;

    XCTAssertEqualObjects(@"mehr", title, @"More button localized in German");
}

- (void)testThatMoreButtonIsLocalizedInFrench
{
    //need a partial mock of the main bundle to set
    NSBundle* mainBundle = [NSBundle mainBundle];
    id mainBundleMock = OCMPartialMock(mainBundle);
    id bundleClassMock = OCMClassMock([NSBundle class]);

    //return the mocked bundle when [NSBundle mainBundle] is called
    OCMExpect([bundleClassMock mainBundle]).andReturn(mainBundleMock);

    //set the language to French
    [Language setLanguage:@"fr"];

    //NSLocalizedString will call this method. Return the string in the locale to be tested instead
    OCMExpect([mainBundleMock localizedStringForKey:@"more" value:@"" table:nil]).andReturn([Language get:@"more" alternate:@""]);

    //load the storyboard
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    XCTAssertNotNil(setupController.moreSettingsButton);

    //titleForState won't be set, but attributedTitle will be...
    NSString* title = [setupController.moreSettingsButton attributedTitleForState:UIControlStateNormal].string;

    XCTAssertEqualObjects(@"plus", title, @"More button localized in French");
}


- (void)d_testThatNextRespondersAreSetupCorrectly
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    [setupController textFieldShouldReturn:setupController.senderNameField];

    //doesn't work: becomeFirstResponder doesn't set the first responder immediately
    XCTAssertTrue(setupController.emailAddressField.isFirstResponder);

    [setupController textFieldShouldReturn:setupController.emailAddressField];
    XCTAssertTrue(setupController.passwordField.isFirstResponder);

    [setupController textFieldShouldReturn:setupController.incomingServerField];
    XCTAssertTrue(setupController.outgoingServerField.isFirstResponder);

    [setupController textFieldShouldReturn:setupController.incomingUserNameField];
    XCTAssertTrue(setupController.outgoingUserNameField.isFirstResponder);

    [setupController textFieldShouldReturn:setupController.incomingPasswordField];
    XCTAssertTrue(setupController.outgoingPasswordField.isFirstResponder);

    [setupController textFieldShouldReturn:setupController.incomingPortField];
    XCTAssertTrue(setupController.outgoingPortField.isFirstResponder);
}



- (void)testManualSetupOfGmail
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    OCMockObject* setupControllerMock = OCMPartialMock(setupController);

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;


    //expected item
    NSString* emailAddress = @"unitTestEmailAddress@gmail.com";

    ConnectionItem* expectedConnectionItem = [ConnectionItem new];
    [expectedConnectionItem setEmailAddress:emailAddress];

    [expectedConnectionItem setIncomingHost:@"imap.gmail.com"];
    [expectedConnectionItem setIncomingUsername:emailAddress];
    [expectedConnectionItem setIncomingAuth:@(MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin)];
    [expectedConnectionItem setIncomingConnectionType:@(MCOConnectionTypeTLS)];
    [expectedConnectionItem setIncomingPort:@993];
    [expectedConnectionItem setIncomingPassword:@""];

    [expectedConnectionItem setOutgoingHost:@"smtp.gmail.com"];
    [expectedConnectionItem setOutgoingUsername:emailAddress];
    [expectedConnectionItem setOutgoingAuth:@(MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin)];
    [expectedConnectionItem setOutgoingConnectionType:@(MCOConnectionTypeStartTLS)];
    [expectedConnectionItem setOutgoingPort:@587];
    [expectedConnectionItem setOutgoingPassword:@""];


    XCTestExpectation* UIUpdateCalled = [self expectationWithDescription:@"failed to call UI update"];

    //expect a call to update the UI with the correct settings
    OCMExpect([(Setup_SeparateController*)setupControllerMock updateFieldValuesWithConnectionItem:expectedConnectionItem]).andDo(^(NSInvocation* invocation)
                                                                                                                       {
                                                                                                                           XCTAssertEqualObjects([(Setup_SeparateController*)setupControllerMock connectionItem], expectedConnectionItem);

                                                                                                                           [UIUpdateCalled  fulfill];
                                                                                                                       });

    [(Setup_SeparateController*)setupControllerMock textFieldDidEndEditing:setupController.senderNameField];

    [[(Setup_SeparateController*)setupControllerMock emailAddressField] setText:emailAddress];

    if([setupController textFieldShouldEndEditing:setupController.emailAddressField])
        [(Setup_SeparateController*)setupControllerMock textFieldDidEndEditing:setupController.emailAddressField];

    [self waitForExpectationsWithTimeout:2 handler:nil];

    OCMVerifyAll(setupControllerMock);
}

- (void)testButtonsAndFieldsAreDisabledWhileConnectionAttemptIsBeingMade
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    [setupController setIsWorking:YES];

    XCTAssertFalse([setupController.credentialsCheckBox isEnabled]);
    XCTAssertFalse([setupController.serverNamesCheckBox isEnabled]);
    XCTAssertFalse([setupController.securityCheckBox isEnabled]);

    XCTAssertFalse([setupController.moreSettingsButton isEnabled]);

    XCTAssertFalse([setupController.senderNameField isEnabled]);
    XCTAssertFalse([setupController.emailAddressField isEnabled]);
    XCTAssertFalse([setupController.passwordField isEnabled]);

    XCTAssertFalse([setupController.incomingAuthCheckButton isEnabled]);
    XCTAssertFalse([setupController.incomingDefaultPortCheckBox isEnabled]);
    XCTAssertFalse([setupController.incomingEncryptionField isEnabled]);
    XCTAssertFalse([setupController.incomingPasswordField isEnabled]);
    XCTAssertFalse([setupController.incomingServerField isEnabled]);
    XCTAssertFalse([setupController.incomingUserNameField isEnabled]);

    XCTAssertFalse([setupController.outgoingAuthCheckButton isEnabled]);
    XCTAssertFalse([setupController.outgoingDefaultPortCheckBox isEnabled]);
    XCTAssertFalse([setupController.outgoingEncryptionField isEnabled]);
    XCTAssertFalse([setupController.outgoingPasswordField isEnabled]);
    XCTAssertFalse([setupController.outgoingServerField isEnabled]);
    XCTAssertFalse([setupController.outgoingUserNameField isEnabled]);

    XCTAssertFalse([setupController.incomingPortField isEnabled]);
    XCTAssertFalse([setupController.outgoingPortField isEnabled]);

    [setupController setIsWorking:NO];

    XCTAssertTrue([setupController.credentialsCheckBox isEnabled]);
    XCTAssertTrue([setupController.serverNamesCheckBox isEnabled]);
    XCTAssertTrue([setupController.securityCheckBox isEnabled]);

    XCTAssertTrue([setupController.moreSettingsButton isEnabled]);

    XCTAssertTrue([setupController.senderNameField isEnabled]);
    XCTAssertTrue([setupController.emailAddressField isEnabled]);
    XCTAssertTrue([setupController.passwordField isEnabled]);

    XCTAssertTrue([setupController.incomingAuthCheckButton isEnabled]);
    XCTAssertTrue([setupController.incomingDefaultPortCheckBox isEnabled]);
    XCTAssertTrue([setupController.incomingEncryptionField isEnabled]);
    XCTAssertTrue([setupController.incomingPasswordField isEnabled]);
    XCTAssertTrue([setupController.incomingServerField isEnabled]);
    XCTAssertTrue([setupController.incomingUserNameField isEnabled]);

    XCTAssertTrue([setupController.outgoingAuthCheckButton isEnabled]);
    XCTAssertTrue([setupController.outgoingDefaultPortCheckBox isEnabled]);
    XCTAssertTrue([setupController.outgoingEncryptionField isEnabled]);
    XCTAssertTrue([setupController.outgoingPasswordField isEnabled]);
    XCTAssertTrue([setupController.outgoingServerField isEnabled]);
    XCTAssertTrue([setupController.outgoingUserNameField isEnabled]);

    XCTAssertTrue([setupController.incomingPortField isEnabled]);
    XCTAssertTrue([setupController.outgoingPortField isEnabled]);
}

- (void)testConnectionItemsUpdateFieldsAndViceVersa
{
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    //setup a connection item with random values
    ConnectionItem* newConnectionItem = [[ConnectionItem alloc] initWithEmail:@"someTestEmail@mynigma.org"];

    [newConnectionItem setFullName:@"SOme name"];
    [newConnectionItem setPassword:@"fdjwUE*@)))"];

    [newConnectionItem setIncomingHost:@"JDeife.dasd.com"];
    [newConnectionItem setIncomingUsername:@"djfiU@(EU(@U"];
    [newConnectionItem setIncomingPassword:@"djf*U@YEU(@siODIFJ"];
    [newConnectionItem setIncomingAuth:@(MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin)];
    [newConnectionItem setIncomingConnectionType:@2];
    [newConnectionItem setIncomingPort:@123];

    [newConnectionItem setOutgoingHost:@"JDefvife.dasd.com"];
    [newConnectionItem setOutgoingUsername:@"djfiUdfwe@(EU(@U"];
    [newConnectionItem setOutgoingPassword:@"djf*bwafwU@YEU(@siODIFJ"];
    [newConnectionItem setOutgoingAuth:@(MCOAuthTypeSASLLogin)];
    [newConnectionItem setOutgoingConnectionType:@1];
    [newConnectionItem setOutgoingPort:@127];

    //set the text fields etc. to reflect the values in the connection item
    [setupController updateFieldValuesWithConnectionItem:newConnectionItem];

    //create a fresh connection item
    ConnectionItem* otherConnectionItem = [ConnectionItem new];

    XCTAssertNotEqualObjects(newConnectionItem, otherConnectionItem);

    //fill the newly created item with the values extracted from the input fields
    [setupController updateConnectionItemWithFieldValues:otherConnectionItem];

    XCTAssertEqualObjects(newConnectionItem, otherConnectionItem);
}


- (void)testThatDuplicateAccountsCannotBeSetup
{
    //some email address
    NSString* email = @"unittestsmynigma@gmail.com";

    id accountManagerMock = OCMClassMock([AccountCreationManager class]);

    OCMExpect([accountManagerMock haveAccountForEmail:email]).andReturn(YES);

    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    ConnectionItem* newConnectionItem = [[ConnectionItem alloc] initWithEmail:email];

    [setupController updateFieldValuesWithConnectionItem:newConnectionItem];


    id alertHelperMock = OCMClassMock([AlertHelper class]);

    OCMExpect([alertHelperMock showAlertWithMessage:[OCMArg any] informativeText:[OCMArg any]]);

    [setupController loginButtonClicked:nil];

    OCMVerifyAll(accountManagerMock);

    OCMVerifyAll(alertHelperMock);
}

- (void)testThatGmailConnectsOnLoginClick
{
    //some (valid) email address
    NSString* email = @"unittestsmynigma@gmail.com";

    //mock the account creation manager to ensure that the account is not reported as existing
    id accountManagerMock = OCMClassMock([AccountCreationManager class]);
    OCMExpect([accountManagerMock haveAccountForEmail:email]).andReturn(NO);

    //create a partial mock of an MCOIMAPSession object to intercept the calls to checkAccountOperation
    MCOIMAPSession* newIMAPSession = [MCOIMAPSession freshSession];
    id imapSessionMock = OCMPartialMock(newIMAPSession);

    id imapSessionClassMock = OCMStrictClassMock([MCOIMAPSession class]);

    OCMExpect([imapSessionClassMock freshSession]).andReturn(imapSessionMock);

    //same for SMTP session
    MCOSMTPSession* newSMTPSession = [MCOSMTPSession new];
    id smtpSessionMock = OCMPartialMock(newSMTPSession);

    id smtpSessionClassMock = OCMStrictClassMock([MCOSMTPSession class]);

    OCMExpect([smtpSessionClassMock freshSession]).andReturn(smtpSessionMock);


    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Main_Universal" bundle:nil];

    Setup_SeparateController* setupController = (Setup_SeparateController*)[storyboard instantiateViewControllerWithIdentifier:@"setupSeparateController"];

    XCTAssertNotNil(setupController);

    //need to call the view for the outlet connections to be made
    (void)setupController.view;

    ConnectionItem* newConnectionItem = [ConnectionItem new];

    [newConnectionItem setFullName:@"SOme name"];
    [newConnectionItem setEmailAddress:email];
    [newConnectionItem setPassword:@"fdjwUE*@)))"];

    [newConnectionItem setIncomingHost:@"JDeife.dasd.com"];
    [newConnectionItem setIncomingUsername:@"djfiU@(EU(@U"];
    [newConnectionItem setIncomingPassword:@"djf*U@YEU(@siODIFJ"];
    [newConnectionItem setIncomingAuth:@(MCOAuthTypeSASLPlain | MCOAuthTypeSASLLogin)];
    [newConnectionItem setIncomingConnectionType:@2];
    [newConnectionItem setIncomingPort:@123];

    [newConnectionItem setOutgoingHost:@"JDefvife.dasd.com"];
    [newConnectionItem setOutgoingUsername:@"djfiUdfwe@(EU(@U"];
    [newConnectionItem setOutgoingPassword:@"djf*bwafwU@YEU(@siODIFJ"];
    [newConnectionItem setOutgoingAuth:@(MCOAuthTypeSASLLogin)];
    [newConnectionItem setOutgoingConnectionType:@1];
    [newConnectionItem setOutgoingPort:@127];

    [setupController updateFieldValuesWithConnectionItem:newConnectionItem];


    id checkIMAPAccountOperationMock = OCMPartialMock([newIMAPSession checkAccountOperation]);

    OCMExpect([imapSessionMock checkAccountOperation]).andDo(^(NSInvocation* invocation){
        __unsafe_unretained MCOIMAPSession* session = nil;

        [invocation getArgument:&session atIndex:0];

        if([session isKindOfClass:[MCOIMAPSession class]])
        {
            XCTAssertEqualObjects(session.hostname, newConnectionItem.incomingHost);
            XCTAssertEqualObjects(session.username, newConnectionItem.incomingUsername);
            XCTAssertEqualObjects(session.password, newConnectionItem.incomingPassword);
            XCTAssertEqual(session.port, newConnectionItem.incomingPort.integerValue);
            XCTAssertEqual(session.connectionType, newConnectionItem.incomingConnectionType.integerValue);
            XCTAssertEqual(session.authType, newConnectionItem.incomingAuth.integerValue);
        }
        else
            XCTFail(@"Session invalid: %@", session);
    }).andReturn(checkIMAPAccountOperationMock);

    OCMExpect([checkIMAPAccountOperationMock start:[OCMArg any]]);


    MCOAddress* address = [MCOAddress addressWithDisplayName:newConnectionItem.outgoingUsername mailbox:newConnectionItem.emailAddress];

    id checkSMTPAccountOperationMock = OCMPartialMock([newSMTPSession checkAccountOperationWithFrom:address]);

    OCMExpect([smtpSessionMock checkAccountOperationWithFrom:address]).andDo(^(NSInvocation* invocation){
        __unsafe_unretained MCOIMAPSession* session = nil;

        __unsafe_unretained MCOAddress* address = nil;
        [invocation getArgument:&session atIndex:0];

        [invocation getArgument:&address atIndex:2];

        if([session isKindOfClass:[MCOSMTPSession class]] && [address isKindOfClass:[MCOAddress class]])
        {                                                                                                                                                                                   XCTAssertEqualObjects(session.hostname, newConnectionItem.outgoingHost);
            XCTAssertEqualObjects(session.username, newConnectionItem.outgoingUsername);
            XCTAssertEqualObjects(session.password, newConnectionItem.outgoingPassword);
            XCTAssertEqual(session.port, newConnectionItem.outgoingPort.integerValue);
            XCTAssertEqual(session.connectionType, newConnectionItem.outgoingConnectionType.integerValue);
            XCTAssertEqual(session.authType, newConnectionItem.outgoingAuth.integerValue);
        }
        else
            XCTFail(@"Session invalid: %@", session);
    }).andReturn(checkSMTPAccountOperationMock);

    OCMExpect([checkSMTPAccountOperationMock start:[OCMArg any]]);

    [setupController loginButtonClicked:nil];

    OCMVerifyAll(accountManagerMock);

    OCMVerifyAll(imapSessionClassMock);
    OCMVerifyAll(imapSessionMock);
    OCMVerifyAll(checkIMAPAccountOperationMock);

    OCMVerifyAll(smtpSessionClassMock);
    OCMVerifyAll(smtpSessionMock);
    OCMVerifyAll(checkSMTPAccountOperationMock);
}



@end
