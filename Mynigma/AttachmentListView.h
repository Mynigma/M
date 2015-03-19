//Copyright © 2012 - 2015 Roman Priebe
//
//This file is part of M - Safe email made simple.
//
//M is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//M is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with M.  If not, see <http://www.gnu.org/licenses/>.
//



#import <UIKit/UIKit.h>

@class FileAttachment;

@interface AttachmentListView : UIView

@property IBOutlet UIImageView* icon;

@property IBOutlet UILabel* topLabel;

@property IBOutlet UILabel* detailLabel;

@property IBOutlet UIProgressView* progressView;

@property IBOutlet UIButton* openButton;


@property FileAttachment* theAttachment;

- (IBAction)open:(id)sender;

- (void)fillWithAttachment:(FileAttachment*)attachment;

- (void)refresh;

@end
