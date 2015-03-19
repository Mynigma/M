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

#import "TestHarness.h"
#import <XCTest/XCTest.h>
#import "AppDelegate.h"
#import "PGPPublicKey+Category.h"




@interface PGPPublicKey_Tests : TestHarness

@end

@implementation PGPPublicKey_Tests



#pragma mark - Public key import

- (void)testImportPublicKey1
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey1" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey2
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey2" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey3
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey3" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey4
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey4" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}
- (void)testImportPublicKey5
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey5" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey6
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey6" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey7
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey7" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey8
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey8" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey9
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey9" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey10
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey10" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey11
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey11" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey12
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey12" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey13
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey13" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey14
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey14" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey15
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey15" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey16
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey16" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPublicKey17
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPublicKey17" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}





#pragma mark - Public key import

- (void)testImportPrivateKey1
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey1" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPrivateKey2
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey2" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPrivateKey3
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey3" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPrivateKey4
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey4" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPrivateKey5
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey5" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportPrivateKey6
{
    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey6" withExtension:@""];

    XCTAssertNotNil(url);

    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

//- (void)testImportPrivateKey7
//{
//    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey7" withExtension:@""];
//
//    XCTAssertNotNil(url);
//
//    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];
//
//    XCTAssertTrue(result);
//}
//
//- (void)testImportPrivateKey8
//{
//    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey8" withExtension:@""];
//
//    XCTAssertNotNil(url);
//
//    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];
//
//    XCTAssertTrue(result);
//}
//
//- (void)testImportPrivateKey9
//{
//    NSURL* url = [BUNDLE URLForResource:@"PGPPrivateKey9" withExtension:@""];
//
//    XCTAssertNotNil(url);
//
//    BOOL result = [PGPPublicKey importKeyFromFileWithURL:url];
//
//    XCTAssertTrue(result);
//}

@end
