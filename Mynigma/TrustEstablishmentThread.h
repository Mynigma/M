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







@class MynigmaDevice, IMAPAccountSetting, DeviceMessage;


@interface TrustEstablishmentThread : NSObject

@property NSData* publicVerKeyData;
@property NSData* publicEncKeyData;

@property NSString* publicKeyLabel;

@property NSData* partnerPublicVerKeyData;
@property NSData* partnerPublicEncKeyData;

@property NSString* partnerPublicKeyLabel;

@property NSData* partnerHashData;

@property NSData* partnerSecretData;

@property NSData* secretData;

@property NSString* thisDeviceUUID;

@property NSString* partnerDeviceUUID;

@property NSString* threadID;

@property NSSet* expectedMessageCommands;

@property NSManagedObjectID* accountSettingObjectID;

//typedef void(^threadCreationCallback)(NSString* threadID);
//
//@property KeyGenerationCallback threationCallback;



+ (void)addThread:(TrustEstablishmentThread*)newThread withID:(NSString*)threadID;

+ (TrustEstablishmentThread*)threadWithID:(NSString*)threadID;

@property(strong) void(^confirmationCallback)(BOOL confirmed);

- (void)processDeviceMessage:(DeviceMessage*)deviceMessage inAccount:(IMAPAccountSetting*)accountSetting;

- (BOOL)isAllowedMessageCommand:(NSString*)messageKind;


+ (void)startNewThreadWithTargetDeviceUUID:(NSString*)targetDeviceUUID withCallback:(void(^)(NSString* newThreadID))callback;

- (DeviceMessage*)constructNewStartThreadMessageWithSenderDevice:(MynigmaDevice*)senderDevice targetDevice:(MynigmaDevice*)targetDevice inContext:(NSManagedObjectContext*)localContext;

+ (TrustEstablishmentThread*)newThreadWithFoundDeviceMessage:(DeviceMessage*)deviceMessage inContext:(NSManagedObjectContext*)localContext
;


- (void)confirmMatch;

- (void)cancel;


@end
