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

@class MynigmaMessage, DeviceMessage, MynigmaDevice, MynigmaFeedback;

@interface DataWrapHelper : NSObject

+ (NSData*)wrapMessage:(MynigmaMessage*)message;

+ (void)unwrapMessageData:(NSData*)payloadPartData intoMessage:(MynigmaMessage*)newMessage withAttachmentHMACS:(NSArray*)attachmentHMACS andFeedback:(MynigmaFeedback**)mynigmaFeedback;

+ (NSData*)makeAccountDataPackage;
+ (NSData*)makeAccountDataPackageIncludingPublicKeys:(BOOL)includePublicKeys includingAccountSettings:(BOOL)includeAccountSettings;
+ (NSData*)makeIOSPackageIncludingAccountSettings:(BOOL)includeAccounts;

+ (void)unwrapAccountDataPackage:(NSData*)data passphrase:(NSString*)passphrase withCallback:(void(^)(NSArray* importedPrivateKeyLabels, NSArray* errorLabels))callback;
+ (void)unwrapAccountDataPackage:(NSData*)data withCallback:(void(^)(NSArray* importedPrivateKeyLabels, NSArray* errorLabels))callback;

+ (void)saveAsDialogue;
+ (void)openDialogue;

+ (NSData*)wrapSignedData:(NSData*)data signedDataBlob:(NSData*)signedDataBlob keyLabel:(NSString*)keyLabel withFeedback:(MynigmaFeedback**)mynigmaFeedback;
+ (NSData*)wrapSignedData:(NSData*)data signedDataBlob:(NSData*)signedDataBlob keyLabel:(NSString*)keyLabel version:(NSString*)version withFeedback:(MynigmaFeedback**)mynigmaFeedback;


+ (NSData*)wrapDeviceMessage:(DeviceMessage*)deviceMessage;
+ (BOOL)unwrapData:(NSData*)deviceMessageData intoDeviceMessage:(DeviceMessage*)deviceMessage;
//+ (DeviceMessage*)unwrapDeviceMessage:(NSData*)deviceMessageData;

+ (NSData*)wrapDeviceDiscoveryData:(MynigmaDevice*)mynigmaDevice;
+ (MynigmaDevice*)unwrapDeviceDiscoveryData:(NSData*)deviceDiscoveryData withDate:(NSDate*)dateFound inContext:(NSManagedObjectContext*)localContext;


+ (NSData*)makeCompleteSyncDataPackage;

+ (NSData*)makeSyncDataPackageWithPrivateKeys:(NSArray*)privateKeys andPublicKeys:(NSArray*)publicKeys andEmailContactDetails:(NSArray*)contactDetails passphrase:(NSString*)passphrase;
+ (void)unwrapSyncDataPackage:(NSData*)data withCallback:(void(^)(NSArray* importedPrivateKeyLabels, NSArray* importedPublicKeyLabels, NSArray* importedAccounts, NSArray* importedContactDetails, NSArray* errors))callback passphrase:(NSString*)passphrase inContext:(NSManagedObjectContext*)localContext;


@end
