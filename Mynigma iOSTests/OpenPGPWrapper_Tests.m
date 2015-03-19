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
#import "OpenPGPWrapper.h"
#import "netpgp.h"
#import "TestHarness.h"
#import "EmailRecipient.h"




@interface OpenPGPWrapper()

+ (netpgp_t*)netPGP;
+ (NSData*)encryptData:(NSData*)inData options:(OpenPGPEncryptionOption)options forEmailRecipients:(NSArray*)emailRecipients;

@end


@interface OpenPGPWrapper_Tests : TestHarness

@end

@implementation OpenPGPWrapper_Tests

- (void)testBuildNetPGP
{
    netpgp_t* netPGP = [OpenPGPWrapper netPGP];
    XCTAssert(netPGP);
}

- (void)testBasicEncryption
{
    NSData* someData = [TestHelper sampleData:@1];

    EmailRecipient* sender = [EmailRecipient new];

    [sender setEmail:@"testEmailAddress@mynigma.org"];
    [sender setName:@"someTestName"];

    NSData* encryptedData = [OpenPGPWrapper encryptData:someData options:0 forEmailRecipients:@[sender]];

    XCTAssertNotNil(encryptedData);
}



@end
