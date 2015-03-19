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





#import "BugReporterController.h"
#import "EmailMessage+Category.h"
#import "AppDelegate.h"
#import "UserSettings+Category.h"
#import "IMAPAccountSetting+Category.h"
#import "EmailRecipient.h"
#import "IMAPAccount.h"
#import "FileAttachment+Category.h"
#import "EmailMessageData.h"
#import "SendingManager.h"
#import "AttachmentsManager.h"
#import "EmailMessageInstance+Category.h"
#import <CrashReporter/CrashReporter.h>




@interface BugReporterController ()

@end

@implementation BugReporterController

@synthesize textView;
@synthesize appendLogButton;
@synthesize segCell;

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
    [super windowDidLoad];


    if ([APPDELEGATE.crashReporter hasPendingCrashReport])
    {
        //[appendLogButton setHidden:NO];
        [appendLogButton setState:NSOnState];

        //there is a crash report - fill in the standard crash report text
        [textView setString:NSLocalizedString(@"Dear Mynigma team,\n\nmy app crashed the last time I used it.\n\nPlease look into the problem and fix it as soon as possible.\n\nSincerely,\n\nUnhappy user", @"Standard crash report text")];
    }
    else
    {
        //[appendLogButton setHidden:YES];
        [appendLogButton setState:NSOffState];
    }
}


- (void)windowWillLoad
{

}

- (IBAction)send:(id)sender
{
    if(![UserSettings currentUserSettings] || ![UserSettings currentUserSettings].preferredAccount)
    {
        NSBeep();
    }
    else
    {
        EmailMessage* newDraftMessage = [EmailMessage newDraftMessageInContext:MAIN_CONTEXT];

        if(appendLogButton.state==NSOnState)
        {
            if ([APPDELEGATE.crashReporter hasPendingCrashReport])
            {
                NSError* error = nil;

                PLCrashReportTextFormat textFormat = PLCrashReportTextFormatiOS;

                PLCrashReport* crashReport = [[PLCrashReport alloc] initWithData:[APPDELEGATE.crashReporter loadPendingCrashReportData] error:&error];
                NSString* crashReportString = [PLCrashReportTextFormatter stringValueForCrashReport:crashReport withTextFormat:textFormat];

                if (crashReportString)
                {
                    if(appendLogButton.state==NSOnState)
                    {
                        NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
                        FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
                        [newAttachment setAttachedToMessage:newDraftMessage];
                        [newAttachment setAttachedAllToMessage:newDraftMessage];
                        [newAttachment setContentType:@"application/octet-stream"];
                        [newAttachment setFileName:@"report.crash"];
                        [newAttachment setDownloadProgress:@1];

                        NSData* attData = [crashReportString dataUsingEncoding:NSUTF8StringEncoding];
                        [newAttachment saveDataToPrivateURL:attData];

                        [newAttachment setSize:[NSNumber numberWithInteger:attData.length]];
                    }
                }
            }

            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            NSString *documentsDirectory = [paths objectAtIndex:0];
            NSString *logPath = [[documentsDirectory stringByExpandingTildeInPath] stringByAppendingPathComponent:@"console.log"];
            NSError* error = nil;
            NSString* consoleLog = [NSString stringWithContentsOfFile:logPath encoding:NSUTF8StringEncoding error:&error];
            if(error)
                NSLog(@"Error writing console.log file to string: %@",error);
            NSString* briefConsoleLog = consoleLog.length>4096?[consoleLog substringWithRange:NSMakeRange(consoleLog.length-4096, 4096)]:consoleLog;
            if(briefConsoleLog.length>0)
            {
                NSEntityDescription* entity = [NSEntityDescription entityForName:@"FileAttachment" inManagedObjectContext:MAIN_CONTEXT];
                FileAttachment* newAttachment = [[FileAttachment alloc] initWithEntity:entity insertIntoManagedObjectContext:MAIN_CONTEXT];
                [newAttachment setAttachedToMessage:newDraftMessage];
                [newAttachment setAttachedAllToMessage:newDraftMessage];
                [newAttachment setContentType:@"application/octet-stream"];
                NSData* attData = [briefConsoleLog dataUsingEncoding:NSUTF8StringEncoding];
                [newAttachment setFileName:@"ConsoleLog.txt"];
                [newAttachment setSize:[NSNumber numberWithInteger:attData.length]];
                [newAttachment setDownloadProgress:@1];

                [newAttachment saveDataToPrivateURL:attData];

            }
        }

        [APPDELEGATE.crashReporter purgePendingCrashReport];

        NSString* priorityString = @"none";
        switch(segCell.selectedSegment)
        {
            case 0: priorityString = @"high";
                break;
            case 1: priorityString = @"medium";
                break;
            case 2: priorityString = @"low";
                break;
        }
        NSString* body = [NSString stringWithFormat:@"Bug report\n\nPriority: %@\n\n%@",priorityString, textView.string];


        [newDraftMessage setDateSent:[NSDate date]];


        [newDraftMessage.messageData setHtmlBody:[NSString stringWithFormat:@"<html><body>%@<br><br><br></body></html>",[body stringByReplacingOccurrencesOfString:@"\n" withString:@"<br>"]]];
        [newDraftMessage.messageData setSubject:@"Bug report"];
        [newDraftMessage.messageData setFromName:[UserSettings currentUserSettings].preferredAccount.senderName?[UserSettings currentUserSettings].preferredAccount.senderName:@"no name"];

        EmailMessageInstance* messageInstance = [EmailMessageInstance findOrMakeNewInstanceForMessage:newDraftMessage inFolder:[UserSettings currentUserSettings].preferredAccount.draftsFolder inContext:MAIN_CONTEXT];

        [messageInstance setFlags:[NSNumber numberWithInt:MCOMessageFlagSeen]];
        [messageInstance setAddedToFolder:messageInstance.inFolder];

        [messageInstance changeUID:nil];

        [newDraftMessage.messageData setLoadRemoteImages:@YES];


        NSMutableArray* emailRecipients = [NSMutableArray new];

        EmailRecipient* recipient = [EmailRecipient new];
        [recipient setName:@"Mynigma info"];
        [recipient setEmail:@"info@mynigma.org"];
        [recipient setType:TYPE_TO];
        [emailRecipients addObject:recipient];

        EmailRecipient* myselfFrom = [EmailRecipient new];
        [myselfFrom setEmail:[UserSettings currentUserSettings].preferredAccount.outgoingEmail];
        [myselfFrom setName:[UserSettings currentUserSettings].preferredAccount.outgoingUserName];
        [myselfFrom setType:TYPE_FROM];
        [emailRecipients addObject:myselfFrom];

        EmailRecipient* myselfReplyTo = [EmailRecipient new];
        [myselfReplyTo setEmail:[UserSettings currentUserSettings].preferredAccount.outgoingEmail];
        [myselfReplyTo setName:[UserSettings currentUserSettings].preferredAccount.outgoingUserName];
        [myselfReplyTo setType:TYPE_REPLY_TO];
        [emailRecipients addObject:myselfReplyTo];

        NSMutableData* addressData = [NSMutableData new];
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:addressData];
        [archiver encodeObject:emailRecipients forKey:@"recipients"];
        [archiver finishEncoding];

        [newDraftMessage.messageData setAddressData:addressData];

        IMAPAccount* account = [UserSettings currentUserSettings].preferredAccount.account;
        
        //NSLog(@"Accounts: %@, preferred: %@",MODEL.accounts,MODEL.currentUserSettings.preferredAccount);
        if(account)
        {
            [SendingManager sendDraftMessageInstance:messageInstance fromAccount:account withCallback:^(NSInteger result,NSError* error) {
                if(result != 1)
                    NSBeep();
                else
                {
                    NSSound* sound = [NSSound soundNamed:@"mail_sent.mp3"];
                    if(sound)
                    {
                        [sound play];
                    }
                    else
                        NSLog(@"Sent mail sound could not be found!!!");
                }
            }];
        }
        else
            NSBeep();
    }
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

- (IBAction)cancel:(id)sender
{
    [APPDELEGATE.crashReporter purgePendingCrashReport];
    
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}

@end
