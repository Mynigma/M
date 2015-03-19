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





#import "AppDelegate.h"
#import <CoreData/CoreData.h>
#import "ContactsController.h"
#import "ContactCell.h"
#import "Contact.h"
#import "ABContactDetail.h"
#import <AddressBook/AddressBook.h>


#define extendedAlphabetArray @[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#"]

@interface ContactsController ()

@end

@implementation ContactsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:@"refreshTable" object:nil];
	// Do any additional setup after loading the view, typically from a nib.
    contactsData = [NSMutableDictionary new];
    if(ABPersonGetSortOrdering()==kABPersonSortByFirstName)
    {
    for(Contact* contact in APPDELEGATE.contacts.fetchedObjects)
    {
        NSString* firstLetter = [[contact.addressBookContact.firstName substringToIndex:1] uppercaseString];
    if([@[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z"] containsObject:firstLetter])
        {
            NSMutableArray* contactsBeginningWithThisLetter = [contactsData objectForKey:firstLetter];
            if(!contactsBeginningWithThisLetter)
                contactsBeginningWithThisLetter = [NSMutableArray new];
            [contactsBeginningWithThisLetter addObject:contact];
            [contactsBeginningWithThisLetter sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateLastContacted" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.firstName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.lastName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];
            [contactsData setObject:contactsBeginningWithThisLetter forKey:firstLetter];
        }
        else
        {
            NSMutableArray* contactsBeginningWithThisLetter = [contactsData objectForKey:@"#"];
            if(!contactsBeginningWithThisLetter)
                contactsBeginningWithThisLetter = [NSMutableArray new];
            [contactsBeginningWithThisLetter addObject:contact];
            [contactsBeginningWithThisLetter sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateLastContacted" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.firstName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.lastName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];
            [contactsData setObject:contactsBeginningWithThisLetter forKey:@"#"];
        }
    }
    }
    else
    {
        for(Contact* contact in APPDELEGATE.contacts.fetchedObjects)
        {
        NSString* firstLetter = [[contact.addressBookContact.lastName substringToIndex:1] uppercaseString];
        if([@[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z"] containsObject:firstLetter])
        {
            NSMutableArray* contactsBeginningWithThisLetter = [contactsData objectForKey:firstLetter];
            if(!contactsBeginningWithThisLetter)
                contactsBeginningWithThisLetter = [NSMutableArray new];
            [contactsBeginningWithThisLetter addObject:contact];
            [contactsBeginningWithThisLetter sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateLastContacted" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.lastName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.firstName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];
            [contactsData setObject:contactsBeginningWithThisLetter forKey:firstLetter];
        }
        else
        {
            NSMutableArray* contactsBeginningWithThisLetter = [contactsData objectForKey:@"#"];
            if(!contactsBeginningWithThisLetter)
                contactsBeginningWithThisLetter = [NSMutableArray new];
            [contactsBeginningWithThisLetter addObject:contact];
            [contactsBeginningWithThisLetter sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"dateLastContacted" ascending:NO],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.lastName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.firstName" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"addressBookContact.uid" ascending:YES]]];
            [contactsData setObject:contactsBeginningWithThisLetter forKey:@"#"];
        }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    showMore = NO;
}

- (void)refreshTable
{
    [contactsTable reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return @[@"🕙",@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#",@"🔎"];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{    
    return index;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section==0)
        return @"Recent";
    if(section==28)
        return @"Search";
    return [extendedAlphabetArray objectAtIndex:section-1];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactCell* cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    if(indexPath.section==0)
    {
        if(!showMore && indexPath.row==12)
            return [tableView dequeueReusableCellWithIdentifier:@"ShowMoreCell"];
            
        if(indexPath.row<APPDELEGATE.recentContacts.fetchedObjects.count)
        {
            Contact* contact = APPDELEGATE.recentContacts.fetchedObjects[indexPath.row];
            ABContactDetail* contactDetail = contact.addressBookContact;
            NSMutableAttributedString* name = [NSMutableAttributedString new];
            const CGFloat fontSize = 21;
            UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
            UIFont *regularFont = [UIFont systemFontOfSize:fontSize];
            if(ABPersonGetSortOrdering()==kABPersonSortByFirstName)
            {
                if(contactDetail.firstName)
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.firstName attributes:@{NSFontAttributeName:boldFont}]];
                else
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];
                [name appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{}]];
                if(contactDetail.lastName)
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.lastName attributes:@{NSFontAttributeName:regularFont}]];
                else
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];
            }
            else
            {
                if(contactDetail.firstName)
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.firstName attributes:@{NSFontAttributeName:regularFont}]];
                else
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];
                [name appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{}]];
                if(contactDetail.lastName)
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.lastName attributes:@{NSFontAttributeName:boldFont}]];
                else
                    [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];
            }
            [cell.nameField setAttributedText:name];
            [cell.imageView setImage:[MODEL profilePicOfContact:contact]];
        }
        return cell;
    }

    NSArray* contactsList = [contactsData objectForKey:[extendedAlphabetArray objectAtIndex:indexPath.section-1]];
    if(indexPath.row<contactsList.count)
    {
    Contact* contact = contactsList[indexPath.row];
    ABContactDetail* contactDetail = contact.addressBookContact;
    NSMutableAttributedString* name = [NSMutableAttributedString new];
    const CGFloat fontSize = 21;
    UIFont *boldFont = [UIFont boldSystemFontOfSize:fontSize];
    UIFont *regularFont = [UIFont systemFontOfSize:fontSize];
    if(ABPersonGetSortOrdering()==kABPersonSortByFirstName)
    {
        if(contactDetail.firstName)
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.firstName attributes:@{NSFontAttributeName:boldFont}]];
        else
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];
        [name appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{}]];
        if(contactDetail.lastName)
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.lastName attributes:@{NSFontAttributeName:regularFont}]];
        else
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];
    }
    else
    {
        if(contactDetail.firstName)
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.firstName attributes:@{NSFontAttributeName:regularFont}]];
        else
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];        
        [name appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:@{}]];
        if(contactDetail.lastName)
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:contactDetail.lastName attributes:@{NSFontAttributeName:boldFont}]];
        else
            [name appendAttributedString:[[NSAttributedString alloc] initWithString:@"*" attributes:@{}]];
    }
    [cell.nameField setAttributedText:name];
    [cell.imageView setImage:[UIImage imageWithData:contactDetail.image]];
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch(section)
    {
        case 0: if(showMore)
            return APPDELEGATE.recentContacts.fetchedObjects.count>50?50:APPDELEGATE.recentContacts.fetchedObjects.count;
                else
                    return APPDELEGATE.recentContacts.fetchedObjects.count>13?13:APPDELEGATE.recentContacts.fetchedObjects.count;
        case 28: return 0;
    }
    NSArray* contactsList = [contactsData objectForKey:[extendedAlphabetArray objectAtIndex:section-1]];
    if(contactsList)
        return contactsList.count;
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 29;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [MODEL.storeObjectContext performBlock:^{

            UITabBarController* tabBarController = self.tabBarController;
            if(tabBarController)
            {
                [tabBarController setSelectedIndex:2];
            }
    }];
    
    return nil;
}


- (IBAction)showMoreButton:(id)sender
{
    showMore = YES;
    [self.tableView reloadData];
}


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    //the sections shouldn't change
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;

        default:
            break;
    }
}


- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
   
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath]
                    atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}


@end
