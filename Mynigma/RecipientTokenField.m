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





#import "RecipientTokenField.h"

#import "AppDelegate.h"
#import "EmailContactDetail+Category.h"
#import "ABContactDetail+Category.h"
#import "Contact+Category.h"
#import "Recipient.h"
#import "AddressDataHelper.h"
#import "IconListAndColourHelper.h"
#import "IMAPAccountSetting+Category.h"
#import "UserSettings+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "ContactCompletionHelper.h"
#import "WindowManager.h"





@implementation RecipientTokenField

@synthesize lastEmailAddressesQueries;


- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setUseSenderAddressesForMenu:NO];
    [self setDelegate:self];
}

- (void)dealloc
{
    [self setDelegate:nil];
}

- (MacToken*)tokenForStringComponent:(NSString*)stringComponent insertAtIndex:(NSInteger)insertionIndex
{
    //the editing string could be an email, a name or a string of the form "Name<email@provider.com>"

    Recipient* objectValue = nil;

    NSString* email = nil;
    NSString* name = stringComponent;

    NSString* editingString = stringComponent;

    //check if it's a valid email address
    if([AddressDataHelper isValidEmailAddress:editingString])
    { //yes, it's a valid email
        email = [editingString lowercaseString];
    }
    else
    { //not an email
      //check if it's "Name<email@provider.com>"

        NSInteger openBracketLocation = [editingString rangeOfString:@"<"].location;
        NSInteger closeBracketLocation = [editingString rangeOfString:@">"].location;
        if(openBracketLocation!=NSNotFound && closeBracketLocation!=NSNotFound)
        {
            name = [[editingString substringToIndex:openBracketLocation] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            if(openBracketLocation+1<closeBracketLocation)
            {
                email = [[editingString substringWithRange:NSMakeRange(openBracketLocation+1, closeBracketLocation-openBracketLocation-1)] lowercaseString];
                if(![AddressDataHelper isValidEmailAddress:email])
                { //email is actually invalid, so reset
                    name = editingString;
                    email = nil;
                }
            }
        }
    }

    if(!email)
    { //must be a name
        NSManagedObjectID* contactID = [[ABContactDetail allContactsDict] objectForKey:editingString];
        if(contactID)
        {
            ABContactDetail* abContact = (ABContactDetail*)[MAIN_CONTEXT objectWithID:contactID];
            if(abContact && [abContact isKindOfClass:[ABContactDetail class]] && abContact.linkedToContact)
            {
                objectValue = [[Recipient alloc] initWithContact:abContact.linkedToContact];
            }
        }
    }
    else
    {
        NSManagedObjectID* emailDetailID = [[EmailContactDetail allAddressesDict] objectForKey:email];
        if(emailDetailID && [emailDetailID isKindOfClass:[NSManagedObjectID class]])
        {
            NSError* error = nil;
            EmailContactDetail* emailDetail = (EmailContactDetail*)[MAIN_CONTEXT existingObjectWithID:emailDetailID error:&error];
            if(emailDetail && !error)
            {
                Recipient* newRecipient = [[Recipient alloc] initWithEmailContactDetail:emailDetail];
                objectValue = newRecipient;
            }
            else
            {
                NSLog(@"Could not find email contact detail in main context: %@, error: %@",emailDetailID,error);
                Recipient* newRecipient = [[Recipient alloc] initWithEmail:email andName:name];
                objectValue = newRecipient;
            }
        }
        else
        { //the email is unknown

        }

        if(!objectValue)
            objectValue = [[Recipient alloc] initWithEmail:email andName:name?name:email];
    }

    if(objectValue)
    {
        MacToken* newToken = [self addTokenWithTitle:objectValue.displayName representedObject:objectValue insertAtIndex:insertionIndex];

        return newToken;
    }
    return nil;
}

//TO DO: use ContactCompletionHelper instead
- (NSArray *)completionsForPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index
{
    NSMutableArray* result = [NSMutableArray new];

    NSString* substring = [self.string substringWithRange:charRange];

    NSDictionary* allAddressesDict = [EmailContactDetail allAddressesDict];

    if (lastEmailAddressesQueries == nil)
    {
        lastEmailAddressesQueries = [NSMutableDictionary new];
    }

    NSArray* allAddressesArr = nil;
    
    if (substring)
        allAddressesArr = [lastEmailAddressesQueries objectForKey:substring];
    
    if (!allAddressesArr)
        allAddressesArr = allAddressesDict.allKeys;
    
    
    NSDictionary* allContactsDict = [ABContactDetail allContactsDict];

    for(NSString* detailString in allContactsDict.allKeys)
    {
        if(detailString && [[detailString lowercaseString] hasPrefix:[substring lowercaseString]])
        {
            NSManagedObjectID* contactDetailID = allContactsDict[detailString];
            ABContactDetail* contactDetail = (ABContactDetail*)[MAIN_CONTEXT existingObjectWithID:contactDetailID error:nil];
            if([contactDetail isKindOfClass:[ABContactDetail class]] && contactDetail.linkedToContact.emailAddresses.count)
                [result addObject:detailString];
        }
    }
    for(NSString* emailAddress in allAddressesArr)
    {
        if(emailAddress && [[emailAddress lowercaseString] hasPrefix:[substring lowercaseString]])
            [result addObject:emailAddress];
    }

    [result sortUsingComparator:^NSComparisonResult(id string1, id string2)
    {
    BOOL hasMynigma1 = NO;
    BOOL hasMynigma2 = NO;
    NSInteger value1 = 0;
    NSInteger value2 = 0;
    NSManagedObjectID* emailContactDetail1ID = [allAddressesDict objectForKey:string1];
    if([emailContactDetail1ID isKindOfClass:[NSManagedObjectID class]])
    {
        NSError* error = nil;
        EmailContactDetail* emailContactDetail1 = (EmailContactDetail*)[MAIN_CONTEXT existingObjectWithID:emailContactDetail1ID error:&error];
        if(error)
            NSLog(@"Error: %@\nwhile fetching email contact detail with ID: %@",error,emailContactDetail1ID);
        if([emailContactDetail1 isKindOfClass:[EmailContactDetail class]])
        {
            value1 = emailContactDetail1.numberOfTimesContacted.integerValue;
            if([MynigmaPublicKey havePublicKeyForEmailAddress:emailContactDetail1.address])
                hasMynigma1 = YES;
        }
    }
    NSManagedObjectID* emailContactDetail2ID = [allAddressesDict objectForKey:string2];
    if([emailContactDetail2ID isKindOfClass:[NSManagedObjectID class]])
    {
        NSError* error = nil;
        EmailContactDetail* emailContactDetail2 = (EmailContactDetail*)[MAIN_CONTEXT existingObjectWithID:emailContactDetail2ID error:&error];
        if(error)
            NSLog(@"Error: %@\nwhile fetching email contact detail with ID: %@",error,emailContactDetail2ID);
        if([emailContactDetail2 isKindOfClass:[EmailContactDetail class]])
        {
            value2 = emailContactDetail2.numberOfTimesContacted.integerValue;
            if([MynigmaPublicKey havePublicKeyForEmailAddress:emailContactDetail2.address])
                hasMynigma2 = YES;
        }
    }

    NSManagedObjectID* abContactDetailID = [allContactsDict objectForKey:string1];
    if(abContactDetailID)
    {
        NSError* error = nil;
        ABContactDetail* abContactDetail = (ABContactDetail*)[MAIN_CONTEXT existingObjectWithID:abContactDetailID error:&error];
        if(error)
            NSLog(@"Error: %@\nwhile fetching AB contact detail with ID: %@",error,emailContactDetail1ID);
        if(abContactDetail)
        {
            value1 = abContactDetail.linkedToContact.numberOfTimesContacted.integerValue;
            if([abContactDetail.linkedToContact mostFrequentEmail].currentPublicKey)
                hasMynigma1 = YES;
        }
    }

    abContactDetailID = [allContactsDict objectForKey:string2];
    if(abContactDetailID)
    {
        NSError* error = nil;
        ABContactDetail* abContactDetail = (ABContactDetail*)[MAIN_CONTEXT existingObjectWithID:abContactDetailID error:&error];
        if(error)
            NSLog(@"Error: %@\nwhile fetching AB contact detail with ID: %@",error,emailContactDetail1ID);
        if(abContactDetail)
        {
            value2 = abContactDetail.linkedToContact.numberOfTimesContacted.integerValue;
            if([abContactDetail.linkedToContact mostFrequentEmail].currentPublicKey)
                hasMynigma2 = YES;
        }
    }
    if(hasMynigma1 && !hasMynigma2)
        return NSOrderedAscending;
    if(hasMynigma2 && !hasMynigma1)
        return NSOrderedDescending;
    if(value1>value2)
        return NSOrderedAscending;
    if(value1<value2)
        return NSOrderedDescending;
    return [string2 compare:string1];
}];

    if (substring && result)
        [lastEmailAddressesQueries setObject:result forKey:substring];
    
return result;
}

- (NSArray *)textView:(NSTextView *)aTextView writablePasteboardTypesForCell:(id < NSTextAttachmentCell >)cell atIndex:(NSUInteger)charIndex
{
    return @[NSStringPboardType];
}

- (BOOL)textView:(NSTextView *)aTextView writeCell:(id < NSTextAttachmentCell >)cell atIndex:(NSUInteger)charIndex toPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    if([cell isKindOfClass:[MacToken class]])
    {
        Recipient* recipient = [(MacToken*)cell representedObject];
        
        [pboard setString:[recipient longDisplayString] forType:NSStringPboardType];

        return YES;
    }

    return NO;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    NSArray* selectedRanges = [self selectedRanges];

    NSAttributedString* tokenFieldText = self.attributedString;

    NSMutableString* newPasteString = [NSMutableString new];

    for(NSValue* value in selectedRanges)
    {
        NSRange range = value.rangeValue;

        NSInteger startOfRange = range.location;

        for(NSInteger currentLocation = range.location; currentLocation < range.location + range.length; currentLocation++)
        {
            NSAttributedString* characterString = [tokenFieldText attributedSubstringFromRange:NSMakeRange(currentLocation, 1)];

            id attribute = [characterString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
            
            if([attribute isKindOfClass:[NSTextAttachment class]])
            {
                //add the previous string first
                if(currentLocation - 1 > startOfRange)
                {
                    NSRange previousRange = NSMakeRange(startOfRange, currentLocation - startOfRange);

                    NSString* subString = [tokenFieldText attributedSubstringFromRange:previousRange].string;

                    [newPasteString appendString:subString];
                }

                //now add the token
                MacToken* token = (MacToken*)[(NSTextAttachment*)attribute attachmentCell];
                if([token isKindOfClass:[MacToken class]])
                {
                    Recipient* rec = token.representedObject;

                    NSString* longDisplayStringWithComma = [NSString stringWithFormat:@"%@,",[rec longDisplayString]];

                    [newPasteString appendString:longDisplayStringWithComma];
                }

                //reset the start of the new range
                startOfRange = currentLocation + 1;
            }
        }

    }

    [pboard setString:newPasteString forType:NSStringPboardType];

    return YES;
}


-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    if([[sender draggingDestinationWindow] isEqualTo:self.window])
        return NSDragOperationMove;

    return NSDragOperationEvery;


//    NSPasteboard *pb = [sender draggingPasteboard];
//    NSDragOperation dragOperation = [sender draggingSourceOperationMask];
//
//    if ([[pb types] containsObject:NSPasteboardTypeString])
//    {
//        if (dragOperation & NSDragOperationMove)
//        {
//            return NSDragOperationMove;
//        }
//    }
//
//    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender
{
    if([[sender draggingDestinationWindow] isEqualTo:self.window])
        return NSDragOperationMove;

    return NSDragOperationEvery;

//    NSPasteboard *pb = [sender draggingPasteboard];
//    NSDragOperation dragOperation = [sender draggingSourceOperationMask];
//
//    if ([[pb types] containsObject:NSPasteboardTypeString])
//    {
//        if (dragOperation & NSDragOperationMove)
//        {
//            return NSDragOperationMove;
//        }
//    }
//
//    return NSDragOperationNone;
}

- (NSDragOperation)dragOperationForDraggingInfo:(id<NSDraggingInfo>)dragInfo type:(NSString *)type
{
    if([[dragInfo draggingDestinationWindow] isEqualTo:self.window])
        return NSDragOperationMove;

    return NSDragOperationCopy;
}

- (NSDragOperation)draggingSession:(NSDraggingSession *)session sourceOperationMaskForDraggingContext:(NSDraggingContext)context
{
    if(context == NSDraggingContextWithinApplication)
        return NSDragOperationMove;

    return NSDragOperationEvery;
}

- (NSColor*)tintColourForToken:(MacToken*)token
{
    Recipient* recipient = token.representedObject;

    if([recipient isSafeAsNonSender])
    {
        return SAFE_DARK_COLOUR;
    }
    else
    {
        return OPEN_DARK_COLOUR;
    }
}

- (NSColor*)highlightTintColourForToken:(MacToken*)token
{
    Recipient* recipient = token.representedObject;

    if([recipient isSafeAsNonSender])
    {
        return SAFE_SELECTED_COLOUR;
    }
    else
    {
        return OPEN_SELECTED_COLOUR;
    }
}

- (NSMenu *)menuForToken:(MacToken*)token
{
    if(self.useSenderAddressesForMenu)
    {
        NSMenu* menu = [[NSMenu alloc] initWithTitle:@"email selection menu"];

        //first determine which sender address is currently selected
        //we need this for the check mark

        NSArray* fromRecs = [self tokens];

        Recipient* fromRec = nil;

        for(Recipient* rec in fromRecs)
        {
            if([rec isKindOfClass:[Recipient class]])
            {
                fromRec = rec;
                break;
            }

            if([rec isKindOfClass:[MacToken class]])
            {
                Recipient* recipient = [(MacToken*)rec representedObject];

                if([recipient isKindOfClass:[Recipient class]])
                    fromRec = recipient;
                break;
            }
        }

        //now list all possible sender addresses

        IMAPAccountSetting* fromAccountSetting = fromRec.displayEmail?[IMAPAccountSetting accountSettingForSenderEmail:fromRec.displayEmail]:nil;

        for(IMAPAccountSetting* accountSetting in [UserSettings usedAccounts])
        {
            NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:accountSetting.emailAddress action:@selector(setFromEmailAddress:) keyEquivalent:@""];

            [menuItem setRepresentedObject:accountSetting];

            [menuItem setTarget:self];
            [menu addItem:menuItem];

            if([accountSetting isEqual:fromAccountSetting])
                [menuItem setState:NSOnState];
            else
                [menuItem setState:NSOffState];
        }
        return menu;
    }


    if([token.representedObject isKindOfClass:[Recipient class]])
    {
        NSMenu* menu = [[NSMenu alloc] initWithTitle:@"email selection menu"];

        EmailRecipient* emailRecipient = [(Recipient*)token.representedObject emailRecipient];
        if(![MynigmaPublicKey havePublicKeyForEmailAddress:[(Recipient*)token.representedObject displayEmail]])
        {
            NSMenuItem* invitationMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Invite to Mynigma", @"Invitation menu item") action:@selector(inviteToMynigma:) keyEquivalent:@""];

            [invitationMenuItem setTarget:self];
            [invitationMenuItem setRepresentedObject:emailRecipient];

            [menu addItem:invitationMenuItem];

            NSMenuItem* separator = [NSMenuItem separatorItem];

            [menu addItem:separator];
        }

        Recipient* rec = (Recipient*)token.representedObject;
        NSArray* emailContacts = [[rec listPossibleEmailContactDetails] sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"numberOfTimesContacted" ascending:NO]]];
        for(EmailContactDetail* emailDetail in emailContacts)
        {
            NSMenuItem* menuItem = [[NSMenuItem alloc] initWithTitle:emailDetail.address action:@selector(chooseEmailFromMenu:) keyEquivalent:@""];
            [menu addItem:menuItem];
            [menuItem setTarget:rec];
            [menuItem setRepresentedObject:token];
            if([[[rec displayEmail] lowercaseString] isEqualToString:[emailDetail.address lowercaseString]])
                [menuItem setState:NSOnState];
            else
                [menuItem setState:NSOffState];
        }
        return menu;
    }
    return nil;
}

- (IBAction)setFromEmailAddress:(id)sender
{
    IMAPAccountSetting* fromAccountSetting = [sender representedObject];

    Recipient* newRecipient = [[Recipient alloc] initWithEmail:fromAccountSetting.senderEmail andName:fromAccountSetting.senderName];

    [newRecipient setType:TYPE_FROM];

    [self setRecipients:@[newRecipient] filterByType:YES];
}


- (void)chooseEmailFromMenu:(id)sender
{
    NSMenuItem* menuItem = (NSMenuItem*)sender;

    MacToken* token = menuItem.representedObject;

    Recipient* rec = token.representedObject;

    NSArray* possibleEmails = [rec listPossibleEmailContactDetails];

    for(EmailContactDetail* emailDetail in possibleEmails)
        if([[emailDetail.address lowercaseString] isEqualToString:[menuItem.title lowercaseString]])
        {
            [rec setContactDetail:emailDetail];
            break;
        }
}


- (BOOL)tokenField:(MacTokenField *)tokenField willAddToken:(MacToken *)token
{
    Recipient* rec = token.representedObject;

    [rec setType:self.type];

    return YES;
}

- (void)tokenField:(MacTokenField *)tokenField didAddToken:(MacToken *)token
{
    if([self.recipientDelegate respondsToSelector:@selector(recipientTokenField:addedRecipient:)])
    {
        [self.recipientDelegate recipientTokenField:(RecipientTokenField*)tokenField addedRecipient:token.representedObject];
    }
}

- (BOOL)tokenField:(MacTokenField *)tokenField willRemoveToken:(MacToken *)token
{
    return YES;
}

- (void)tokenField:(MacTokenField *)tokenField didRemoveToken:(MacToken *)token
{
    if([self.recipientDelegate respondsToSelector:@selector(recipientTokenField:removedRecipient:)])
    {
        [self.recipientDelegate recipientTokenField:(RecipientTokenField*)tokenField removedRecipient:token.representedObject];
    }
}

- (NSArray*)recipients
{
    NSMutableArray* returnValue = [NSMutableArray new];

    for(MacToken* token in [self tokens])
    {
        if([token.representedObject isKindOfClass:[Recipient class]])
        {
            [returnValue addObject:token.representedObject];
        }
    }

    return returnValue;
}

- (void)addRecipients:(NSArray*)recipients filterByType:(BOOL)filter
{
    for(Recipient* recipient in recipients.reverseObjectEnumerator)
    {
        if(!filter || (recipient.type == self.type))
        {
            //show the name, unless it's the list of sender addresses, in which case show the email address instead...
            NSString* name = recipient.displayName;//self.useSenderAddressesForMenu?recipient.displayEmail:recipient.displayName;

            [self addTokenWithTitle:name representedObject:recipient insertAtIndex:0];
        }
    }
}

- (void)removeAllRecipients
{
    [self removeAllTokens];

    [self setString:@""];

    [self updateHeight];
}

- (void)setRecipients:(NSArray*)recipients filterByType:(BOOL)filter
{
    [self removeAllRecipients];
    [self addRecipients:recipients filterByType:filter];
}

- (NSRect)boundsOfToken:(MacToken *)token
{
    for(NSInteger location = 0; location < self.attributedString.length; location++)
    {
        NSRange range = NSMakeRange(location, 1);

        NSAttributedString* previousCharacter = [self.attributedString attributedSubstringFromRange:range];

        id attribute = [previousCharacter attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];

        if([attribute isKindOfClass:[NSTextAttachment class]])
        {
            //yes, it has a text attachment, so it must be a token
            MacToken* foundToken = (MacToken*)[(NSTextAttachment*)attribute attachmentCell];

            if([foundToken isEqualTo:token])
            {
                NSRect tokenBounds = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(location, 1) inTextContainer: self.textContainer];

                return tokenBounds;
            }
        }
    }

    return NSMakeRect(0, 0, 0, 0);
}

- (NSRect)boundsOfTokenWithRecipient:(Recipient*)recipient
{
    for(NSInteger location = 0; location < self.attributedString.length; location++)
    {
        NSRange range = NSMakeRange(location, 1);

        NSAttributedString* previousCharacter = [self.attributedString attributedSubstringFromRange:range];

        id attribute = [previousCharacter attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];

        if([attribute isKindOfClass:[NSTextAttachment class]])
        {
            //yes, it has a text attachment, so it must be a token
            MacToken* foundToken = (MacToken*)[(NSTextAttachment*)attribute attachmentCell];

            if([foundToken.representedObject isEqualTo:recipient])
            {
                NSRect tokenBounds = [self.layoutManager boundingRectForGlyphRange:NSMakeRange(location, 1) inTextContainer: self.textContainer];

                return tokenBounds;
            }
        }
    }
    
    return NSMakeRect(0, 0, 0, 0);
}

- (void)updateTintColours
{
    for(MacToken* token in self.tokens)
    {
        [token setTintColor:[self tintColourForToken:token]];
    }

    [self setNeedsDisplay:YES];
}


- (IBAction)inviteToMynigma:(id)sender
{
    EmailRecipient* emailRecipient = [(NSMenuItem*)sender representedObject];

    [WindowManager showInvitationMessageForEmailRecipient:emailRecipient];
}

@end
