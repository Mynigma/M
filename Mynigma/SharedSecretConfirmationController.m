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





#import "SharedSecretConfirmationController.h"
#import "DeviceConnectionHelper.h"
#import "TrustEstablishmentThread.h"
//#import "DeviceConnectionThread.h"
#import "MynigmaDevice.h"

@interface SharedSecretConfirmationController ()

@end

@implementation SharedSecretConfirmationController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
//    [TrustEstablishmentThread startNewThreadWithTargetDevice:self.targetDevice withCallback:^(NSString* newThreadID) {
//
//         [[DeviceConnectionHelper sharedInstance] startEstablishingTrustInThreadWithID:newThreadID];
//    }];
//
//    [self showProgress:0];

    [super windowDidLoad];
}

- (void)showChunks:(NSArray*)chunks
{
    if(chunks.count < 3)
    {
        NSLog(@"Error: count of chunks is less than 3!!!");
        return;
    }

    [self.chunk0 setStringValue:chunks[0]];
    [self.chunk1 setStringValue:chunks[1]];
    [self.chunk2 setStringValue:chunks[2]];
//    [self.chunk3 setStringValue:chunks[3]];
//    [self.chunk4 setStringValue:chunks[4]];

//    [self.feedbackLabel setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Please compare codes with %@", nil), self.targetDevice.displayName]];
}

//- (void)showProgress:(NSInteger)progressIndex
//{
//    [self.levelIndicator setIntegerValue:progressIndex];
//
//    if(progressIndex <5)
//    {
//        [self.confirmButton setHidden:YES];
//        [self.cancelButton setStringValue:NSLocalizedString(@"Cancel", nil)];
//    }
//    else
//    {
//        [self.confirmButton setHidden:NO];
//        [self.confirmButton setStringValue:NSLocalizedString(@"The codes match", nil)];
//        [self.cancelButton setStringValue:NSLocalizedString(@"The codes do not match", nil)];
//    }
//
//
//    switch(progressIndex)
//    {
//        case 0:
//            [self.feedbackLabel setStringValue:@"Generating ephemeral key..."];
//            break;
//        case 1:
//            [self.feedbackLabel setStringValue:@"Starting handshake..."];
//            break;
//        case 2:
//            [self.feedbackLabel setStringValue:@"Waiting for response..."];
//            break;
//        case 3:
//            [self.feedbackLabel setStringValue:@"Stage 3"];
//            break;
//        case 4:
//            [self.feedbackLabel setStringValue:@"Stage 4"];
//            break;
//    }
//}

- (IBAction)matchConfirmed:(id)sender
{
    [self.targetDevice setIsTrusted:@YES];

    [self.currentThread confirmMatch];


    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

- (IBAction)matchDenied:(id)sender
{
    [self.currentThread cancel];

    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}


@end
