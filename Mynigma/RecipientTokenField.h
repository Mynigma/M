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





#import <Cocoa/Cocoa.h>
#import "MacTokenField.h"

@class Recipient, RecipientTokenField;

@protocol RecipientDelegate
@optional
- (void)recipientTokenField:(RecipientTokenField*)tokenField addedRecipient:(Recipient*)recipient;
- (void)recipientTokenField:(RecipientTokenField*)tokenField removedRecipient:(Recipient*)recipient;
@end


@interface RecipientTokenField : MacTokenField <MacTokenFieldDelegate>

@property (weak) IBOutlet id<NSObject,RecipientDelegate> recipientDelegate;

@property BOOL useSenderAddressesForMenu;

@property NSInteger type;

@property NSMutableDictionary* lastEmailAddressesQueries;

- (MacToken*)tokenForStringComponent:(NSString*)stringComponent insertAtIndex:(NSInteger)insertionIndex;

- (NSColor*)tintColourForToken:(MacToken*)token;
- (NSColor*)highlightTintColourForToken:(MacToken*)token;

- (BOOL)tokenField:(MacTokenField *)tokenField willAddToken:(MacToken *)token;
- (void)tokenField:(MacTokenField *)tokenField didAddToken:(MacToken *)token;
- (BOOL)tokenField:(MacTokenField *)tokenField willRemoveToken:(MacToken *)token;
- (void)tokenField:(MacTokenField *)tokenField didRemoveToken:(MacToken *)token;

- (NSArray*)recipients;

- (void)addRecipients:(NSArray*)recipients filterByType:(BOOL)filter;

- (void)removeAllRecipients;

- (void)setRecipients:(NSArray*)recipients filterByType:(BOOL)filter;

- (NSRect)boundsOfToken:(MacToken*)token;

- (NSRect)boundsOfTokenWithRecipient:(Recipient*)recipient;

- (void)updateTintColours;

@end
