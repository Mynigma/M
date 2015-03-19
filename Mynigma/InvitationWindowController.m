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





#import "InvitationWindowController.h"
#import "AppDelegate.h"
#import "InvitationStyleView.h"
#import "InvitationContactView.h"
#import "ABContactDetail+Category.h"
#import "EmailContactDetail+Category.h"
#import "Contact+Category.h"
#import "EmailRecipient.h"
#import "Recipient.h"
#import "MultipleSelectionRowView.h"
#import "WindowManager.h"



static BOOL isReloadingContactView;


@interface InvitationWindowController ()

@end

@implementation InvitationWindowController

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

    [self setSelectedContacts:[NSMutableArray new]];

    [self setFilterPredicate:[NSPredicate predicateWithValue:YES]];

    NSMutableArray* newDataSet = [NSMutableArray new];

    [newDataSet addObject:@{@"name":NSLocalizedString(@"Concise",@"Invitation style heading"), @"detail":NSLocalizedString(@"Brief explanation in simple terms",@"Invitation style detail"), @"image":@"conciseStyle", @"id":@"conciseStyle"}];

    [newDataSet addObject:@{@"name":NSLocalizedString(@"Detailed",@"Invitation style heading"), @"detail":NSLocalizedString(@"Longer, more precise explanation",@"Invitation style detail"), @"image":@"detailStyle", @"id":@"normalStyle"}];

    //[newDataSet addObject:@{@"name":@"Emtpy", @"detail":@"Write your own", @"image":@"emptyStyle", @"id":@"emptyStyle"}];

    //[newDataSet addObject:@{@"name":@"Twitter", @"detail":@"Summed up in 140 characters", @"image":@"twitterStyle", @"id":@"twitterStyle"}];

    [newDataSet addObject:@{@"name":NSLocalizedString(@"Overly secure",@"Invitation style heading"), @"detail":NSLocalizedString(@"Decipher challenge",@"Invitation style detail"), @"image":@"tooSecureStyle", @"id":@"tooSecureStyle"}];

    [newDataSet addObject:@{@"name":NSLocalizedString(@"BuzzFeed",@"Invitation style heading"), @"detail":NSLocalizedString(@"Sensationalist click bait style",@"Invitation style detail"), @"image":@"buzzfeedStyle", @"id":@"buzzfeedStyle"}];

    [self setStylesDataSet:newDataSet];

    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"EmailContactDetail"];

    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"address != nil AND address != ''"]];

    NSArray* sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"hasUsedMac" ascending:NO], [NSSortDescriptor sortDescriptorWithKey:@"address" ascending:YES]];

    [fetchRequest setSortDescriptors:sortDescriptors];

    NSError* error = nil;

    self.allEmails = [MAIN_CONTEXT executeFetchRequest:fetchRequest error:&error];

    //NSPredicate* hasContactPredicate = [NSPredicate predicateWithFormat:@"((ANY linkedToContact.hasMynigma == nil) OR (ANY linkedToContact.hasMynigma == NO)) AND (ANY linkedToContact != nil)"];
    
    [self setShownContacts:[self.allEmails mutableCopy]];

    [self updateContactSelectionFeedback];

    [self.styleTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];

}

- (void)awakeFromNib
{
    [super awakeFromNib];
}


- (void)selectEmailRecipient:(EmailRecipient*)emailRecipient
{
    EmailContactDetail* contactDetail = [EmailContactDetail emailContactDetailForAddress:emailRecipient.email];

    if(contactDetail)
        [self setSelectedContacts:[@[contactDetail] mutableCopy]];
    else
        [self setSelectedContacts:[NSMutableArray new]];

    [self refreshContactsList];

    [self updateContactSelectionFeedback];
}



- (IBAction)nextButton:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];

    NSMutableArray* selectedRecipients = [NSMutableArray new];

    for(EmailContactDetail* contactDetail in self.selectedContacts)
    {
        if([contactDetail isKindOfClass:[EmailContactDetail class]])
        {
            Recipient* recipient = [[Recipient alloc] initWithEmailContactDetail:contactDetail];

            [recipient setType:TYPE_TO];

            [selectedRecipients addObject:recipient];
        }
    }

    NSInteger styleIndex = [self.styleTableView selectedRow];

    NSString* styleString = nil;

    if(styleIndex >= 0 && styleIndex < self.stylesDataSet.count)
    {
        styleString = [self.stylesDataSet[styleIndex] objectForKey:@"id"];
    }

    [WindowManager showInvitationMessageForRecipients:selectedRecipients style:styleString];
}

- (IBAction)cancelButton:(id)sender
{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:self];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView.tag == 113)
    {
        return self.stylesDataSet.count;
    }

    if(tableView.tag == 114)
    {
        return self.shownContacts.count;
    }

    return 0;
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row
{
    MultipleSelectionRowView* rowView = [MultipleSelectionRowView new];

    if(tableView.tag==113)
    {
        [rowView setUseRoundedRect:NO];
    }
    else
        [rowView setUseRoundedRect:YES];

    return rowView;
}

- (NSView*)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView.tag == 113)
    {
        InvitationStyleView* tableCellView = (InvitationStyleView*)[tableView makeViewWithIdentifier:@"styleCellView" owner:self];

        if(row<self.stylesDataSet.count && [tableCellView isKindOfClass:[InvitationStyleView class]])
        {
            NSDictionary* dataDict = [self.stylesDataSet objectAtIndex:row];

            NSString* name = [dataDict objectForKey:@"name"];

            if(name)
            {
                [tableCellView.textField setStringValue:name];
            }

            NSString* detail = [dataDict objectForKey:@"detail"];

            if(detail)
            {
                [tableCellView.detailField setStringValue:detail];
            }
            
            NSString* imageName = [dataDict objectForKey:@"image"];

            NSURL* imageURL = [BUNDLE URLForImageResource:imageName];

            NSImage* image = [[NSImage alloc] initWithData:[NSData dataWithContentsOfURL:imageURL]];

            if(image)
            {
                [tableCellView.imageView setImage:image];
            }
        }

        return tableCellView;
    }
    if(tableView.tag == 114 && row < self.shownContacts.count)
    {
        InvitationContactView* tableCellView = (InvitationContactView*)[tableView makeViewWithIdentifier:@"contactCellView" owner:self];

        EmailContactDetail* emailDetail = [self.shownContacts objectAtIndex:row];

        Contact* contact = [emailDetail mostFrequentContact];

        NSString* firstName = contact.addressBookContact.firstName;
        NSString* lastName = contact.addressBookContact.lastName;

        NSString* topString = nil;
        NSString* bottomString = nil;

        NSString* address = emailDetail.address;

        if(!address)
            address = @"";

        if(firstName || lastName)
        {
        if(firstName && lastName)
            topString = [NSString stringWithFormat:@"%@ %@",firstName,lastName];
        else if(firstName)
            topString = firstName;
        else if(lastName)
            topString = lastName;

            bottomString = address;
        }
        else
        {
            topString = address;

            bottomString = @"";
        }

        [tableCellView.textField setStringValue:topString];

        [tableCellView.emailField setStringValue:bottomString];

        if(emailDetail.hasUsedMac.boolValue)
        {
            [tableCellView.hasUsedMynigmaField setHidden:NO];
        }
        else
        {
            [tableCellView.hasUsedMynigmaField setHidden:YES];
        }

        if([contact haveProfilePic])
        {
            NSImage* image = [contact profilePic];
            [tableCellView.imageConstraint setPriority:1];
            [tableCellView.imageView setImage:image];
        }
        else
        {
            [tableCellView.imageConstraint setPriority:999];
            [tableCellView.imageView setImage:nil];
        }

        if([self.selectedContacts containsObject:emailDetail])
        {
            [tableCellView.pickBox setState:NSOnState];
        }
        else
        {
            [tableCellView.pickBox setState:NSOffState];
        }

        return tableCellView;
    }

    return nil;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if(tableView.tag == 114 && row < self.shownContacts.count)
    {
        EmailContactDetail* emailDetail = [self.shownContacts objectAtIndex:row];

        CGFloat baseHeight = 32;

        Contact* contact = emailDetail.mostFrequentContact;

        NSString* firstName = contact.addressBookContact.firstName;
        NSString* lastName = contact.addressBookContact.lastName;

        if(firstName || lastName)
        {
            baseHeight += 20;
        }

        if(emailDetail.hasUsedMac.boolValue)
        {
            baseHeight += 12;
        }

        return baseHeight;
    }

    return 56;
}


- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([notification.object isKindOfClass:[NSTableView class]] && [notification.object tag]==114)
    {
        //the selection change is due to a reload of table data, not user action...
        if(isReloadingContactView)
            return;


        //add any newly selected addresses to the list of selected contacts
        NSIndexSet* selectedRows = [self.contactTableView selectedRowIndexes];

        NSMutableSet* selectedDisplayedObjects = [NSMutableSet new];

        NSInteger index = selectedRows.firstIndex;

        while(index != NSNotFound)
        {
            if(index < self.shownContacts.count)
            {
                EmailContactDetail* contactDetail = [self.shownContacts objectAtIndex:index];

                if([contactDetail isKindOfClass:[EmailContactDetail class]])
                {
                    if(![self.selectedContacts containsObject:contactDetail])
                    {
                        [self.selectedContacts addObject:contactDetail];
                        [self.contactTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:index] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
                    }

                    [selectedDisplayedObjects addObject:contactDetail];
                }
            }
            else
            {
                NSLog(@"Index error in contact selection!!!");
            }

            index = [selectedRows indexGreaterThanIndex:index];
        }

        //now check if any previously selected addresses have been deselected
        NSMutableArray* newSelectedContacts = [self.selectedContacts mutableCopy];

        NSMutableIndexSet* indexesToBeRefreshed = [NSMutableIndexSet new];

        for(EmailContactDetail* contactDetail in self.selectedContacts)
        {
            NSInteger index = [self.shownContacts indexOfObject:contactDetail];
            if(index >= 0 && index != NSNotFound)
            {
                //ok, it is displayed

                if(![selectedDisplayedObjects containsObject:contactDetail])
                {
                    [newSelectedContacts removeObject:contactDetail];
                    [indexesToBeRefreshed addIndex:index];
                }
            }
        }

        [self setSelectedContacts:newSelectedContacts];

        [self.contactTableView reloadDataForRowIndexes:indexesToBeRefreshed columnIndexes:[NSIndexSet indexSetWithIndex:0]];

        [self updateContactSelectionFeedback];
    }
}

- (void)updateContactSelectionFeedback
{
    NSInteger selectedContactsCount = self.selectedContacts.count;

    NSString* feedbackString = nil;

    if(selectedContactsCount == 0)
    {
        feedbackString = [NSString stringWithFormat:NSLocalizedString(@"No contacts selected", @"Invitation dialogue")];
    }
    else if(selectedContactsCount == 1)
    {
        feedbackString = [NSString stringWithFormat:NSLocalizedString(@"One contact selected", @"Invitation dialogue")];
    }
    else
    {
        feedbackString = [NSString stringWithFormat:NSLocalizedString(@"%ld contacts selected", @"Invitation dialogue"), selectedContactsCount];
    }

    [self.contactSelectionFeedbackField setStringValue:feedbackString];

    [self.nextButton setEnabled:selectedContactsCount>0];
}

- (NSIndexSet*)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    if(tableView.tag == 113)
    {
        if(proposedSelectionIndexes.count == 0 && self.stylesDataSet.count > 0)
        {
            return [NSIndexSet indexSetWithIndex:0];
        }
    }

    return proposedSelectionIndexes;
}

- (void)controlTextDidChange:(NSNotification *)obj
{
    NSTextField* textField = obj.object;
    if([textField isKindOfClass:[NSTextField class]])
    {
        NSString* searchTerm = textField.stringValue;

        if(searchTerm.length == 0)
            [self setFilterPredicate:[NSPredicate predicateWithValue:YES]];
        else
        {
        //reset the filter predicate

        NSPredicate* newFilterPredicate = [NSPredicate predicateWithFormat:@"(address CONTAINS[cd] %@) OR (ANY linkedToContact.addressBookContact.firstName CONTAINS[cd] %@) OR (ANY linkedToContact.addressBookContact.lastName CONTAINS[cd] %@)", searchTerm.copy, searchTerm.copy, searchTerm.copy];

        [self setFilterPredicate:newFilterPredicate];
        }
        
        [self refreshContactsList];
    }
}

- (void)refreshContactsList
{
    if(self.filterPredicate && self.allEmails)
    {
        self.shownContacts = [[self.allEmails filteredArrayUsingPredicate:self.filterPredicate] mutableCopy];

        //this will temporarily disable the selection change delegate method, so that the loss of selection is not mistaken for a user-driven deselection
        isReloadingContactView = YES;

        [self.contactTableView reloadData];

        NSMutableIndexSet* indexesToBeSelected = [NSMutableIndexSet new];

        for(EmailContactDetail* contactDetail in self.selectedContacts)
        {
            NSInteger index = [self.shownContacts indexOfObject:contactDetail];
            if(index >= 0 && index != NSNotFound)
            {
                //ok, it is displayed

                [indexesToBeSelected addIndex:index];
            }
        }

        [self.contactTableView selectRowIndexes:indexesToBeSelected byExtendingSelection:NO];

        isReloadingContactView = NO;
    }
}


@end
