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
@class NSManagedObjectID;

@class MessageCell, EmailMessageInstance;

@interface MessagesController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
{
    NSDateFormatter* dateFormatter;
    NSDateFormatter* timeFormatter;
    IBOutlet UIToolbar* toolBar;
        
    UIButton* pressedButton;
    NSInteger numberOfRows;
    
    NSInteger numberOfMessagesToBeDisplayed;
}



#pragma mark - IBOutlets & views

@property IBOutlet UIBarButtonItem* composeNewButton;
@property UIRefreshControl* refreshControl;
@property IBOutlet UITableView* tableView;
@property IBOutlet UISearchBar* searchBar;



#pragma mark - Menu buttons

- (IBAction)menuButtonPressed:(id)sender;
- (IBAction)rightActionButtonPressed:(id)sender;



#pragma mark - Filtering

- (void)updateFiltersWithObject:(NSManagedObject*)object;



#pragma mark - Refreshing

- (void)refreshLoadMoreCell;
- (void)refreshMessage:(NSManagedObjectID*)messageID;
- (void)refreshMessageInstance:(NSManagedObjectID*)messageID;
- (void)configureCell:(MessageCell*)cell atIndexPath:(NSIndexPath*)indexPath;





#pragma mark - Managing compose new button

- (void)removeComposeNewButton;
- (void)addComposeNewButton;



#pragma mark - Managing selection

- (void)selectMessageInstances:(NSArray*)messageInstances;


- (BOOL)moveUpInMessagesList;
- (BOOL)moveDownInMessagesList;




#pragma mark - Search bar

- (void)setSearchBarShown:(BOOL)shown animated:(BOOL)animated;

@property IBOutlet NSLayoutConstraint* hideSearchBarContraint;


@end
