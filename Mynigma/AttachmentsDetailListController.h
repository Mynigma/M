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

@class FileAttachment, EmailMessage;

@interface AttachmentsDetailListController : UITableViewController <UIDocumentInteractionControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property NSArray* attachments;
@property NSArray* documentInteractionControllers;

@property BOOL canAddAndRemoveAttachments;

@property(nonatomic, weak) UIViewController* callingViewController;

//- (void)setupWithMessage:(EmailMessage*)message;
- (void)setupWithAttachments:(NSArray*)attachments;

- (void)refreshAttachment:(FileAttachment*)fileAttachment;

- (void)setCanAddAndRemove:(BOOL)canAddAndRemove;

@end
