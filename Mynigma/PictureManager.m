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





#import "PictureManager.h"
#import "DisplayMessageController.h"
#import "ComposeNewController.h"
#import "AttachmentsDetailListController.h"
#import "AppDelegate.h"
#import "EmailMessageInstance+Category.h"
#import "EmailMessage+Category.h"
#import "ViewControllersManager.h"



@implementation PictureManager

+ (PictureManager*)sharedInstance
{
    static dispatch_once_t p = 0;

    __strong static id sharedObject = nil;

    dispatch_once(&p, ^{
        sharedObject = [PictureManager new];
    });

    return sharedObject;
}

- (void)takeNewPhotoInViewController:(UIViewController*)viewController
{
    self.callingViewController = viewController;

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;

    [viewController presentViewController:picker animated:YES completion:^{

    }];
}

- (void)pickExistingPhotoInViewController:(UIViewController*)viewController
{
    self.callingViewController = viewController;

    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {

        if([self.callingViewController isKindOfClass:[ComposeNewController class]])
        {
            [(ComposeNewController*)self.callingViewController showPopoverFromAttachmentsButton:picker];
        }
    }
    else
    {
        [viewController presentViewController:picker animated:YES completion:^{
        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];

    NSData* pngData = UIImagePNGRepresentation(chosenImage);

    if([self.callingViewController isKindOfClass:[ComposeNewController class]])
    {
        [(ComposeNewController*)self.callingViewController addPhotoAttachmentWithData:pngData];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {

        if([self.callingViewController isKindOfClass:[ComposeNewController class]])
        {
            [(ComposeNewController*)self.callingViewController hidePopover];
        }
    }

    if([ViewControllersManager sharedInstance].attachmentsListController && [self.callingViewController isKindOfClass:[ComposeNewController class]])
    {
        [[ViewControllersManager sharedInstance].attachmentsListController setupWithAttachments:[(ComposeNewController*)self.callingViewController allAttachments]];
    }

    self.callingViewController = nil;

    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
