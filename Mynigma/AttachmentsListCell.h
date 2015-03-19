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

@class FileAttachment;

@interface AttachmentsListCell : UITableViewCell

@property IBOutlet UIImageView* typeImageView;
@property IBOutlet UILabel* nameLabel;
@property IBOutlet UILabel* sizeLabel;
@property IBOutlet UILabel* statusLabel;
@property IBOutlet UIProgressView* progressBar;

@property IBOutlet UIButton* actionButton;

@property NSMutableArray* documentInteractionController;

@property FileAttachment* attachment;

@property (nonatomic, strong) UIDocumentInteractionController* interactionController;

- (void)configureWithAttachment:(FileAttachment*)attachment andDocumentInteractionController:(UIDocumentInteractionController*)documentInteractionController;

- (IBAction)actionButtonTapped:(id)sender;

- (void)refreshDownloadProgress;

@end
