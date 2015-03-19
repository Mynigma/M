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





#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class EmailRecipient, Recipient, EmailContactDetail;

@interface ContactSuggestions : NSObject <NSFetchedResultsControllerDelegate>
{
    NSMutableDictionary* suggestionsDict;
    NSArray* priorityList;
    NSMutableDictionary* priorityDict;
}

@property NSFetchedResultsController* emailAddressesController;

- (void)initialFetchDone;

- (NSString*)getSuggestionForPartialString:(NSString*)partialString;

- (NSManagedObjectID*)suggestionObjectIDforPartialString:(NSString*)partialString;

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller;
- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;
- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type;
- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller;

- (EmailRecipient*)emailRecipientForString:(NSString*)string;
- (Recipient*)recipientForString:(NSString*)string;
- (NSArray*)contactObjectIDsForPartialString:(NSString*)passedString maxNumber:(NSInteger)maxNumber;

- (void)addEmailContactDetailToSuggestions:(EmailContactDetail*)contactDetail;

@end
