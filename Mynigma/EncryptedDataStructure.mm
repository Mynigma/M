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

#import "EncryptedDataStructure.h"
#import "mynigma.pb.h"
#import "SessionKeyEntryDataStructure.h"



@implementation EncryptedDataStructure

+ (instancetype)parseFromProtocolBuffersData:(NSData*)data
{
    EncryptedDataStructure* newStructure = [EncryptedDataStructure new];
        
    mynigma::encryptedData* encryptedData = new mynigma::encryptedData;
    
    encryptedData->ParseFromArray([data bytes], (int)[data length]);
    
    NSMutableArray* sessionKeyTable = [NSMutableArray new];
    
    for(int i=0;i<encryptedData->encrsessionkeytable_size();i++)
    {
        mynigma::encrSessionKeyEntry* entry = new mynigma::encrSessionKeyEntry;
        *entry = encryptedData->encrsessionkeytable(i);
        
        NSData* keyLabelData = [[NSData alloc] initWithBytes:entry->keylabel().data() length:entry->keylabel().size()];
        NSData* foundEncrSessionKeyData = [[NSData alloc] initWithBytes:entry->encrsessionkey().data() length:entry->encrsessionkey().size()];
        
        NSData* foundEncrIntroData = [[NSData alloc] initWithBytes:entry->introductiondata().data() length:entry->introductiondata().size()];
        
        NSString* keyLabel = [[NSString alloc] initWithData:keyLabelData encoding:NSUTF8StringEncoding];

        SessionKeyEntryDataStructure* sessionKeyEntry = [SessionKeyEntryDataStructure new];
        
        [sessionKeyEntry setKeyLabel:keyLabel];
        [sessionKeyEntry setEncrSessionKey:foundEncrSessionKeyData];
        [sessionKeyEntry setIntroductionData:foundEncrIntroData];
        
        if(entry)
            delete entry;
        
        if(sessionKeyEntry)
            [sessionKeyTable addObject:sessionKeyEntry];
    }
    
    [newStructure setEncrSessionKeyTable:sessionKeyTable];
    
    NSData* messageData = [[NSData alloc] initWithBytes:encryptedData->encrmessagedata().data() length:encryptedData->encrmessagedata().size()];
    [newStructure setEncrMessageData:messageData];

    NSData* messageHMACData = [[NSData alloc] initWithBytes:encryptedData->messagehmac().data() length:encryptedData->messagehmac().size()];
    [newStructure setMessageHMAC:messageHMACData];

    NSMutableArray* newAttachmentsHMACArray = [NSMutableArray new];
    
    for(int i=0;i<encryptedData->attachmentshmac_size();i++)
    {
        NSData* attachmentsHMACData = [[NSData alloc] initWithBytes:encryptedData->attachmentshmac(i).data() length:encryptedData->attachmentshmac(i).size()];
        
        if(attachmentsHMACData)
            [newAttachmentsHMACArray addObject:attachmentsHMACData];
    }
    
    [newStructure setAttachmentHMACs:newAttachmentsHMACArray];

    if(encryptedData)
        delete encryptedData;
    
    return newStructure;
}

@end
