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





#import "MessageListController.h"
#import "EmailMessage+Category.h"
#import "AppDelegate.h"
#import "IMAPAccount.h"
#import "MessageCellView.h"
#import "EmailRecipient.h"
#import "IMAPAccountSetting+Category.h"
#import "IMAPFolderSetting+Category.h"
#import "Recipient.h"
#import "FileAttachment+Category.h"
#import "DownloadHelper.h"
#import "MessageRowView.h"
#import "GmailLabelSetting.h"
#import "GmailAccountSetting.h"
#import "MynigmaMessage+Category.h"
#import "EmailMessageData.h"
#import "EmailMessageInstance+Category.h"
#import "OutlineObject.h"
#import "ReloadingView.h"
#import "ReloadViewController.h"
#import "EmailMessageController.h"
#import "DeviceMessage+Category.h"
#import "DisplayMessageView.h"
#import "WindowManager.h"
#import "SelectionAndFilterHelper.h"

#if ULTIMATE

#import "CustomerManager.h"

#endif



@interface MessageListController ()

@end

@implementation MessageListController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
    }
    return self;
}

- (void)awakeFromNib
{
    [APPDELEGATE setMessageListController:self];

    NSTableView* tableView = APPDELEGATE.messagesTable;
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleClick:)];
}


#pragma mark -
#pragma mark TABLE VIEW DELEGATE METHODS


- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(row==[tableView numberOfRows]-1)
    {
        NSTableCellView* cellView = [tableView makeViewWithIdentifier:@"EndView" owner:self];
        return cellView;
    }

    NSObject* messageObject = [self messageObjectForIndex:row];
    MessageCellView *messageView = [tableView makeViewWithIdentifier:@"MessageView" owner:self];

    EmailMessage* displayedMessage = nil;
    EmailMessageInstance* displayedMessageInstance = nil;

    if([messageObject isKindOfClass:[EmailMessageInstance class]])
    {
        displayedMessageInstance = (EmailMessageInstance*)messageObject;

        displayedMessage = displayedMessageInstance.message;

        [messageView setMessageInstance:(EmailMessageInstance*)messageObject];

        [messageView setMessage:displayedMessage];
    }
    else if([messageObject isKindOfClass:[EmailMessage class]])
    {
        displayedMessage = (EmailMessage*)messageObject;

        displayedMessageInstance = nil;

        [messageView setMessageInstance:nil];

        [messageView setMessage:displayedMessage];
    }


    if([displayedMessage isSafe])
    {
        NSAttributedString* previewString = [self previewStringForMessageInstance:displayedMessageInstance];

        [messageView.previewField setAttributedStringValue:previewString];

            if(![displayedMessage isDownloaded]) //the myn data has not yet been downloaded
            {
                [messageView.fromField setStringValue:displayedMessage.messageData.fromName?displayedMessage.messageData.fromName:@""];
                [messageView.subjectField setStringValue:NSLocalizedString(@"Safe message",@"Safe, secure email message")];
                [messageView.dateSentField setStringValue:[self stringForDate:displayedMessage.dateSent]];
                return messageView;
            }
            else if(![displayedMessage isDecrypted]) //it has not yet been decrypted
            {
                [messageView.fromField setStringValue:displayedMessage.messageData.fromName?displayedMessage.messageData.fromName:@""];
                [messageView.subjectField setStringValue:NSLocalizedString(@"Safe message",@"Safe, secure email message")];
                [messageView.dateSentField setStringValue:[self stringForDate:displayedMessage.dateSent]];
                return messageView;
            }
            else //it's a downloaded, decrypted message, so just display it normally
            {
                if(displayedMessage.messageData.addressData)
                    [messageView.fromField setAttributedStringValue:[self attributedFromToString:displayedMessage.messageData.addressData]];
                else
                    [messageView.fromField setStringValue:NSLocalizedString(@"(nothing to display)",@"Placeholder")];
                [messageView.subjectField setStringValue:displayedMessage.messageData.subject?displayedMessage.messageData.subject:NSLocalizedString(@"Safe message",@"Safe, secure email message")];
                [messageView.dateSentField setStringValue:[self stringForDate:displayedMessage.dateSent]];
                return messageView;
            }
        }
    else if([displayedMessage isKindOfClass:[DeviceMessage class]])
    {
        NSAttributedString* previewString = [self previewStringForMessageInstance:displayedMessageInstance];

        [messageView.previewField setAttributedStringValue:previewString];

        [messageView.fromField setStringValue:NSLocalizedString(@"Internal Mynigma message", @"Device message subject")];
        [messageView.subjectField setStringValue:NSLocalizedString(@"Please do not delete",@"Device message subject in message list")];
        [messageView.dateSentField setStringValue:[self stringForDate:displayedMessage.dateSent]];

        return messageView;
    }
    else
    {
            if(displayedMessage.dateSent)
                [messageView.dateSentField setStringValue:[self stringForDate:displayedMessage.dateSent]];
            else
                [messageView.dateSentField setStringValue:@""];
            if(displayedMessage.messageData.addressData)
                [messageView.fromField setAttributedStringValue:[self attributedFromToString:displayedMessage.messageData.addressData]];
            else
                [messageView.fromField setStringValue:NSLocalizedString(@"(nothing to display)",@"Placeholder")];

        NSAttributedString* previewString = [self previewStringForMessageInstance:displayedMessageInstance];

        [messageView.previewField setAttributedStringValue:previewString];

        NSString* subjectString = displayedMessage.messageData.subject?displayedMessage.messageData.subject:NSLocalizedString(@"(no subject)",@"Placeholder");

        if(!subjectString)
            subjectString = @"(no subject)";

        NSAttributedString* subjectStr = [[NSAttributedString alloc] initWithString:subjectString];
            [messageView.subjectField setAttributedStringValue:subjectStr];
            return messageView;
    }

    [messageView.fromField setSelectable:NO];
    [messageView.textField setStringValue:NSLocalizedString(@"(no sender)",@"Placeholder")];
    [messageView.subjectField setStringValue:NSLocalizedString(@"(no subject)",@"Placeholder")];
    
    [messageView.dateSentField setStringValue:@""];
    
    return messageView;
    
}


- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    CGFloat returnValue = 72;

    return returnValue;
}

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    //if(APPDELEGATE.foldersInPullToRefreshUpdate.count>0 && row==0)
    //    return NO;

    return YES;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSIndexSet* selectedIndices = [APPDELEGATE.messagesTable selectedRowIndexes];

    if(selectedIndices.count!=1)
    {
        [[WindowManager sharedInstance].displayView showMessageInstance:nil];
        return;
    }

    NSInteger index = [selectedIndices firstIndex];

    NSObject* messageObject = [self messageObjectForIndex:index];

    EmailMessage* message = nil;

    EmailMessageInstance* messageInstance = nil;

    if([messageObject isKindOfClass:[EmailMessageInstance class]])
    {
        messageInstance = (EmailMessageInstance*)messageObject;

        message = messageInstance.message;

        [[WindowManager sharedInstance].displayView showMessageInstance:messageInstance];
    }
    else if([messageObject isKindOfClass:[EmailMessage class]])
    {
        message = (EmailMessage*)messageObject;

        [[WindowManager sharedInstance].displayView showMessage:message];
    }



    [DownloadHelper downloadMessage:message urgent:YES alsoDownloadAttachments:NO];

    for(FileAttachment* attachment in messageInstance.message.allAttachments)
    {
        //download attachments without user confirmation
        //if it's either inline or less than 50 KB
        if(attachment.isInline || attachment.size.unsignedIntegerValue < 50*1024)
            [attachment urgentlyDownloadWithCallback:nil];
    }

//    if(APPDELEGATE.suppressReloadOfContentViewerOnChangeOfMessageSelection)
//        return;
//
//    if(selectedIndices.count!=1)
//    {
//        [APPDELEGATE setViewerArray:newViewerArray];
//        [APPDELEGATE.viewerTable reloadData];
//        return;
//    }
//
//
//    NSInteger index = [selectedIndices firstIndex];
//
//    NSObject* messageObject = [self messageObjectForIndex:index];
//
//    EmailMessage* message = nil;
//
//    EmailMessageInstance* messageInstance = nil;
//
//    if([messageObject isKindOfClass:[EmailMessageInstance class]])
//    {
//        messageInstance = (EmailMessageInstance*)messageObject;
//
//        message = messageInstance.message;
//    }
//    else if([messageObject isKindOfClass:[EmailMessage class]])
//    {
//        message = (EmailMessage*)messageObject;
//    }
//
//    if([messageInstance isUnread])
//    {
//        [messageInstance markRead];
//    }
//
//    if(message)
//    {
//            if(index>=0 && index<APPDELEGATE.messagesTable.numberOfRows)
//            {
//                if(APPDELEGATE.viewerArray.count>0 && [APPDELEGATE.viewerArray[0] isEqual:messageObject])
//                {
//                    //don't do anything if the displayed message has not changed - it might simply be that the messages table has reloaded, which will cause re-selection. Reloading every time would cause flicker in the content viewer
//                }
//                else
//                {
//                    [APPDELEGATE.messagesTable beginUpdates];
//                    [APPDELEGATE.messagesTable reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
//                    [APPDELEGATE.messagesTable endUpdates];
//                }
//            }
//            
//
//            [newViewerArray addObject:messageObject];
//
//            if(message.allAttachments && message.allAttachments.count>0)
//            {
//                    NSArray* attachmentsArray = [message.allAttachments sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"contentid" ascending:YES]]];
//                    for(NSInteger i=0;i<attachmentsArray.count;i++)
//                    {
//                        FileAttachment* attachment = [attachmentsArray objectAtIndex:i];
//
//                        //TO DO: allow display of inline attachments by replacing the following line with a settings bool value
//                        if(attachment.attachedToMessage)
//                            [newViewerArray addObject:attachment];
//                        [attachment downloadAndOrDecryptUsingSession:nil withCallback:nil];
//                    }
//                }
//            [APPDELEGATE setViewerArray:newViewerArray];
//
//        }
//    else
//    {
//        [APPDELEGATE setViewerArray:newViewerArray];
//        [APPDELEGATE.viewerTable reloadData];
//        return;
//    }
//
//    [APPDELEGATE.viewerTable reloadData];
}


- (NSString *)tableView:(NSTableView *)tableView typeSelectStringForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSObject* messageObject = [self messageObjectForIndex:row];
    if([messageObject isKindOfClass:[EmailMessage class]])
        return [[(EmailMessage*)messageObject messageData] subject];
    if([messageObject isKindOfClass:[EmailMessageInstance class]])
        return [[(EmailMessageInstance*)messageObject message].messageData subject];
    return nil;
}


- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    return [MessageRowView new];
}




#pragma mark -
#pragma mark TABLE VIEW DATA SOURCE METHODS

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSInteger number = [(NSArray*)[[SelectionAndFilterHelper sharedInstance] filteredMessages] count];

    number++;

    //NSLog(@"Folders in pull to refresh update: %@", APPDELEGATE.foldersInPullToRefreshUpdate);

    return number;
}


#pragma mark -
#pragma mark DRAG AND DROP

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    NSLog(@"writeRowsWithIndexes");
    /*  NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
     [pboard declareTypes:[NSArray arrayWithObject:DRAGANDDROPMESSAGE] owner:self];
     [pboard setData:data forType:DRAGANDDROPMESSAGE];*/
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if([aTableView isEqual:APPDELEGATE.messagesTable] && ![SelectionAndFilterHelper sharedInstance].showContacts)
    {
        if([SelectionAndFilterHelper sharedInstance].draggedObjects.count==1 && row<APPDELEGATE.messagesTable.numberOfRows)
        {
            MessageCellView* cell = [aTableView viewAtColumn:0 row:row makeIfNecessary:NO];
            if([cell isKindOfClass:[MessageCellView class]])
            {
                EmailMessageInstance* instance = cell.messageInstance;
                if(instance)
                {
                    if(row<APPDELEGATE.messagesTable.numberOfRows)
                        [aTableView setDropRow:row dropOperation:NSTableViewDropOn];

                    OutlineObject* draggedObject = [SelectionAndFilterHelper sharedInstance].draggedObjects.anyObject;
                    if([draggedObject isKindOfClass:[OutlineObject class]])
                    {
                        NSSet* folders = [draggedObject associatedFoldersForAccountSettings:[NSSet setWithObject:instance.accountSetting]];
                        if(folders.count==1)
                        {
                            IMAPFolderSetting* folderSetting = folders.anyObject;
                            if([folderSetting isKindOfClass:[GmailLabelSetting class]])
                            {
                                if([instance canAddLabel:(GmailLabelSetting*)folderSetting])
                                {
                                    return NSDragOperationCopy;
                                }
                                if([[instance hasLabels] containsObject:folderSetting])
                                    return NSDragOperationDelete;
                            }
                        }
                    }
                }
            }
        }
    }
    return NSDragOperationNone;
}

- (void)tableView:(NSTableView *)tableView updateDraggingItemsForDrag:(id < NSDraggingInfo >)draggingInfo
{
    if([draggingInfo.draggingSource isEqual:APPDELEGATE.messagesTable])
    {

     NSLog(@"Update dragging items");
     [draggingInfo enumerateDraggingItemsWithOptions:NSDraggingItemEnumerationClearNonenumeratedImages forView:tableView classes:@[[NSPasteboardItem class]] searchOptions:nil usingBlock:^(NSDraggingItem *draggingItem, NSInteger idx, BOOL *stop) {
     
     NSLog(@"updating!");
     
     [draggingItem setImageComponentsProvider:^{
     NSDraggingImageComponent* draggingImage = [NSDraggingImageComponent new];
     [draggingImage setFrame:NSMakeRect(0, 0, 128, 179./2)];
     [draggingImage setContents:[NSImage imageNamed:@"postcardStraight2.png"]];
     [draggingImage setKey:@"SomeKey"];
     
     NSArray* imageComponentsProvider = @[draggingImage];
     return imageComponentsProvider;}];
     }];
    }
}


- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    if([aTableView isEqual:APPDELEGATE.messagesTable] && ![SelectionAndFilterHelper sharedInstance].showContacts)
    {
        if([SelectionAndFilterHelper sharedInstance].draggedObjects.count==1)
        {
            MessageCellView* cell = [aTableView viewAtColumn:0 row:row makeIfNecessary:NO];
            if([cell isKindOfClass:[MessageCellView class]])
            {
                EmailMessageInstance* instance = cell.messageInstance;
                if(instance)
                {
                    OutlineObject* draggedObject = [SelectionAndFilterHelper sharedInstance].draggedObjects.anyObject;
                    if([draggedObject isKindOfClass:[OutlineObject class]])
                    {
                        NSSet* folders = [draggedObject associatedFoldersForAccountSettings:[NSSet setWithObject:instance.accountSetting]];
                        if(folders.count==1)
                        {
                            IMAPFolderSetting* folderSetting = folders.anyObject;
                            if([folderSetting isKindOfClass:[GmailLabelSetting class]])
                             {
                                 if([instance canAddLabel:(GmailLabelSetting*)folderSetting])
                                 {
                                     [instance addDraggedLabel:(GmailLabelSetting*)folderSetting];
                                     [SelectionAndFilterHelper refreshMessageInstance:instance.objectID];
                                     return YES;
                                 }
                                 if([[instance hasLabels] containsObject:folderSetting])
                                 {
                                     NSAlert* alertMessage = [NSAlert alertWithMessageText:[NSString stringWithFormat:NSLocalizedString(@"The message is already labelled '%@'", @"Already have label explanation"), folderSetting.displayName] defaultButton:NSLocalizedString(@"Remove label", @"Remove label") alternateButton:NSLocalizedString(@"Cancel", @"Cancel Button") otherButton:nil informativeTextWithFormat:NSLocalizedString(@"Would you like to remove the label?", @"Remove label confirmation")];
                                     if([alertMessage runModal]==NSAlertDefaultReturn)
                                     {
                                         [instance removeHasLabelsObject:(GmailLabelSetting*)folderSetting];
                                         [instance setLabelsChangedInFolder:(GmailLabelSetting*)instance.inFolder];
                                         [SelectionAndFilterHelper refreshMessageInstance:instance.objectID];
                                         return YES;
                                     }
                                 }
                            }
                        }
                    }
                }
            }
        }
    }
    return NO;
}


- (void)tableView:(NSTableView *)aTableView draggingSession:(NSDraggingSession *)session endedAtPoint:(NSPoint)screenPoint operation:(NSDragOperation)operation
{

}

- (void)tableView:(NSTableView *)tableView draggingSession:(NSDraggingSession *)session willBeginAtPoint:(NSPoint)screenPoint forRowIndexes:(NSIndexSet *)rowIndexes
{
    [[WindowManager sharedInstance].displayView refresh];
    
    NSMutableSet* draggedObjectsSet = [NSMutableSet new];
    NSInteger index = rowIndexes.firstIndex;
    while(index!=NSNotFound)
    {
        EmailMessageInstance* messageInstance = (EmailMessageInstance*)[self messageObjectForIndex:index];
        if([messageInstance isKindOfClass:[EmailMessageInstance class]])
            [draggedObjectsSet addObject:messageInstance.objectID];
        index = [rowIndexes indexGreaterThanIndex:index];
    }
    [SelectionAndFilterHelper sharedInstance].draggedObjects = draggedObjectsSet;
}

- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet
{
    return nil;
}

- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    NSPasteboardItem *pasteboardItem = [[NSPasteboardItem alloc] init];
    NSArray *types = [[NSArray alloc] initWithObjects:DRAGANDDROPMESSAGE, nil];
    BOOL ok = [pasteboardItem setDataProvider:self forTypes:types];
    
    if (ok) {
        
        //NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        //[pasteboard clearContents];
        
        NSObject* messageObject = [self messageObjectForIndex:row];
        if([messageObject isKindOfClass:[EmailMessageInstance class]])
        {
            NSManagedObjectID* messageObjectID = [(NSManagedObject*)messageObject objectID];
            NSURL* messageURL = [messageObjectID URIRepresentation];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:messageURL];
            [pasteboardItem setData:data forType:DRAGANDDROPMESSAGE];
            return pasteboardItem;
        }
    }
    return nil;
}

- (void)pasteboard:(NSPasteboard *)pasteboard item:(NSPasteboardItem *)item provideDataForType:(NSString *)type
{
    NSLog(@"Pasteboard provide data");
}

- (void)pasteboardFinishedWithDataProvider:(NSPasteboard *)pasteboard
{
    NSLog(@"pasteboard finished");
}

#pragma mark -
#pragma mark MISCELLANEOUS


#pragma mark - SELECTION

- (void)selectRowAtIndex:(NSInteger)index
{
    NSInteger newSelectedRow = index;
    
    if(newSelectedRow >= 0 && newSelectedRow < APPDELEGATE.messagesTable.numberOfRows)
    {
        [APPDELEGATE.messagesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedRow] byExtendingSelection:NO];
    }
    else
    {
        //try the one before instead
        newSelectedRow--;
        if(newSelectedRow >= 0 && newSelectedRow < APPDELEGATE.messagesTable.numberOfRows)
        {
            [APPDELEGATE.messagesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedRow] byExtendingSelection:NO];
        }
        else
        {
            //give up - might be that the last message in the list was deleted
        }
    }

}


- (void)moveSelectionOnFromMessageObject:(NSObject*)messageObject
{
    if(APPDELEGATE.messagesTable.selectedRow == [EmailMessageController indexForMessageObject:messageObject])
    {
        //try the next row
        NSInteger newSelectedRow = APPDELEGATE.messagesTable.selectedRow+1;
        if(newSelectedRow >= 0 && newSelectedRow < APPDELEGATE.messagesTable.numberOfRows)
        {
            [APPDELEGATE.messagesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedRow] byExtendingSelection:NO];
        }
        else
        {
            //try the one before instead
            newSelectedRow--;
            if(newSelectedRow >= 0 && newSelectedRow < APPDELEGATE.messagesTable.numberOfRows)
            {
                [APPDELEGATE.messagesTable selectRowIndexes:[NSIndexSet indexSetWithIndex:newSelectedRow] byExtendingSelection:NO];
            }
            else
            {
                //give up - might be that the last message in the list was deleted
            }
        }
    }
}

- (NSObject*)messageObjectForIndex:(NSInteger)index
{
    //if(APPDELEGATE.foldersInPullToRefreshUpdate.count>0)
    //    index--;

    return [EmailMessageController messageObjectAtIndex:index];

//    NSArray* filteredMessages = APPDELEGATE.filteredMessages;
//
//        if(index>=0 && index<[filteredMessages count])
//        {
//            return [filteredMessages objectAtIndex:index];
//        }
//        return nil;
}

- (NSAttributedString*)previewStringForMessageInstance:(EmailMessageInstance*)messageInstance
{
    if(!messageInstance)
        return [NSAttributedString new];

    NSMutableAttributedString* previewString = [NSMutableAttributedString new];

    //show the UID (only in the exclusive preview version)
#if ULTIMATE

    if([CustomerManager isExclusiveVersion])
    {
        NSString* uidString = messageInstance.uid.stringValue;

        if(uidString)
        {
            [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:uidString attributes:@{}]];
            [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{}]];
        }
        
        [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"(%ld) ", messageInstance.message.instances.count]]];
    }

#endif

    if(messageInstance.inFolder && (![messageInstance.inFolder isKindOfClass:[GmailLabelSetting class]] || ![(GmailLabelSetting*)messageInstance.inFolder allMailForAccount]))
    {
        if(messageInstance.inFolder.displayName)
            [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:messageInstance.inFolder.displayName attributes:@{}]];
        [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{}]];
        //[previewString appendString:displayedMessage.inFolder.displayName];
        //[previewString appendString:@" "];
    }

    for(GmailLabelSetting* labelSetting in [messageInstance.hasLabels sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"displayName" ascending:YES]]])
    {
        if(labelSetting.displayName)
            [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:labelSetting.displayName attributes:@{}]];
        [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{}]];
    }
    /*NSString* shortenedBodyString = displayedMessage.body?displayedMessage.body:@"";
     if(shortenedBodyString.length>500)
     shortenedBodyString = [shortenedBodyString substringToIndex:500];
     [previewString appendAttributedString:[[NSAttributedString alloc] initWithString:shortenedBodyString attributes:@{NSForegroundColorAttributeName:[NSColor secondarySelectedControlColor]}]];*/

    return previewString;
}


- (NSString*)stringForDate:(NSDate*)date
{
    if(!date || [date timeIntervalSince1970]<1)
        return NSLocalizedString(@"No date", @"Message list empty date placeholder");
    NSCalendar *cal = [NSCalendar currentCalendar];
    NSDateComponents *components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:components];
    components = [cal components:(NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit) fromDate:date];
    NSDate *otherDate = [cal dateFromComponents:components];
    
    if([otherDate isEqualToDate:today]) //today, so return something like "Today 9:30am"
    {
        return [NSString stringWithFormat:NSLocalizedString(@"Today %@",@"Date <some date>"),[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
    }
    /*if([otherDate isEqualToDate:[today dateByAddingTimeInterval:-24*60*60]]) //yesterday. return "Yesterday 10:46pm"
     {
     return [NSString stringWithFormat:@"Yesterday %@",[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
     }*/
    if([date compare:[today dateByAddingTimeInterval:-5*24*60*60]]==NSOrderedDescending) //this week, so return "Wed 9:23pm"
    {
        NSDateComponents *weekdayComponents =[cal components:NSWeekdayCalendarUnit fromDate:date];
        
        NSInteger weekday = [weekdayComponents weekday];
        NSString* weekdayString = @"";
        switch(weekday)
        {
            case 1: weekdayString = NSLocalizedString(@"Sun",@"Sunday short");
                break;
            case 2: weekdayString = NSLocalizedString(@"Mon",@"Monday short");
                break;
            case 3: weekdayString = NSLocalizedString(@"Tue",@"Tuesday short");
                break;
            case 4: weekdayString = NSLocalizedString(@"Wed",@"Wednesday short");
                break;
            case 5: weekdayString = NSLocalizedString(@"Thu",@"Thursday short");
                break;
            case 6: weekdayString = NSLocalizedString(@"Fri",@"Friday short");
                break;
            case 7: weekdayString = NSLocalizedString(@"Sat",@"Saturday short");
                break;
        }
        return [NSString stringWithFormat:@"%@ %@",weekdayString,[NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterShortStyle]];
        
    }
    if([date timeIntervalSinceNow]<-365*24*60*60)
        return [[SelectionAndFilterHelper sharedInstance].messageOldDateFormatter stringFromDate:date];

    return [[SelectionAndFilterHelper sharedInstance].messageDateFormatter stringFromDate:date];
}

- (NSAttributedString*)attributedFromToString:(NSData*)addressData
{
    NSMutableAttributedString* toStr = [NSMutableAttributedString new];
    if(addressData.length>0)
    {
        NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:addressData];
        NSArray* recordsArray = [unarchiver decodeObjectForKey:@"recipients"];
        //NSString* fromStr = [NSString new];
        //NSString* toolTip = [NSString new];
        EmailRecipient* from = nil;
        if(recordsArray.count>0)
        {
            EmailRecipient* replyTo;
            for(EmailRecipient* rec in recordsArray)
            {
                switch(rec.type)
                {
                    case TYPE_FROM:
                        from = rec;
                        break;
                    case TYPE_REPLY_TO:
                        replyTo = rec;
                        break;
                    case TYPE_TO:
                    case TYPE_CC:
                    case TYPE_BCC:
                        if(toStr.length>0)
                            [toStr appendAttributedString:[[NSAttributedString alloc] initWithString:@", "]];
                        [toStr appendAttributedString:[rec attributedDisplayStringWithType:NO isNominative:NO]];
                        break;
                }
            }
            if(!from)
            {
                from = replyTo;
            }
        }
        if(from && toStr)
        {
            NSMutableAttributedString* fromToStr = [[NSMutableAttributedString alloc] initWithAttributedString:[from attributedDisplayStringWithType:NO isNominative:YES]];
            NSFont* system13 = [NSFont systemFontOfSize:13];

            NSString* toString = NSLocalizedString(@" to ",@"Email send from XY <to> YZ");

            if(!toString)
                toString = @" to ";

            [fromToStr appendAttributedString:[[NSAttributedString alloc] initWithString:toString attributes:@{NSFontAttributeName:system13}]];
            [fromToStr appendAttributedString:toStr];
            return fromToStr;
        }
    }
    return [[NSAttributedString alloc] initWithString:@""];
}


- (IBAction)doubleClick:(id)sender
{
    NSInteger row = [APPDELEGATE.messagesTable clickedRow];

    NSObject* messageObject = [self messageObjectForIndex:row];
    if([messageObject isKindOfClass:[EmailMessageInstance class]])
    {
        if([(EmailMessageInstance*)messageObject isInDraftsFolder])
            [WindowManager openDraftMessageInstanceInWindow:(EmailMessageInstance*)messageObject];
        else
            [WindowManager openMessageInstanceInWindow:(EmailMessageInstance*)messageObject];
    }
    else if([messageObject isKindOfClass:[EmailMessage class]])
    {

    }
    else
        NSLog(@"No message to open!!!");
}

- (IBAction)deleteSelectedMessages:(id)sender
{
    [APPDELEGATE deleteSelectedMessages:sender];
}



@end
