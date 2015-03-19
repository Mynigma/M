//
//  EstablishTrustProtocol.h
//  Mynigma
//
//  Created by Roman Priebe on 21.05.14.
//  Copyright (c) 2014 Mynigma UG (haftungsbeschränkt). All rights reserved.
//

#import "DeviceConnectionProtocol.h"

@interface EstablishTrustProtocol : DeviceConnectionProtocol

@property NSData* publicKeyData;

@property NSData* privateKeyData;

@property MynigmaDevice* thisDevice;

@property MynigmaDevice* partnerDevice;

@property NSData* partnerPublicKeyData;

@property NSData* partnerHashData;

@property NSData* partnerSecretData;

@property NSString* protocol;

@property NSData* secretData;

@property NSSet* expectedMessageCommands;


- (BOOL)verifyPayloads;

@end
