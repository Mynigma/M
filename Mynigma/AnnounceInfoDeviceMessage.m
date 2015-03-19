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





#import "AnnounceInfoDeviceMessage.h"
#import "DeviceMessage+Category.h"
#import "MynigmaDevice+Category.h"


@implementation AnnounceInfoDeviceMessage


//the initial message
+ (DeviceMessage*)announceInfoMessageWithPublicKeyEncData:(NSData*)publicKeyEncData verData:(NSData*)publicKeyVerData keyLabel:(NSString*)keyLabel hashData:(NSData*)hashData threadID:(NSString*)threadID senderDevice:(MynigmaDevice*)senderDevice targetDevice:(MynigmaDevice*)targetDevice onLocalContext:(NSManagedObjectContext*)localContext isResponse:(BOOL)isAcknowledgement
{
    if(!publicKeyVerData || !publicKeyEncData || !keyLabel || !hashData)
    {
        NSLog(@"Error creating announce info message: %@, %@, %@", publicKeyVerData, publicKeyEncData, hashData);
        return nil;
    }

    DeviceMessage* newMessage = [DeviceMessage constructNewDeviceMessageInContext:localContext];

    [newMessage setBurnAfterReading:@YES];

    //valid for ten minutes
    NSDate* expiryDate = [NSDate dateWithTimeIntervalSinceNow:60*10];
    [newMessage setExpiryDate:expiryDate];

    if(isAcknowledgement)
        [newMessage setMessageCommand:@"1_ACK_ANNOUNCE_INFO"];
    else
        [newMessage setMessageCommand:@"1_ANNOUNCE_INFO"];

    NSData* keyLabelData = [keyLabel dataUsingEncoding:NSUTF8StringEncoding];

    [newMessage setPayload:@[publicKeyVerData, publicKeyEncData, keyLabelData, hashData]];

    if(senderDevice)
        [newMessage setSender:senderDevice];
    else
        [newMessage setSender:[MynigmaDevice currentDeviceInContext:localContext]];

    [newMessage setDateSent:[NSDate date]];

    [newMessage setThreadID:threadID];

    if(targetDevice)
        [newMessage setTargets:[NSSet setWithObject:targetDevice]];
    else
        [newMessage setTargets:[NSSet setWithObject:[MynigmaDevice currentDeviceInContext:localContext]]];
    
    return newMessage;
}

@end
