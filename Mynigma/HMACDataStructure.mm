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

#import "HMACDataStructure.h"
#import "mynigma.pb.h"




@implementation HMACDataStructure

+ (instancetype)parseFromProtocolBuffersData:(NSData*)data
{
    mynigma::HMACData* HMACData = new mynigma::HMACData;
    
    HMACData->ParseFromArray([data bytes], (int)[data length]);
    
    HMACDataStructure* newStructure = [HMACDataStructure new];
    
    NSData* versionStringData = [[NSData alloc] initWithBytes:HMACData->version().data() length:HMACData->version().size()];
    NSString* versionString = [[NSString alloc] initWithData:versionStringData encoding:NSUTF8StringEncoding];
    [newStructure setVersion:versionString];
    
    NSData* encryptedData = [[NSData alloc] initWithBytes:HMACData->encrypteddata().data() length:HMACData->encrypteddata().size()];
    [newStructure setEncryptedData:encryptedData];
    
    NSData* HMAC = [[NSData alloc] initWithBytes:HMACData->hmac().data() length:HMACData->hmac().size()];
    [newStructure setHMAC:HMAC];
    
    if(HMACData)
        delete HMACData;
    
    return newStructure;
}

- (instancetype)initWithEncryptedData:(NSData*)encryptedData HMAC:(NSData*)HMAC version:(NSString*)version
{
    self = [super init];
    if (self) {
        
        [self setEncryptedData:encryptedData];
        [self setHMAC:HMAC];
        [self setVersion:version];
    }
    return self;
}

- (NSData*)serialisedData
{
    mynigma::HMACData* HMACData = new mynigma::HMACData;
    
    HMACData->set_version(self.version.UTF8String);
    HMACData->set_encrypteddata(self.encryptedData.bytes, self.encryptedData.length);
    HMACData->set_hmac(self.HMAC.bytes, self.HMAC.length);
    
    int encrData_size = HMACData->ByteSize();
    void* encr_data = malloc(encrData_size);
    HMACData->SerializeToArray(encr_data, encrData_size);

    NSData* returnData = [[NSData alloc] initWithBytes:encr_data length:encrData_size];;
    free(encr_data);
    delete HMACData;
    
    return returnData;
}

@end
