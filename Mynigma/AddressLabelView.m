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





#import "AddressLabelView.h"
#import "EmailRecipient.h"
#import "IconListAndColourHelper.h"
#import "AddressDataHelper.h"
#import "EmailMessageInstance+Category.h"
#import "EmailContactDetail+Category.h"
#import "Contact+Category.h"
#import "EmailMessage+Category.h"
#import "EmailMessageData.h"
#import "DeviceMessage+Category.h"
#import "MynigmaPublicKey+Category.h"
#import "DeviceMessage+Category.h"
#import "MynigmaDevice+Category.h"
#import "WindowManager.h"


#if ULTIMATE

#import "CustomerManager.h"

#endif

#define TOKENS_OFFSET 0
#define LINE_HEIGHT 22

@implementation AddressLabelView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.isExpanded = NO;
    }
    return self;
}

- (BOOL)isFlipped
{
    return YES;
}

- (IBAction)addressLabelClicked:(id)sender
{
    EmailRecipient* emailRecipient = [[(NSButton*)sender cell] representedObject];

    if([emailRecipient isKindOfClass:[EmailRecipient class]])
    {
        NSMenu* buttonMenu = [self menuForEmailRecipient:emailRecipient];

        [NSMenu popUpContextMenu:buttonMenu withEvent:[NSApp currentEvent] forView:sender];
    }
}

- (NSButton*)newRecipientButtonWithEmailRecipient:(EmailRecipient*)emailRecipient alsoAddComma:(BOOL)addComma
{
    NSButton* newButton = [[NSButton alloc] init];

    NSString* buttonTitle = addComma?[NSString stringWithFormat:@"%@,", emailRecipient.displayString]:emailRecipient.displayString;

    if(!buttonTitle)
        buttonTitle = NSLocalizedString(@"No sender", @"Address label button");

    if(!buttonTitle)
        buttonTitle = @"No sender";

    NSAttributedString* attrTitle = [[NSAttributedString alloc] initWithString:buttonTitle attributes:@{NSForegroundColorAttributeName:[NSColor disabledControlTextColor], NSFontTraitsAttribute:@(NSFontBoldTrait)}];

    [newButton setAttributedTitle:attrTitle];

    [newButton setButtonType:NSMomentaryLight];
    [newButton setBezelStyle:NSRecessedBezelStyle];
    [newButton setShowsBorderOnlyWhileMouseInside:YES];

    [newButton setHidden:NO];

    [newButton setTarget:self];
    [newButton setAction:@selector(addressLabelClicked:)];

    [newButton.cell setRepresentedObject:emailRecipient];

    [newButton sizeToFit];

    return newButton;
}

- (void)setEmailRecipientsForMessage:(EmailMessage*)message
{
    [self setIsExpanded:NO];

    //first remove all subviews
    NSArray* currentSubviews = [self.subviews copy];

    for(NSView* buttonSubview in currentSubviews)
    {
        [buttonSubview removeFromSuperview];
    }

    BOOL isExclusive = NO;

#if ULTIMATE

    isExclusive = [CustomerManager isExclusiveVersion];

#endif

    if(!message.messageData.addressData || ([message isKindOfClass:[DeviceMessage class]] && !isExclusive))
    {
        if(self.senderButton.superview)
        {
            [self.senderButton removeFromSuperview];
            [self setSenderButton:nil];
        }

        if(self.toLabel.superview)
        {
            [self.toLabel removeFromSuperview];
            [self setToLabel:nil];
        }

        return;
    }

    if([message isKindOfClass:[DeviceMessage class]])
    {
        EmailRecipient* fromRecipient = [EmailRecipient new];
        [fromRecipient setName:[(DeviceMessage*)message sender].displayName];
        [fromRecipient setEmail:[(DeviceMessage*)message sender].deviceId];
        [fromRecipient setType:TYPE_FROM];

        NSMutableArray* newRecipientList = [NSMutableArray new];

        [newRecipientList addObject:fromRecipient];

        for(MynigmaDevice* device in [(DeviceMessage*)message targets])
        {
            EmailRecipient* toRecipient = [EmailRecipient new];
            [toRecipient setName:device.displayName];
            [toRecipient setEmail:device.deviceId];
            [toRecipient setType:TYPE_TO];

            [newRecipientList addObject:toRecipient];
        }

        if([(DeviceMessage*)message targets].count == 0)
        {
            EmailRecipient* toRecipient = [EmailRecipient new];
            [toRecipient setName:@"anybody out there"];
            [toRecipient setEmail:@"N/A"];
            [toRecipient setType:TYPE_TO];

            [newRecipientList addObject:toRecipient];
        }

        NSData* newAddressData = [AddressDataHelper addressDataForEmailRecipients:newRecipientList];

        [message.messageData setAddressData:newAddressData];
    }


    NSMutableArray* newButtonsArray = [NSMutableArray new];

    EmailRecipient* senderAsEmailRecipient = [AddressDataHelper senderAsEmailRecipientForMessage:message];

    NSButton* newButton = [self newRecipientButtonWithEmailRecipient:senderAsEmailRecipient alsoAddComma:NO];

    if(self.senderButton.superview)
    {
        [self.senderButton removeFromSuperview];
        [self setSenderButton:nil];
    }

    if(newButton)
        [self addSubview:newButton];

    [self setSenderButton:newButton];




    NSTextField* newToLabel = [[NSTextField alloc] init];

    NSString* toString = NSLocalizedString(@"to", @"Content viewer address list");

    if(!toString)
        toString = @"to";

    NSAttributedString* attrTitle = [[NSAttributedString alloc] initWithString:toString attributes:@{NSForegroundColorAttributeName:[NSColor disabledControlTextColor]}];

    [newToLabel setAttributedStringValue:attrTitle];

    [newToLabel setBezeled:NO];
    [newToLabel setEditable:NO];
    [newToLabel setSelectable:NO];

    [newToLabel sizeToFit];

    if(self.toLabel.superview)
    {
        [self.toLabel removeFromSuperview];
        [self setToLabel:nil];
    }

    if(newToLabel)
        [self addSubview:newToLabel];

    [self setToLabel:newToLabel];



    NSArray* recipientsArray = [AddressDataHelper recipientsWithoutSenderForMessage:message];

    NSInteger counter = 0;

    for(EmailRecipient* emailRecipient in recipientsArray)
    {
        counter++;

        BOOL stillMoreToCome = counter<recipientsArray.count;

        NSButton* newButton = [self newRecipientButtonWithEmailRecipient:emailRecipient alsoAddComma:stillMoreToCome];

        if(newButton && senderAsEmailRecipient)
        {
            [self addSubview:newButton];

            [newButtonsArray addObject:newButton];
        }
    }

    self.addressLabelButtons = newButtonsArray;

    [self layoutAddressLabels];

    [self invalidateIntrinsicContentSize];
}

- (NSSize)intrinsicContentSize
{
    return NSMakeSize(self.bounds.size.width, self.isExpanded?self.numberOfLines*(LINE_HEIGHT):LINE_HEIGHT);
}

- (NSButton*)expandButtonAfterIndex:(NSInteger)indexOfNextObject
{
    NSInteger numberOfRemainingLabels = self.addressLabelButtons.count - indexOfNextObject;

    if(numberOfRemainingLabels<=0)
        return nil;

    NSString* buttonTitle = @"";

    if(indexOfNextObject==0)
    {
        if(self.addressLabelButtons.count==1)
        {
            buttonTitle = NSLocalizedString(@"1 recipient", @"Content viewer expansion button");
        }
        else
        {
            buttonTitle = [NSString stringWithFormat:NSLocalizedString(@"%ld recipients", @"Content viewer expansion button"), numberOfRemainingLabels];
        }
    }
    else
    {
        if(numberOfRemainingLabels==1)
        {
            buttonTitle = [NSString stringWithFormat:NSLocalizedString(@"+ 1 recipient", @"Content viewer expansion button"), numberOfRemainingLabels];
        }
        else
        {
            buttonTitle = [NSString stringWithFormat:NSLocalizedString(@"+ %ld recipients", @"Content viewer expansion button"), numberOfRemainingLabels];
        }
    }

    NSButton* newButton = [[NSButton alloc] init];

    if(!buttonTitle)
        buttonTitle = @"";

    NSAttributedString* attrTitle = [[NSAttributedString alloc] initWithString:buttonTitle attributes:@{NSForegroundColorAttributeName:DARK_BLUE_COLOUR, NSUnderlineStyleAttributeName:@(NSUnderlineStyleSingle)}];

    [newButton setAttributedTitle:attrTitle];

    [newButton setBordered:NO];

    [newButton setButtonType:NSMomentaryLight];

    [newButton sizeToFit];

    [newButton setTarget:self];

    [newButton setAction:@selector(expandButtonHit:)];

    return newButton;
}

- (IBAction)expandButtonHit:(id)sender
{
    [self setIsExpanded:YES];
    [self invalidateIntrinsicContentSize];
    [self layoutAddressLabels];
}

//- (void)hideButton:(NSButton*)button
//{
//    [button setFrame:NSMakeRect(-button.bounds.size.width, 0, button.bounds.size.width, button.bounds.size.height)];
//}

- (void)layoutAddressLabels
{
    if(self.expansionButton)
    {
        [self.expansionButton removeFromSuperview];
        self.expansionButton = nil;
    }

	CGFloat topMargin = 1; //floor(layoutLineHeight * 4 / 7) + 2 + TOKENS_OFFSET;
	CGFloat hPadding = 0;
    CGFloat leftMargin = 0;
	CGFloat rightMargin = hPadding;
    CGFloat rightMarginForTopLine = hPadding + 40;
	CGFloat lineHeight = LINE_HEIGHT;

    self.numberOfLines = 1;
	__block CGPoint tokenCaret = (CGPoint){0, (topMargin - 1)};

    __block BOOL hideAllRemainingButtons = NO;

    __block NSButton* previousExpansionButton;

    //first draw the sender
    [self.senderButton setFrame:(CGRect){tokenCaret, self.senderButton.bounds.size}];
    tokenCaret.x += self.senderButton.bounds.size.width + hPadding;


    //and then the "to" text field
    [self.toLabel setFrame:(CGRect){tokenCaret, self.toLabel.bounds.size}];
    tokenCaret.x += self.toLabel.bounds.size.width + hPadding;

    //now the actual recipients
	[self.addressLabelButtons enumerateObjectsUsingBlock:^(NSView* button, NSUInteger idx, BOOL *stop){

        if(hideAllRemainingButtons)
        {
            //used to hide all buttons from the second line onwards (if the view is not expanded)
            [button setHidden:YES];
        }
        else
        {

            CGFloat actualWidth = self.bounds.size.width;

            //if the line is not expanded we need to leave space for the expansion button
            if(!self.isExpanded && self.numberOfLines == 1)
            {
                
                NSButton* expansionButton = [self expandButtonAfterIndex:idx+1];

                CGFloat neededWidthIncludingExpansionButton = tokenCaret.x + hPadding + button.bounds.size.width + hPadding + expansionButton.bounds.size.width + hPadding;

                if(neededWidthIncludingExpansionButton > actualWidth)
                {
                    //the new button wouldn't fit, so hide it, add the expansion button and hide all remaining buttons, too!
                    if (previousExpansionButton)
                    {
                        [self addSubview:previousExpansionButton];
                        [previousExpansionButton setFrame:(CGRect){tokenCaret, previousExpansionButton.bounds.size}];
                        [self setExpansionButton:previousExpansionButton];
                    }
                    else
                    {
                        expansionButton = [self expandButtonAfterIndex:0];
                        [self addSubview:expansionButton];
                        [expansionButton setFrame:(CGRect){tokenCaret, expansionButton.bounds.size}];
                        [self setExpansionButton:expansionButton];
                    }

                    [button setHidden:YES];

                    hideAllRemainingButtons = YES;
                }
                
                previousExpansionButton = expansionButton;

            }

            if(!hideAllRemainingButtons)
            {
                [button setHidden:NO];


                CGFloat maxWidth = self.bounds.size.width - tokenCaret.x - hPadding - (self.numberOfLines == 1 ? rightMarginForTopLine : rightMargin);

                if(button.superview)
                {
                    if (button.bounds.size.width > maxWidth)
                    {
                        self.numberOfLines++;
                        tokenCaret.x = leftMargin;
                        tokenCaret.y += lineHeight;
                    }
                    
                    [button setFrame:(CGRect){tokenCaret, button.bounds.size}];
                    tokenCaret.x += button.bounds.size.width + hPadding;
                }
            }
        }
	}];
}

- (NSMenu*)menuForEmailRecipient:(EmailRecipient*)emailRecipient
{
    NSMenu* newMenu = [[NSMenu alloc] initWithTitle:emailRecipient.displayString];

    //show email address
    if(emailRecipient.name)
    {
        NSMenuItem* emailAddressMenuItem = [[NSMenuItem alloc] initWithTitle:emailRecipient.email action:nil keyEquivalent:@""];
        
        [newMenu addItem:emailAddressMenuItem];
        
        NSMenuItem* separator = [NSMenuItem separatorItem];
        
        [newMenu addItem:separator];
    }
    
    //compose message to
    if (emailRecipient.email)
    {
        NSMenuItem* composeMessageMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Compose message to...", nil) action:@selector(sendMessage:) keyEquivalent:@""];
        
        [composeMessageMenuItem setTarget:self];
        [composeMessageMenuItem setRepresentedObject:emailRecipient];
        
        [newMenu addItem:composeMessageMenuItem];
    }
    
    //invite to Mynigma function, if applicable
    if(emailRecipient.email)
    {
        if(![MynigmaPublicKey havePublicKeyForEmailAddress:emailRecipient.email])
        {
            NSMenuItem* invitationMenuItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Invite to Mynigma", @"Invitation menu item") action:@selector(inviteToMynigma:) keyEquivalent:@""];

            [invitationMenuItem setTarget:self];
            [invitationMenuItem setRepresentedObject:emailRecipient];

            [newMenu addItem:invitationMenuItem];

//            NSMenuItem* separator = [NSMenuItem separatorItem];
//
//            [newMenu addItem:separator];
        }
    }


    EmailContactDetail* emailContactDetail = [EmailContactDetail emailContactDetailForAddress:emailRecipient.email];

    //add to contacts
    if(emailContactDetail.linkedToContact.count==0)
    {
        NSMenuItem* addToContacts = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Add to contacts", @"Content viewer context menu") action:@selector(addToContacts:) keyEquivalent:@""];

        [addToContacts setTarget:self];
        [addToContacts setRepresentedObject:emailRecipient];

        [newMenu addItem:addToContacts];

//        NSMenuItem* separator = [NSMenuItem separatorItem];
//
//        [newMenu addItem:separator];

    }

    NSMenuItem* copyAddress = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Copy address", @"Content viewer context menu") action:@selector(copyAddress:) keyEquivalent:@""];

    [copyAddress setTarget:self];
    [copyAddress setRepresentedObject:emailRecipient];

    [newMenu addItem:copyAddress];


    return newMenu;
}

- (IBAction)addToContacts:(id)sender
{
    EmailRecipient* emailRecipient = [(NSMenuItem*)sender representedObject];

    NSString* email = emailRecipient.email;
    NSString* fullName = emailRecipient.name;

    [EmailContactDetail addEmailContactDetailForEmail:email makeDuplicateIfNecessary:YES withCallback:^(EmailContactDetail *contactDetail, BOOL alreadyFoundOne) {

        [contactDetail setFullName:fullName];
        [Contact addEmailAddressDetailToContacts:contactDetail];

    }];
}

- (IBAction)copyAddress:(id)sender
{
    EmailRecipient* emailRecipient = [(NSMenuItem*)sender representedObject];

    NSPasteboard* pboard = [NSPasteboard generalPasteboard];

    [pboard clearContents];
    NSPasteboardItem *item = [[NSPasteboardItem alloc] init];

    NSString* longDisplayString = [emailRecipient longDisplayString];

    [item setString:longDisplayString forType:NSStringPboardType];

    [pboard writeObjects:@[longDisplayString]];
}

//opens a new draft message to the contact associated with the context menu
- (IBAction)sendMessage:(id)sender
{
    EmailRecipient* emailRecipient = [(NSMenuItem*)sender representedObject];

    [WindowManager showNewMessageWindowWithRecipient:emailRecipient];
//    EmailMessageInstance* newInstance = [APPDELEGATE showFreshMessageWindow];


}

- (IBAction)inviteToMynigma:(id)sender
{
    EmailRecipient* emailRecipient = [(NSMenuItem*)sender representedObject];

    [WindowManager showInvitationMessageForEmailRecipient:emailRecipient];
}

@end
