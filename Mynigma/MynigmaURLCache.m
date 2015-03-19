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





#import "MynigmaURLCache.h"
#import "EmailMessageInstance+Category.h"
#import "AppDelegate.h"
#import "DisplayMessageController.h"
#import "ComposeNewController.h"
#import "FileAttachment+Category.h"
#import "EmailMessage+Category.h"
#import "ViewControllersManager.h"



@implementation MynigmaURLCache

- (NSCachedURLResponse*)cachedResponseForRequest:(NSURLRequest*)request
{
    NSURL *url = [request URL];

    BOOL redirectCID = [url.absoluteString hasPrefix:@"https://cid/?p="];

    NSString* path = url.absoluteString;

    if (redirectCID)
    {
        NSString* cidString = [path stringByReplacingOccurrencesOfString:@"https://cid/?p=" withString:@""];

        EmailMessageInstance* messageInstance = [ViewControllersManager sharedInstance].displayMessageController.displayedMessageInstance;

        NSCachedURLResponse* urlResponse = [self findAttachmentWithCID:cidString forMessage:messageInstance.message forURL:url];

        if(urlResponse)
            return urlResponse;

        messageInstance = [ViewControllersManager sharedInstance].composeController.composedMessageInstance;

        urlResponse = [self findAttachmentWithCID:cidString forMessage:messageInstance.message forURL:url];

        if(urlResponse)
            return urlResponse;
    }

    return [super cachedResponseForRequest:request];
}

- (NSCachedURLResponse*)findAttachmentWithCID:(NSString*)cidString forMessage:(EmailMessage*)message forURL:(NSURL*)url
{
    for(FileAttachment* attachment in message.allAttachments)
    {
        if([[attachment.contentid lowercaseString] isEqualToString:[cidString lowercaseString]])
        {
            NSData* attachmentData = attachment.data;

            NSURLResponse *response = [[NSURLResponse alloc] initWithURL:url MIMEType:attachment.contentType expectedContentLength:[attachmentData length] textEncodingName:nil];

            NSCachedURLResponse *cachedResponse = [[NSCachedURLResponse alloc] initWithResponse:response data:attachmentData];

            return cachedResponse;
        }
    }

    return nil;
}

@end
