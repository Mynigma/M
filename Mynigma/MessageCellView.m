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





#import "MessageCellView.h"
#import "AppDelegate.h"
#import "EmailMessage.h"
#import "MynigmaMessage.h"

#import "IMAPFolderSetting.h"
#import "IMAPAccountSetting.h"
#import "IMAPAccount.h"
#import "MessageCellView.h"
#import "MessageRowView.h"
#import <MailCore/MailCore.h>
#import "IconListAndColourHelper.h"
#import "MessageListIconView.h"
#import "EmailMessageInstance+Category.h"




@implementation MessageCellView

@synthesize bodyField;
@synthesize fromField;
@synthesize toField;
@synthesize subjectField;
@synthesize dateSentField;

@synthesize widthConstraint1;
@synthesize widthConstraint2;
@synthesize widthConstraint3;
@synthesize widthConstraint4;
@synthesize widthConstraint5;


@synthesize boxWidthConstraint;

@synthesize topBox;
@synthesize bottomBox;

@synthesize symbol1;
@synthesize symbol2;
@synthesize symbol3;
@synthesize symbol4;
@synthesize symbol5;

@synthesize leftSymbol1;
@synthesize leftSymbol2;
@synthesize leftSymbol3;
@synthesize leftSymbol4;
@synthesize leftSymbol5;

@synthesize previewField;

@synthesize labelField;
@synthesize unreadSymbol;

@synthesize box;

@synthesize detailField;

@synthesize toStringField;

@synthesize disclosureTriangle;

@synthesize toString;
@synthesize toWidth;

@synthesize messageInstance;

@synthesize expanded;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        hasBackgroundStyleLight = NO;
    }
    
    return self;
}


/*
 - (void)drawRect:(NSRect)dirtyRect
 {

     //if(self.backgroundStyle == NSBackgroundStyleLight)
     if(hasBackgroundStyleLight)
     {
         NSInteger selectedRow = [APPDELEGATE.messagesTable selectedRow];
         NSInteger thisRow = [APPDELEGATE.messagesTable rowForView:self];
         if(selectedRow>-1 && selectedRow==thisRow)
         {
             [[NSColor gridColor] set];
         }
         else
         {
             if(message && [MODEL isUnread:(EmailMessage*)message])
             {
                 [[NSColor colorWithDeviceRed:243./255 green:246./255 blue:250./255 alpha:1] set];
             }
             else
             {
                 [[NSColor whiteColor] set];
             }
         }
     }
     else
     {
         [[NSColor alternateSelectedControlColor] set];
     }
     NSRectFill(self.frame);
}*/

- (IBAction)triangleClicked:(id)sender
{
    
}

- (NSArray *)draggingImageComponents
{
    NSDraggingImageComponent *onlyComponent = [NSDraggingImageComponent draggingImageComponentWithKey:@"Message"];
    onlyComponent.contents = [NSImage imageNamed:@"postcardStraight2.png"];
    
    
    NSWindow *plotWindow = [self window];
    NSPoint mousePosition = [plotWindow mouseLocationOutsideOfEventStream];
    
    //convert to View
    mousePosition = [self convertPoint:mousePosition fromView:nil];
    float mX = mousePosition.x;
    float mY = mousePosition.y;

    // Convert the frame to our coordinate system
    NSMutableArray *result = [NSMutableArray array];
    NSRect viewBounds = [self convertRect:NSMakeRect(mX-20, mY-17, 51, 35) fromView:self];
    onlyComponent.frame = viewBounds;
    
    [result addObject:onlyComponent];
    return result;
}


- (void)setBackgroundStyle:(NSBackgroundStyle)backgroundStyle
{
    NSColor *textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor whiteColor] : [NSColor controlDarkShadowColor];
    
    hasBackgroundStyleLight = (backgroundStyle == NSBackgroundStyleLight);

    self.toField.textColor = textColor;
    self.fromField.textColor = textColor;
    NSAttributedString* subject = self.subjectField.attributedStringValue;
    if(!subject)
        return;

    NSMutableAttributedString* subjectCopy = [subject mutableCopy];
    [subject enumerateAttributesInRange:NSMakeRange(0,subject.length) options:NSAttributedStringEnumerationReverse usingBlock:
     ^(NSDictionary *attributes, NSRange range, BOOL *stop) {
         
         if(![attributes objectForKey:NSBackgroundColorAttributeName])
         {
             [subjectCopy addAttribute:NSForegroundColorAttributeName value:(backgroundStyle == NSBackgroundStyleDark) ? [NSColor whiteColor] : [NSColor controlDarkShadowColor] range:range];         }
         
     }];

    [self.subjectField setAttributedStringValue:subjectCopy];
    
    self.dateSentField.textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor whiteColor] : [NSColor selectedKnobColor];
    
    self.toStringField.textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor whiteColor] : [NSColor controlDarkShadowColor];
    
    self.previewField.textColor = (backgroundStyle == NSBackgroundStyleDark) ? [NSColor whiteColor] : [NSColor secondarySelectedControlColor];

    EmailMessage* displayedMessage = (EmailMessage*)self.message;
    EmailMessageInstance* displayedMessageInstance = (EmailMessageInstance*)self.messageInstance;

    if([displayedMessageInstance isFlagged])
    {
        NSImage* starImage = [NSImage imageNamed:@"starred16"];
        [self.starImageView setImage:starImage withTintColour:(backgroundStyle == NSBackgroundStyleDark)?[NSColor whiteColor]:[NSColor colorWithDeviceRed:242./255 green:208./255 blue:83./255 alpha:1]];
        [self.starImageView showTheLogo];
    }
    else
        [self.starImageView hideTheLogo];

    if(displayedMessage)
    {
        NSArray* imagesToBeDisplayed = (displayedMessageInstance!=nil)?[IconListAndColourHelper leftEdgeIconsForMessageInstance:displayedMessageInstance]:[IconListAndColourHelper leftEdgeIconsForMessage:displayedMessage];
        NSArray* otherImagesToBeDisplayed = (displayedMessageInstance!=nil)?[IconListAndColourHelper otherIconsForMessageInstance:displayedMessageInstance]:[IconListAndColourHelper otherIconsForMessage:displayedMessage];

        if(imagesToBeDisplayed.count==0)
            boxWidthConstraint.constant = 0;
        else
            boxWidthConstraint.constant = LEFT_BORDER_OFFSET;

        //first draw the images on the left hand side
        if(imagesToBeDisplayed.count==1)
        { //only one image
            [[self leftSymbol1] setImage:nil];
            [[self leftSymbol2] setImage:nil];
            NSImageView* imageView = [self leftSymbol3];
            NSDictionary* iconDict = [imagesToBeDisplayed objectAtIndex:0];
            [imageView setImage:[iconDict objectForKey:@"image"]];
            if(backgroundStyle == NSBackgroundStyleDark)
            {
                [topBox setFillColor:[iconDict objectForKey:@"colourBG"]];
                [bottomBox setFillColor:[iconDict objectForKey:@"colourBG"]];
            }
            else
            {
                [topBox setFillColor:[iconDict objectForKey:@"colour"]];
                [bottomBox setFillColor:[iconDict objectForKey:@"colour"]];
            }
        }
        else if(imagesToBeDisplayed.count>1)
        { //two images
            [[self leftSymbol3] setImage:nil];
            NSImageView* imageView1 = [self leftSymbol1];
            NSImageView* imageView2 = [self leftSymbol2];
            NSDictionary* iconDict1 = [imagesToBeDisplayed objectAtIndex:0];
            NSDictionary* iconDict2 = [imagesToBeDisplayed objectAtIndex:1];
            [imageView1 setImage:[iconDict1 objectForKey:@"image"]];
            [imageView2 setImage:[iconDict2 objectForKey:@"image"]];
            if(backgroundStyle == NSBackgroundStyleDark)
            {
                [topBox setFillColor:[iconDict1 objectForKey:@"colourBG"]];
                [bottomBox setFillColor:[iconDict2 objectForKey:@"colourBG"]];
            }
            else
            {
                [topBox setFillColor:[iconDict1 objectForKey:@"colour"]];
                [bottomBox setFillColor:[iconDict2 objectForKey:@"colour"]];
            }
        }
        else
        {
            [[self leftSymbol1] setImage:nil];
            [[self leftSymbol2] setImage:nil];
            [[self leftSymbol3] setImage:nil];
        }
        
        //then the additional ones below the subject line
        for(NSInteger index=1;index<=5;index++)
        {
            NSImageView* imageView = [self valueForKey:[NSString stringWithFormat:@"symbol%ld",index]];
            NSLayoutConstraint* constraint = [self valueForKey:[NSString stringWithFormat:@"widthConstraint%ld",index]];
            if(index-1<otherImagesToBeDisplayed.count) //there is an icon to be displayed at this index
            {
                //the icon dictionary containing the actual icon to be displayed
                NSDictionary* iconDict = [otherImagesToBeDisplayed objectAtIndex:index-1];
                if([imageView isKindOfClass:[MessageListIconView class]])
                {
                    [(MessageListIconView*)imageView setImage:[iconDict objectForKey:@"image"] withTintColour:(backgroundStyle == NSBackgroundStyleDark)?[NSColor whiteColor]:[NSColor lightGrayColor]];
                }
                else
                    [imageView setImage:[iconDict objectForKey:(backgroundStyle == NSBackgroundStyleDark)?@"imageBG":@"image"]];
                if(constraint)
                {
                    constraint.constant = 20;
                }
            }
            else
            {
                if(imageView)
                    [imageView setImage:nil];
                if(constraint)
                {
                    constraint.constant = 0;
                }
            }
        }
        
        [self setNeedsLayout:YES];
    }
    else
    {
        [[self leftSymbol1] setImage:nil];
        [[self leftSymbol2] setImage:nil];
        [[self leftSymbol3] setImage:nil];
        [[self leftSymbol4] setImage:nil];
        [[self leftSymbol5] setImage:nil];
        [[self symbol1] setImage:nil];
        [[self symbol2] setImage:nil];
        [[self symbol3] setImage:nil];
        [[self symbol4] setImage:nil];
        [[self symbol5] setImage:nil];
        [self.widthConstraint1 setConstant:0];
        [self.widthConstraint2 setConstant:0];
        [self.widthConstraint3 setConstant:0];
        [self.widthConstraint4 setConstant:0];
        [self.widthConstraint5 setConstant:0];

        NSLog(@"No displayed message set!!");
    }


    [super setBackgroundStyle:backgroundStyle];
}

- (BOOL)tokenField:(NSTokenField *)tokenField hasMenuForRepresentedObject:(id)representedObject
{
    return NO;
}

- (NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
    if([representedObject isKindOfClass:[NSString class]])
    {
        return representedObject;
    }
    else
        return @"Not a string!";
}


@end
