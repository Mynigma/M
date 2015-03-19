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





#import "SharedSecretTrustController.h"
#import "MynigmaDevice+Category.h"
#import "TrustEstablishmentThread.h"
#import "DeviceConnectionHelper.h"


@interface SharedSecretTrustController ()

@end

@implementation SharedSecretTrustController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self showProgress:-1];
    [self setIsEstablishingTrust:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)trustDeviceButtonTapped:(id)sender
{
    if(self.isEstablishingTrust)
    {
        [self setIsEstablishingTrust:NO];
        [self.currentThread cancel];
        self.currentThread = nil;
        [self.trustButton setTitle:NSLocalizedString(@"Trust this device", @"Device connection UI") forState:UIControlStateNormal];
        [self showProgress:-1];
    }
    else
    {
        [self setIsEstablishingTrust:YES];
        [self.trustButton setTitle:NSLocalizedString(@"Cancel", @"Cancel Button") forState:UIControlStateNormal];
        [TrustEstablishmentThread startNewThreadWithTargetDeviceUUID:self.device.deviceId withCallback:^(NSString *newThreadID){

            self.currentThread = [TrustEstablishmentThread threadWithID:newThreadID];
            [[DeviceConnectionHelper sharedInstance] startEstablishingTrustInThreadWithID:newThreadID];
    }];
    }
}

- (void)setupWithDevice:(MynigmaDevice*)device
{
    [self setDevice:device];

    [self.deviceImage setImage:device.image];
    [self.deviceName setText:device.displayName?device.displayName:@""];

    if([device isEqual:[MynigmaDevice currentDevice]])
    {
        [self.trustButton setHidden:YES];
        [self.detailLabel setText:NSLocalizedString(@"This device", @"Device connection UI")];
    }
    else
    {
        [self.trustButton setHidden:NO];

        NSDate* lastSyncedDate = device.lastSynced;

        NSString* lastSyncedString = (lastSyncedDate==nil)?NSLocalizedString(@"Never synced", @"Device connection UI"):[NSString stringWithFormat:NSLocalizedString(@"Last synced: %@", @"Device connection UI"), [NSDateFormatter localizedStringFromDate:device.lastSynced dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterMediumStyle]];

        [self.detailLabel setText:lastSyncedString];
    }
}

- (void)showProgress:(NSInteger)progressIndex
{
    [self.progressBar setProgress:progressIndex/8.];
    [self.progressBar setHidden:progressIndex<0];

    switch(progressIndex)
    {
        case -1:
            [self.feedbackLabel setText:NSLocalizedString(@"Click \"Trust this device\" to sync your data. Never trust a device you do not recognise.", @"Device connection feedback")];
            break;
        case 0:
            [self.feedbackLabel setText:NSLocalizedString(@"Generating ephemeral key...", @"Device connection feedback")];
            break;
        case 1:
            [self.feedbackLabel setText:NSLocalizedString(@"Starting handshake...", @"Device connection feedback")];
            break;
        case 2:
            [self.feedbackLabel setText:NSLocalizedString(@"Waiting for response...", @"Device connection feedback")];
            break;
        case 3:
            [self.feedbackLabel setText:NSLocalizedString(@"Received response", @"Device connection feedback")];
            break;
        case 4:
            [self.feedbackLabel setText:NSLocalizedString(@"Please compare this code to the one shown on the other device", @"Device connection feedback")];
            break;
        default:
            [self.feedbackLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Invalid progress index: %ld", @"Device connection feedback"), (long)progressIndex]];
            break;
    }
}

- (void)showShortDigests:(NSArray*)chunks
{
    if(chunks.count >= 5)
    {
        [self.chunk0 setText:chunks[0]];
        [self.chunk1 setText:chunks[1]];
        [self.chunk2 setText:chunks[2]];
        [self.chunk3 setText:chunks[3]];
        [self.chunk4 setText:chunks[4]];
        [self.hideShortDigestsContraint setPriority:1];
    }
}

- (IBAction)matchConfirmed:(id)sender
{
    [self.currentThread confirmMatch];
}

- (IBAction)matchDenied:(id)sender
{
    [self.currentThread cancel];
}

@end
