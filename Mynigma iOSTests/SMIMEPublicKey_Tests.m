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
#import "SMIMEPublicKey+Category.h"
#import "AppDelegate.h"



@interface SMIMEPublicKey_Tests : TestHarness

@end

@implementation SMIMEPublicKey_Tests



#pragma mark - Test import of S/MIME certificates

- (void)testImportOfAliceDSSSignByCarlNoInherit
{
    NSURL* url = [BUNDLE URLForResource:@"AliceDSSSignByCarlNoInherit" withExtension:@"cer"];
    
    XCTAssertNotNil(url);
    
    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];
    
    XCTAssertTrue(result);
}

- (void)testImportOfAliceRSASignByCarl
{
    NSURL* url = [BUNDLE URLForResource:@"AliceRSASignByCarl" withExtension:@"cer"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfBobRSASignByCarl
{
    NSURL* url = [BUNDLE URLForResource:@"BobRSASignByCarl" withExtension:@"cer"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfCarlDSSSelf
{
    NSURL* url = [BUNDLE URLForResource:@"CarlDSSSelf" withExtension:@"cer"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfCarlRSASelf
{
    NSURL* url = [BUNDLE URLForResource:@"CarlRSASelf" withExtension:@"cer"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfDianeDSSSignByCarlInherit
{
    NSURL* url = [BUNDLE URLForResource:@"DianeDSSSignByCarlInherit" withExtension:@"cer"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfDianeRSASignByCarl
{
    NSURL* url = [BUNDLE URLForResource:@"DianeRSASignByCarl" withExtension:@"cer"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}




#pragma mark - Test import of S/MIME private keys

- (void)testImportOfAlicePrivDSSSign
{
    NSURL* url = [BUNDLE URLForResource:@"AlicePrivDSSSign" withExtension:@"pri"];
    
    XCTAssertNotNil(url);
    
    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];
    
    XCTAssertTrue(result);
}

- (void)testImportOfAlicePrivRSASign
{
    NSURL* url = [BUNDLE URLForResource:@"AlicePrivRSASign" withExtension:@"pri"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfBobPrivRSAEncrypt
{
    NSURL* url = [BUNDLE URLForResource:@"BobPrivRSAEncrypt" withExtension:@"pri"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfCarlPrivDSSSign
{
    NSURL* url = [BUNDLE URLForResource:@"CarlPrivDSSSign" withExtension:@"pri"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfCarlPrivRSASign
{
    NSURL* url = [BUNDLE URLForResource:@"CarlPrivRSASign" withExtension:@"pri"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfDianePrivDSSSign
{
    NSURL* url = [BUNDLE URLForResource:@"DianePrivDSSSign" withExtension:@"pri"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}

- (void)testImportOfDianePrivRSASignEncrypt
{
    NSURL* url = [BUNDLE URLForResource:@"DianePrivRSASignEncrypt" withExtension:@"pri"];

    XCTAssertNotNil(url);

    BOOL result = [SMIMEPublicKey importKeyFromFileWithURL:url];

    XCTAssertTrue(result);
}


@end
