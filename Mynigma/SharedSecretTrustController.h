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





#import <UIKit/UIKit.h>

@class MynigmaDevice, TrustEstablishmentThread;

@interface SharedSecretTrustController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *deviceImage;

@property (weak, nonatomic) IBOutlet UILabel *deviceName;

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;

@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UILabel *feedbackLabel;

@property (weak, nonatomic) IBOutlet UILabel *chunk0;
@property (weak, nonatomic) IBOutlet UILabel *chunk1;
@property (weak, nonatomic) IBOutlet UILabel *chunk2;
@property (weak, nonatomic) IBOutlet UILabel *chunk3;
@property (weak, nonatomic) IBOutlet UILabel *chunk4;

@property (weak, nonatomic) IBOutlet UIButton *trustButton;

- (IBAction)trustDeviceButtonTapped:(id)sender;

@property MynigmaDevice* device;

- (void)setupWithDevice:(MynigmaDevice*)device;

- (void)showProgress:(NSInteger)progressIndex;

@property TrustEstablishmentThread* currentThread;

@property BOOL isEstablishingTrust;

@property IBOutlet NSLayoutConstraint* hideShortDigestsContraint;

- (void)showShortDigests:(NSArray*)chunks;


#pragma mark - IBAction methods

- (IBAction)matchConfirmed:(id)sender;
- (IBAction)matchDenied:(id)sender;


@end
