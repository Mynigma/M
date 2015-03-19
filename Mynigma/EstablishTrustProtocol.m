//
//  EstablishTrustProtocol.m
//  Mynigma
//
//  Created by Roman Priebe on 21.05.14.
//  Copyright (c) 2014 Mynigma UG (haftungsbeschränkt). All rights reserved.
//

#import "EstablishTrustProtocol.h"
#import "DeviceMessage.h"
#import "MessageCommandExpectation.h"
#import "AppleEncryptionWrapper.h"
#import "OpenSSLWrapper.h"
#import "MynigmaDevice+Category.h"
#import "DeviceConnectionHelper.h"



@implementation EstablishTrustProtocol

- (EstablishTrustProtocol*)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (BOOL)verifyPayloads
{
    //check that the hash is actually correct
    NSMutableData* dataToBeHashed = [NSMutableData dataWithData:self.partnerSecretData];

    [dataToBeHashed appendData:[self.partnerDevice.deviceId dataUsingEncoding:NSUTF8StringEncoding]];

    NSData* computedHash = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];

    if([computedHash isEqual:self.partnerHashData])
    {
        return YES;
    }

    NSLog(@"Invalid hash computed!!!");

    return NO;
}

- (void)processDeviceMessage:(DeviceMessage*)deviceMessage
{
    //first ensure that this particular command is not out of turn in the protocol
    if([self.expectedMessageCommand validateCommand:deviceMessage.messageKind withNumberOfPayloads:deviceMessage.payload.count])
    {
        //ok, this command was expected
        [self.payloads addObject:deviceMessage.payload];

        if([deviceMessage.messageKind isEqualToString:@"1_ANNOUNCE_INFO"])
        {
            //store the received values
            [self setPartnerPublicKeyData:deviceMessage.payload[0]];

            [self setPartnerHashData:deviceMessage.payload[1]];

            //generate an ephemeral key
            NSArray* ephemeralKeyData = [OpenSSLWrapper generateEphemeralKeyPairData];

            if(ephemeralKeyData.count<2)
            {
                NSLog(@"Failed to generate ephemeral key!!!");
                return;
            }

            //public part
            self.publicKeyData = ephemeralKeyData[0];

            //private part
            self.privateKeyData = ephemeralKeyData[1];

            //some secret data
            self.secretData = [AppleEncryptionWrapper randomBytesOfLength:64];

            //hash the secret data, followed by the device UUID
            NSMutableData* dataToBeHashed = [NSMutableData dataWithData:self.secretData];

            NSData* UUIDData = [[MynigmaDevice currentDevice].deviceId dataUsingEncoding:NSUTF8StringEncoding];

            [dataToBeHashed appendData:UUIDData];

            //the hash: hash(secret||UUID)
            NSData* hashedData = [AppleEncryptionWrapper SHA512DigestOfData:dataToBeHashed];

            //respond with the next message in the protocol
            DeviceMessage* response = [DeviceMessage protocol1_message1b_inResponseToMessage:deviceMessage withPublicKeyData:self.publicKeyData hashData:hashedData];

            [response postDeviceMessage];

            self.expectedMessageCommand = EXPECT_COMMAND(@"1_CONFIRM_CONNECTION", @2);
        }
        else if([deviceMessage.messageKind isEqualToString:@"1_ACK_ANNOUNCE_INFO"])
        {
            [self setPartnerPublicKeyData:deviceMessage.payload[0]];

            [self setPartnerHashData:deviceMessage.payload[1]];

            //respond with the next message in the protocol
            DeviceMessage* response = [DeviceMessage protocol1_message2a_inResponseToMessage:deviceMessage withSecretKeyData:self.secretData];

            [response postDeviceMessage];



            self.expectedMessageCommand = EXPECT_COMMAND(@"1_ACK_CONFIRM_CONNECTION", @1);
        }
        else if([deviceMessage.messageKind isEqualToString:@"1_CONFIRM_CONNECTION"])
        {
            [self setPartnerSecretData:deviceMessage.payload[0]];

            //make sure all the necessary data is there
            if(self.publicKeyData && self.privateKeyData && self.partnerPublicKeyData && self.thisDevice.deviceId && self.partnerDevice.deviceId && self.secretData && self.partnerSecretData && self.partnerHashData)
            {
                if([self verifyPayloads])
                {

                NSMutableData* INFOData = [NSMutableData dataWithData:self.publicKeyData];

                [INFOData appendData:[self.thisDevice.deviceId dataUsingEncoding:NSUTF8StringEncoding]];

                [INFOData appendData:self.secretData];

                [INFOData appendData:self.partnerPublicKeyData];

                [INFOData appendData:[self.partnerDevice.deviceId dataUsingEncoding:NSUTF8StringEncoding]];

                [INFOData appendData:self.partnerSecretData];

                NSArray* shortDigestChunks = [AppleEncryptionWrapper shortDigestChunksOfData:INFOData];

                [[DeviceConnectionHelper sharedInstance] showShortDigestChunks:shortDigestChunks];



                //respond with the next message in the protocol
                DeviceMessage* response = [DeviceMessage protocol1_message2b_inResponseToMessage:deviceMessage withSecretKeyData:self.secretData];

                [response postDeviceMessage];

                self.expectedMessageCommands = [NSSet setWithObject:@"1_ACK_CONFIRM_CONNECTION"];
                }
                else
                {
                    [self cancelProtocolWithErrorString:@"Invalid data!"];
                }
            }
        }
        else if([deviceMessage.messageKind isEqualToString:@"1_ACK_CONFIRM_CONNECTION"])
        {
            //make sure all the necessary data is there
            if(self.publicKeyData && self.privateKeyData && self.partnerPublicKeyData && self.thisDevice.deviceId && self.partnerDevice.deviceId && self.secretData && self.partnerSecretData && self.partnerHashData)
            {
                //check that the hash is actually correct
                if([self verifyPayloads])
                {
                NSMutableData* INFOData = [NSMutableData dataWithData:self.publicKeyData];

                [INFOData appendData:[self.thisDevice.deviceId dataUsingEncoding:NSUTF8StringEncoding]];

                [INFOData appendData:self.secretData];

                [INFOData appendData:self.partnerPublicKeyData];

                [INFOData appendData:[self.partnerDevice.deviceId dataUsingEncoding:NSUTF8StringEncoding]];

                [INFOData appendData:self.partnerSecretData];

                NSArray* shortDigestChunks = [AppleEncryptionWrapper shortDigestChunksOfData:INFOData];
                
                [[DeviceConnectionHelper sharedInstance] showShortDigestChunks:shortDigestChunks];
                }
                else
                {
                    [self cancelProtocolWithErrorString:@"Error: invalid data!!!"];
                }
            }
        }
        else
        {
            NSLog(@"Out of turn command");
            [self cancelProtocolWithErrorString:@"Error: out of turn command!"];
        }
    }
}

- (void)startProtocol
{
    self.currentStage++;
}

- (void)cancelProtocolWithErrorString:(NSString*)errorString
{
    
}

@end
