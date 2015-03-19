//
//  MacTokenField.m
//  MacTokenField
//

#import "MacTokenField.h"
#import "IconListAndColourHelper.h"
#import "Recipient.h"
#import "Contact.h"
#import "EmailContactDetail+Category.h"
#import "MacTokenFieldTextContainer.h"


CGFloat const lineHeight = 22;
CGFloat const hTextPadding = 25;
CGFloat const hTextMargin = 5;
CGFloat const vTextMargin = 5;
CGFloat const vTextPadding = 3;
CGFloat const kDisclosureThickness = 2.5;
NSLineBreakMode const kLineBreakMode = NSLineBreakByTruncatingMiddle;



CGFloat const baselineOffset = 5;

#define PROMPT_OFFSET 0
#define TEXT_OFFSET -1
#define TOKENS_OFFSET 0


NSString * const kTextHidden = @"\u200D"; // Zero-Width Joiner

static NSFont* textFont;
static NSFont* tokenFont;

static NSMutableParagraphStyle* defaultParagraphStyle;

#pragma mark - MacTokenFieldInternalDelegate


@interface MacToken (Private)

- (instancetype)initWithTitle:(NSString *)aTitle;
- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object;
- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object font:(NSFont *)aFont;

@end



@implementation MacTokenFieldInternalDelegate

- (void)textView:(NSTextView *)textView clickedOnCell:(id <NSTextAttachmentCell>)cell inRect:(NSRect)cellFrame atIndex:(NSUInteger)charIndex
{
    //[(MacTokenField*)textView setSelectedRange:NSMakeRange(charIndex, 1)];

    if([_externalDelegate respondsToSelector:@selector(menuForToken:)])
    {
        NSMenu* menu = [_externalDelegate menuForToken:(MacToken*)cell];

        [menu popUpMenuPositioningItem:nil atLocation:NSMakePoint(cellFrame.origin.x+cellFrame.size.width - 20, cellFrame.origin.y + cellFrame.size.height) inView:textView];
    }
}

- (NSArray *)textView:(NSTextView *)view writablePasteboardTypesForCell:(id <NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex
{
    if([_externalDelegate respondsToSelector:@selector(textView:writablePasteboardTypesForCell:atIndex:)])
        return [_externalDelegate textView:view writablePasteboardTypesForCell:cell atIndex:charIndex];

    return @[];
}

- (BOOL)textView:(NSTextView *)view writeCell:(id <NSTextAttachmentCell>)cell atIndex:(NSUInteger)charIndex toPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    if([_externalDelegate respondsToSelector:@selector(textView:writeCell:atIndex:toPasteboard:type:)])
        return [_externalDelegate textView:view writeCell:cell atIndex:charIndex toPasteboard:pboard type:type];

    return NO;
}

- (void)didBeginEditing:(NSNotification*)notification
{

}

- (void)didEndEditing:(NSNotification*)notification
{
	[_tokenField tokeniseText];
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRanges:(NSArray *)affectedRanges replacementStrings:(NSArray *)replacementStrings
{
    BOOL returnValue = YES;

    NSMutableArray* tokensToBeDeleted = [NSMutableArray new];

    for(NSInteger counter = 0; counter < affectedRanges.count; counter++)
    {
        NSValue* value = affectedRanges[counter];

        NSRange range = value.rangeValue;

        NSString* replacementString = @"";

        if(counter < replacementStrings.count)
        {
            replacementString = replacementStrings[counter];
        }

        if([self.externalDelegate respondsToSelector:@selector(textView:shouldChangeTextInRanges:replacementStrings:)])
            if(![self.externalDelegate textView:textView shouldChangeTextInRanges:affectedRanges replacementStrings:replacementStrings])
                returnValue = NO;

        //check if any tokens have been deleted
        NSAttributedString* attributedStringBeingReplaced = [_tokenField.attributedString attributedSubstringFromRange:range];

        for(NSInteger location = 0; location < attributedStringBeingReplaced.length; location++)
        {
            NSAttributedString* characterString = [attributedStringBeingReplaced attributedSubstringFromRange:NSMakeRange(location, 1)];

            id attribute = [characterString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];

            if([attribute isKindOfClass:[NSTextAttachment class]])
            {
                MacToken* token = (MacToken*)[(NSTextAttachment*)attribute attachmentCell];
                if([token isKindOfClass:[MacToken class]])
                    [tokensToBeDeleted addObject:token];
            }
        }
    }

    if(returnValue)
    {
        [_tokenField removeTokens:tokensToBeDeleted];
        _tokenField.needToUpdateHeightAfterTextChange = YES;
    }

    return returnValue;
}

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if(commandSelector == @selector(deleteBackward:))
    {
        //check if there is a token just to the left of the caret
        //if so, break it up and expose the string value
        NSRange selectedRange = [[[textView selectedRanges] objectAtIndex:0] rangeValue];

        //if there is a selection, simply delete the selection and don't open a token
        if(selectedRange.length>0)
            return NO;

        NSInteger insertionPoint = selectedRange.location;

        if(insertionPoint>0)
        {
            NSRange range = NSMakeRange(insertionPoint - 1, 1);

            NSAttributedString* previousCharacter = [textView.attributedString attributedSubstringFromRange:range];

            id attribute = [previousCharacter attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];

            if([attribute isKindOfClass:[NSTextAttachment class]])
            {
                //yes, it has a text attachment, so it must be a token
                MacToken* token = (MacToken*)[(NSTextAttachment*)attribute attachmentCell];

                [_tokenField removeToken:token];

                NSString* titleString = token.title;

                if(!titleString)
                    titleString = @"";

                [textView.textStorage replaceCharactersInRange:range withAttributedString:[[NSAttributedString alloc] initWithString:titleString attributes:@{NSForegroundColorAttributeName:NAVBAR_COLOUR}]];
                return YES;
            }
        }
    }

    if(commandSelector == @selector(insertTab:))
    {
        if(_tokenField.superview.nextKeyView)
        {
            [[_tokenField window] selectNextKeyView:_tokenField.superview];
        }
        return YES;
    }

    //return NO to indicate that the delegate dod not handle the command
    return NO;
}

- (NSArray *)textView:(NSTextView *)textView completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)index;
{
    if([self.externalDelegate respondsToSelector:@selector(textView:completions:forPartialWordRange:indexOfSelectedItem:)])
        return  [self.externalDelegate textView:textView completions:words forPartialWordRange:charRange indexOfSelectedItem:index];

    return @[];
}


@end


#pragma mark - MacTokenField

@interface MacTokenField (Private)
- (void)setup;
@end

@implementation MacTokenField {
	NSMutableArray * _tokens;
	CGPoint _tokenCaret;
    MacTokenFieldInternalDelegate* _internalDelegate;
}
@synthesize selectedTokens = _selectedTokens;
@synthesize tokenizingCharacters = _tokenizingCharacters;


- (instancetype)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
		[self setup];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder]))
    {
		[self setup];
	}

	return self;
}

- (void)removeFromSuperview
{
    [self setDelegate:nil];
        
    //break up delegate retain cycle
    _internalDelegate = nil;
    [super removeFromSuperview];
}

- (void)awakeFromNib
{
    [self setup];
}

- (BOOL)resignFirstResponder
{
    [self tokeniseText];
    return [super resignFirstResponder];
}

- (void)setup
{
    self.isShowingCompletions = NO;

    self.needToUpdateHeightAfterTextChange = NO;

    _tokenLimit = -1;

//    id actualDelegate = self.delegate;

	_internalDelegate = [[MacTokenFieldInternalDelegate alloc] init];
	[_internalDelegate setTokenField:self];
//	[_internalDelegate setExternalDelegate:actualDelegate];
    [super setDelegate:_internalDelegate];
    
    //[[NSNotificationCenter defaultCenter] addObserver:_internalDelegate selector:@selector(didEndEditing:) name:NSTextDidEndEditingNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:_internalDelegate selector:@selector(textDidChange:) name:NSTextDidChangeNotification object:nil];
    //[[NSNotificationCenter defaultCenter] addObserver:_internalDelegate selector:@selector(didBeginEditing:) name:NSTextDidBeginEditingNotification object:nil];

    NSFont* newFont = [NSFont systemFontOfSize:12];

    [self setFont:newFont];

    [self.textStorage setFont:newFont];

    [self setTextColor:NAVBAR_COLOUR];

    if(!defaultParagraphStyle)
    {
        defaultParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

        [defaultParagraphStyle setLineSpacing:5];

        //[defaultParagraphStyle setMaximumLineHeight:19];
        //[defaultParagraphStyle setMinimumLineHeight:19];

        [defaultParagraphStyle setParagraphSpacing:5];
    }

    [self setDefaultParagraphStyle:defaultParagraphStyle];

    [self setString:@""];

    //[self.textStorage setAttributedString:[EmptyToken emptyString]];

    //[self.textStorage setAttributedString:[EmptyToken emptyString]];

    [self updateHeight];

    self.contentWidth = 20;

	_tokens = [NSMutableArray array];
	_tokenizingCharacters = [NSCharacterSet characterSetWithCharactersInString:@",;\n\r\t"];
}

#pragma mark PROPERTY OVERRIDES

- (void)setFrame:(CGRect)frame
{
    //fix for 10.8 crash
    if (frame.origin.x != 0 || frame.origin.y != 0 || frame.size.width != 0 || frame.size.height != 0)
        [super setFrame:frame];

    [self updateHeight];
}

- (void)setDelegate:(id<MacTokenFieldDelegate>)del
{
    _internalDelegate.externalDelegate = del;
    [super setDelegate:_internalDelegate];
}

- (NSArray *)tokens
{
//    NSMutableArray* returnValue = [NSMutableArray new];
//
//    NSAttributedString* tokenFieldString = self.attributedString;
//
//    //rescan the contents of the view for tokens, just in case
//    for(NSInteger location = 0; location < tokenFieldString.length; location++)
//    {
//        NSAttributedString* characterString = [tokenFieldString attributedSubstringFromRange:NSMakeRange(location, 1)];
//
//        id attribute = [characterString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];
//
//        if([attribute isKindOfClass:[NSTextAttachment class]])
//        {
//            MacToken* token = (MacToken*)[(NSTextAttachment*)attribute attachmentCell];
//            if([token isKindOfClass:[MacToken class]])
//                [returnValue addObject:token];
//        }
//    }
//
//	return returnValue;

    return [_tokens copy];
}


- (NSScrollView *)scrollView
{
	return ([self.superview isKindOfClass:[NSScrollView class]] ? (NSScrollView *)self.superview : nil);
}


#pragma mark - MANAGING TOKENS

- (MacToken *)addTokenWithTitle:(NSString *)title
{
	return [self addTokenWithTitle:title representedObject:nil insertAtIndex:-1];
}

- (MacToken *)addTokenWithTitle:(NSString *)title representedObject:(id)object insertAtIndex:(NSInteger)insertionIndex
{
	if (title.length)
    {
		MacToken * token = [[MacToken alloc] initWithTitle:title representedObject:object font:self.font];

        if(![self canAddToken:token])
            return nil;

        [_tokens addObject:token];

        if([_internalDelegate.externalDelegate respondsToSelector:@selector(tintColourForToken:)])
        {
            NSColor* tintColour = [_internalDelegate.externalDelegate tintColourForToken:token];

            [token setTintColor:tintColour];
        }

        if([_internalDelegate.externalDelegate respondsToSelector:@selector(highlightTintColourForToken:)])
        {
            NSColor* highlightTintColour = [_internalDelegate.externalDelegate highlightTintColourForToken:token];

            [token setHighlightTintColor:highlightTintColour];
        }

        if(insertionIndex >=0 && insertionIndex <= self.attributedString.length)
        {
            NSTextAttachment* newAttachment = [[NSTextAttachment alloc] init];

            [newAttachment setAttachmentCell:token];

            NSAttributedString* newAttributedString = [MacToken attributedStringWithToken:token paragraphStyle:self.defaultParagraphStyle];

            [self.textStorage beginEditing];
            [self.textStorage insertAttributedString:newAttributedString atIndex:insertionIndex];
            [self.textStorage endEditing];

            [self.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, self.attributedString.length) actualCharacterRange:nil];
            [self.layoutManager invalidateDisplayForCharacterRange:NSMakeRange(0, self.attributedString.length)];

            [self updateHeight];
            [self updateWidth];

            if ([_internalDelegate.externalDelegate respondsToSelector:@selector(tokenField:didAddToken:)])
            {
                [_internalDelegate.externalDelegate tokenField:self didAddToken:token];
            }
        }

		return token;
	}

	return nil;
}

- (BOOL)canAddToken:(MacToken *)token
{
	BOOL shouldAdd = YES;
	if ([_internalDelegate.externalDelegate respondsToSelector:@selector(tokenField:willAddToken:)])
    {
		shouldAdd = [(id<MacTokenFieldDelegate>)_internalDelegate.externalDelegate tokenField:self willAddToken:token];
	}

    if(self.tokens.count >= self.tokenLimit)
        shouldAdd = NO;

	if (shouldAdd){

		if (![_tokens containsObject:token])
        {
            return YES;
		}
	}

    return NO;
}


- (void)removeTokens:(NSArray*)tokenArray
{
    for(MacToken* token in tokenArray)
    {
        [self removeToken:token];
    }
}


//TO DO: actually delete the token from the text view (!!!)
- (void)removeToken:(MacToken *)token
{
	if ([_selectedTokens containsObject:token])
        [self deselectToken:token];

	BOOL shouldRemove = YES;
	if ([_internalDelegate.externalDelegate respondsToSelector:@selector(tokenField:willRemoveToken:)])
    {
		shouldRemove = [(id<MacTokenFieldDelegate>)_internalDelegate.externalDelegate tokenField:self willRemoveToken:token];
	}

	if (shouldRemove)
    {
		[_tokens removeObject:token];

		if ([_internalDelegate.externalDelegate respondsToSelector:@selector(tokenField:didRemoveToken:)]){
			[(id<MacTokenFieldDelegate>)_internalDelegate.externalDelegate tokenField:self didRemoveToken:token];
		}

        [self updateHeight];
        [self updateWidth];
    }
}

- (void)removeAllTokens
{
    NSSet* allTokens = [NSSet setWithArray:_tokens];
	for(MacToken* token in allTokens)
         [self removeToken:token];

    //[self setString:@"\u200D"];
    [self.textStorage beginEditing];
    [self.textStorage setAttributedString:[NSAttributedString new]];
    [self.textStorage endEditing];
}



#pragma mark - DRAG & DROP / COPY & PASTE

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{
    BOOL result = [super performDragOperation:sender];

    [self tokeniseText];

    return result;
}

-(void)paste:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSString *pbItem = [pb readObjectsForClasses: @[[NSString class],[NSAttributedString class]] options:nil].lastObject;

    [super paste:pbItem];
    [self tokeniseText];
}

- (NSArray *)readablePasteboardTypes
{
    return @[NSStringPboardType];
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pboard type:(NSString *)type
{
    if ([type isEqual:NSStringPboardType])
    {
        NSString* insertionString = [pboard stringForType:type];
        [self insertText:insertionString];
        return YES;
    }

    return [super readSelectionFromPasteboard:pboard type:type];
}



#pragma mark - SELECTION

- (void)selectToken:(MacToken *)token byExtendingSelection:(BOOL)extendSelection
{
	if(!extendSelection)
        [self deselectSelectedTokens];

	[_selectedTokens addObject:token];

    [token setSelected:YES];

    [token setHighlighted:YES];
}

- (void)deselectToken:(MacToken*)token
{
    [token setSelected:NO];

    [token setHighlighted:NO];

    [_selectedTokens removeObject:token];
}

- (void)deselectSelectedTokens
{
    NSArray* selectedTokens = [_selectedTokens copy];
    for(MacToken* token in selectedTokens)
    {
        [self deselectToken:token];
    }
}


#pragma mark - TOKENISING

- (void)tokeniseText
{
    NSAttributedString* tokenFieldText = self.attributedString;

    NSMutableArray* rangesToBeReplaced = [NSMutableArray new];

    NSMutableArray* addedTokens = [NSMutableArray new];

    NSInteger startOfRange = 0;

    for(NSInteger currentLocation = 0; currentLocation < tokenFieldText.length; currentLocation++)
    {
        NSAttributedString* characterString = [tokenFieldText attributedSubstringFromRange:NSMakeRange(currentLocation, 1)];

        unichar character = [characterString.string characterAtIndex:0];

        id attribute = [characterString attribute:NSAttachmentAttributeName atIndex:0 effectiveRange:NULL];

        if(attribute)
        {
            if(currentLocation-1 >=0 && currentLocation > startOfRange + 1)
            {
                NSRange newRange = NSMakeRange(startOfRange, currentLocation - startOfRange);

                [rangesToBeReplaced addObject:[NSValue valueWithRange:newRange]];
            }

            startOfRange = currentLocation + 1;
        }

        if([_tokenizingCharacters characterIsMember:character])
        {
            if(currentLocation-1 >=0 && currentLocation > startOfRange + 1)
            {
                NSRange newRange = NSMakeRange(startOfRange, currentLocation - startOfRange);

                [rangesToBeReplaced addObject:[NSValue valueWithRange:newRange]];
            }

            //this will effectively remove the tokenising character
            [rangesToBeReplaced addObject:[NSValue valueWithRange:NSMakeRange(currentLocation, 1)]];

            startOfRange = currentLocation + 1;
        }

        if(currentLocation == tokenFieldText.length - 1)
        {
            NSRange newRange = NSMakeRange(startOfRange, currentLocation + 1 - startOfRange);

            [rangesToBeReplaced addObject:[NSValue valueWithRange:newRange]];
        }
    }



    for(NSInteger counter = rangesToBeReplaced.count-1; counter>=0; counter--)
    {
        NSValue* value = rangesToBeReplaced[counter];

        NSRange newRange = value.rangeValue;

        NSTextAttachment* textAttachment = [[NSTextAttachment alloc] init];

        NSString* tokenText = [[tokenFieldText attributedSubstringFromRange:newRange].string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        MacToken* newToken = nil;

        if([_internalDelegate.externalDelegate respondsToSelector:@selector(tokenForStringComponent:insertAtIndex:)])
            newToken = [_internalDelegate.externalDelegate tokenForStringComponent:tokenText insertAtIndex:-1];

        if(!newToken)
        {
            //only remove tokenising characters
            if(newRange.location+newRange.length<=self.textStorage.length && newRange.length==1)
                [self.textStorage replaceCharactersInRange:newRange withString:@""];
            continue;
        }

        [addedTokens addObject:newToken];

        [textAttachment setAttachmentCell:newToken];

        NSMutableAttributedString* attributedString = [[NSAttributedString attributedStringWithAttachment:textAttachment] mutableCopy];

        if(self.defaultParagraphStyle)
            [attributedString addAttribute:NSParagraphStyleAttributeName value:self.defaultParagraphStyle range:NSMakeRange(0, attributedString.length)];

        if(newRange.location+newRange.length<=self.textStorage.length)
            [self.textStorage replaceCharactersInRange:newRange withAttributedString:attributedString];
    }

    for(MacToken* token in addedTokens)
    {
        if ([_internalDelegate.externalDelegate respondsToSelector:@selector(tokenField:didAddToken:)])
        {
            [_internalDelegate.externalDelegate tokenField:self didAddToken:token];
        }
    }

    [self updateHeight];
}


- (void)didChangeText
{
//    NSMutableAttributedString* newInsertString = nil;
//    if([insertString isKindOfClass:[NSAttributedString class]])
//    {
//        newInsertString = [insertString mutableCopy];
//        [newInsertString addAttributes:@{NSParagraphStyleAttributeName:self.defaultParagraphStyle} range:NSMakeRange(0, newInsertString.length)];
//    }
//    else if([insertString isKindOfClass:[NSString class]])
//    {
//        newInsertString = [[NSMutableAttributedString alloc] initWithString:insertString attributes:@{NSParagraphStyleAttributeName:self.defaultParagraphStyle}];
//    }

    if ([self.string rangeOfCharacterFromSet:self.tokenizingCharacters].location != NSNotFound)
    {
        [self tokeniseText];
    }

    if(!self.isShowingCompletions)
        [self complete:self];


    //[self.textStorage addAttribute:NSBaselineOffsetAttributeName value:@(baselineOffset) range:NSMakeRange(0, self.textStorage.length)];


    if(self.needToUpdateHeightAfterTextChange)
    {
        [self updateHeight];
        self.needToUpdateHeightAfterTextChange = NO;
    }
}


#pragma mark - COMPLETION SUGGESTIONS

- (void)complete:(id)sender
{
    [super complete:sender];
}

- (NSRange)rangeForUserCompletion
{
    NSRange range = [super rangeForUserCompletion];

    //need to extend the range - it should not be terminated by space, "@" etc.

    NSInteger previousLocation = range.location - 1;

    BOOL foundTerminatingCharacter = NO;

    NSMutableCharacterSet* charSet = [NSMutableCharacterSet alphanumericCharacterSet];

    [charSet addCharactersInString:@" @_."];

    while(previousLocation>=0 && !foundTerminatingCharacter)
    {
        NSAttributedString* characterString = [self.textStorage attributedSubstringFromRange:NSMakeRange(previousLocation, 1)];

        if([characterString.string rangeOfCharacterFromSet:charSet].location==NSNotFound)
            foundTerminatingCharacter = YES;
        else
            previousLocation--;
    }

    //if(foundTerminatingCharacter || previousLocation<0)
    previousLocation++;

    NSRange newRange = NSMakeRange(previousLocation, range.length + range.location - previousLocation);
    
    return newRange;
}

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(NSInteger)movement isFinal:(BOOL)flag
{
    switch(movement)
    {
        case NSTabTextMovement:
        case NSReturnTextMovement:

            if(flag)
            {
                [self.textStorage replaceCharactersInRange:charRange withString:word];

                self.isShowingCompletions = NO;

                [self tokeniseText];
            }
            else
            {
                self.isShowingCompletions = YES;

                [super insertCompletion:word forPartialWordRange:charRange movement:movement isFinal:flag];
            }

            break;

        case NSLeftTextMovement:
        case NSRightTextMovement:
        case NSUpTextMovement:
        case NSDownTextMovement:

        case NSOtherTextMovement:
        case NSBacktabTextMovement:
        case NSCancelTextMovement:

            self.isShowingCompletions = NO;

            break;
    }
}




#pragma mark - INSERTION

- (void)insertText:(id)insertString replacementRange:(NSRange)replacementRange
{
//    NSMutableAttributedString* newInsertString = nil;
//    if([insertString isKindOfClass:[NSAttributedString class]])
//    {
//        newInsertString = [insertString mutableCopy];
//        [newInsertString addAttributes:@{NSParagraphStyleAttributeName:self.defaultParagraphStyle, NSBaselineOffsetAttributeName:@(baselineOffset)} range:NSMakeRange(0, newInsertString.length)];
//    }
//    else if([insertString isKindOfClass:[NSString class]])
//    {
//        newInsertString = [[NSMutableAttributedString alloc] initWithString:insertString attributes:@{NSParagraphStyleAttributeName:self.defaultParagraphStyle, NSBaselineOffsetAttributeName:@(baselineOffset)}];
//    }

    //[insertString addAttribute:NSParagraphStyleAttributeName value:self.defaultParagraphStyle range:NSMakeRange(0, self.textStorage.length)];

    [super insertText:insertString replacementRange:replacementRange];
}


#pragma mark - LAYOUT

- (void)updateHeight
{
    //[self.layoutManager invalidateLayoutForCharacterRange:NSMakeRange(0, self.textStorage.length) actualCharacterRange:nil];

    [self.layoutManager glyphRangeForTextContainer:self.textContainer];
    
    CGFloat newHeight = [[self layoutManager] usedRectForTextContainer:[self textContainer]].size.height+15;

    if(newHeight < 29)
    {
        newHeight = 29;
    }

    //NSLog(@"Updated height: %f (%@)", newHeight, self.attributedString);

    [self setContentHeight:newHeight];
    [self.superview.superview invalidateIntrinsicContentSize];
}

- (void)updateWidth
{
    CGFloat minimumWidth = 20;

    for(MacToken* token in _tokens)
    {
        if(token.cellSize.width > minimumWidth)
            minimumWidth = token.cellSize.width;
    }

    self.contentWidth = minimumWidth;
}

- (NSPoint)textContainerOrigin
{
	if ([self.string isEqualToString:kTextHidden])
        return NSMakePoint(0, -20);

	CGRect frame = CGRectOffset(self.bounds, _tokenCaret.x - 2, 6);// _tokenCaret.y + 5 + TEXT_OFFSET);

    return frame.origin;
}

//- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor *)color turnedOn:(BOOL)flag
//{
//    rect.size.height = 29;
//
//    [super drawInsertionPointInRect:rect color:color turnedOn:flag];
//}

#pragma mark - OTHER

- (NSString *)description
{
	return [NSString stringWithFormat:@"<MacTokenField %p; frame: \"{{%f, %f}, {%f, %f}}\">", self, self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height];
}

- (void)dealloc
{
	[self setDelegate:nil];
    
    _internalDelegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


#pragma mark - MacToken

@interface MacToken (Drawing)
CGPathRef CGPathCreateTokenPath(CGSize size, CGPoint offset);
CGPathRef CGPathCreateDisclosureIndicatorPath(CGPoint arrowPointFront, CGFloat height, CGFloat thickness, CGFloat * width);
- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha;

@end

@implementation MacToken
@synthesize title = _title;
@synthesize representedObject = _representedObject;
@synthesize tintColor = _tintColor;
@synthesize textColor = _textColor;
@synthesize highlightedTextColor = _highlightedTextColor;
@synthesize accessoryType = _accessoryType;
@synthesize maxWidth = _maxWidth;

#pragma mark Init
- (instancetype)initWithTitle:(NSString *)aTitle {
    return [self initWithTitle:aTitle representedObject:nil];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object {
    self.font = [NSFont systemFontOfSize:12];
	return [self initWithTitle:aTitle representedObject:object font:[NSFont systemFontOfSize:FONT_SIZE]];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object font:(NSFont*)aFont
{

	if ((self = [super init])){

        [self setFont:aFont];

		_title = [aTitle copy];
		_representedObject = object;

		_tintColor = NAVBAR_COLOUR;
		_textColor = [NSColor whiteColor];
		_highlightedTextColor = [NSColor whiteColor];

		_accessoryType = MacTokenAccessoryTypeNone;
		_maxWidth = 1000;

		//[self setBackgroundColor:[NSColor clearColor]];
		//[self sizeToFit];
	}

	return self;
}

+ (NSAttributedString*)attributedStringWithToken:(MacToken*)token paragraphStyle:(NSParagraphStyle*)paragraphStyle
{
    NSTextAttachment* textAttachment = [NSTextAttachment new];

    [textAttachment setAttachmentCell:token];

    NSMutableAttributedString* newAttributedString = [[NSAttributedString attributedStringWithAttachment:textAttachment] mutableCopy];

    //[newAttributedString addAttribute:NSBaselineOffsetAttributeName value:@(5) range:NSMakeRange(0, newAttributedString.length)];

    [newAttributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, newAttributedString.length)];

    return newAttributedString;
}




#pragma mark Property Overrides

- (void)setTitle:(NSString *)newTitle {

	if (newTitle){
		_title = [newTitle copy];
		//[self sizeToFit];
	}
}


- (void)setTintColor:(NSColor *)newTintColor
{
	if (!newTintColor) newTintColor = DARK_BLUE_COLOUR;

	if (_tintColor != newTintColor){
		_tintColor = newTintColor;
	}
}

- (void)setAccessoryType:(MacTokenAccessoryType)type {

	if (_accessoryType != type){
		_accessoryType = type;
		//[self sizeToFit];
	}
}

- (void)setMaxWidth:(CGFloat)width {

	if (_maxWidth != width){
		_maxWidth = width;
		//[self sizeToFit];
	}
}


#pragma mark - LAYOUT


//- (void)sizeToFit
//{
//    CGSize newSize = [self sizeThatFits:self.frame.size];
//    [self setFrameSize:newSize];
//}

- (CGPoint)cellBaselineOffset
{
    return (CGPoint){0, -5};
}

- (CGSize)sizeThatFits:(CGSize)size
{
    NSFont* usedFont = [NSFont systemFontOfSize:12];

	CGFloat accessoryWidth = 0;

	if (_accessoryType == MacTokenAccessoryTypeDisclosureIndicator){
		CGPathRelease(CGPathCreateDisclosureIndicatorPath(CGPointZero, self.font.pointSize, kDisclosureThickness, &accessoryWidth));
		accessoryWidth += floorf(hTextPadding / 2);
	}

    NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

    [paragraphStyle setLineBreakMode:kLineBreakMode];

    CGRect titleRect = [_title boundingRectWithSize:CGSizeMake((_maxWidth - hTextPadding - accessoryWidth), MAXFLOAT) options:0 attributes:@{NSParagraphStyleAttributeName:paragraphStyle,NSFontAttributeName:usedFont}];
    CGFloat height = floorf(titleRect.size.height + vTextPadding);

    return (CGSize){2*hTextMargin + MAX(ceilf(titleRect.size.width + hTextPadding + accessoryWidth), height - 3), height};
}

#pragma mark - DRAWING


CGPathRef CGPathCreateTokenPath(CGSize size, CGPoint offset)
{
	CGMutablePathRef path = CGPathCreateMutable();
	CGFloat arcValue = size.height / 2;
	CGFloat radius = arcValue;
	CGPathAddArc(path, NULL, hTextMargin + offset.x + arcValue, offset.y + arcValue, radius, (M_PI / 2), (M_PI * 3 / 2), NO);
	CGPathAddArc(path, NULL, - hTextMargin + offset.x + size.width - arcValue, offset.y + arcValue, radius, (M_PI  * 3 / 2), (M_PI / 2), NO);
	CGPathCloseSubpath(path);

	return path;
}

CGPathRef CGPathCreateDisclosureIndicatorPath(CGPoint arrowPointFront, CGFloat height, CGFloat thickness, CGFloat * width) {

	thickness /= cosf(M_PI / 4);

	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, arrowPointFront.x, arrowPointFront.y);

	CGPoint bottomPointFront = CGPointMake(arrowPointFront.x - (height / (2 * tanf(M_PI / 4))), arrowPointFront.y - height / 2);
	CGPathAddLineToPoint(path, NULL, bottomPointFront.x, bottomPointFront.y);

	CGPoint bottomPointBack = CGPointMake(bottomPointFront.x - thickness * cosf(M_PI / 4),  bottomPointFront.y + thickness * sinf(M_PI / 4));
	CGPathAddLineToPoint(path, NULL, bottomPointBack.x, bottomPointBack.y);

	CGPoint arrowPointBack = CGPointMake(arrowPointFront.x - thickness / cosf(M_PI / 4), arrowPointFront.y);
	CGPathAddLineToPoint(path, NULL, arrowPointBack.x, arrowPointBack.y);

	CGPoint topPointFront = CGPointMake(bottomPointFront.x, arrowPointFront.y + height / 2);
	CGPoint topPointBack = CGPointMake(bottomPointBack.x, topPointFront.y - thickness * sinf(M_PI / 4));

	CGPathAddLineToPoint(path, NULL, topPointBack.x, topPointBack.y);
	CGPathAddLineToPoint(path, NULL, topPointFront.x, topPointFront.y);
	CGPathAddLineToPoint(path, NULL, arrowPointFront.x, arrowPointFront.y);

	if (width) *width = (arrowPointFront.x - topPointBack.x);
	return path;
}

- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha highlighted:(BOOL)highlighted
{
    NSColor* color = highlighted?self.highlightTintColor:self.tintColor;

	CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor));
	const CGFloat * components = CGColorGetComponents(color.CGColor);

	if (colorSpaceModel == kCGColorSpaceModelMonochrome || colorSpaceModel == kCGColorSpaceModelRGB){

		if (red) *red = components[0];
		if (green) *green = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[1]);
		if (blue) *blue = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[2]);
		if (alpha) *alpha = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[1] : components[3]);

		return YES;
	}

	return NO;
}

#pragma mark - OTHER

- (NSString *)description
{
	return [NSString stringWithFormat:@"<MacToken %p; title = \"%@\"; representedObject = \"%@\", cell size = \"{%f, %f}\">", self, _title, _representedObject, self.cellSize.width, self.cellSize.height];
}


- (NSSize)cellSize
{
    return [self sizeThatFits:NSMakeSize(0, 0)];
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager
{
//    CGFloat gb = [[NSTypesetter sharedSystemTypesetter] baselineOffsetInLayoutManager:layoutManager glyphIndex:charIndex];
//
//    NSRect useFrame = cellFrame;
//    useFrame.origin.y += gb;

    NSFont* usedFont = [NSFont systemFontOfSize:12];

    CGPoint offset = cellFrame.origin;

    CGSize cellSize = self.cellSize;

 	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];

    if(!context)
    {
        NSLog(@"Attempting to draw with invalid context!!!");
        return;
    }

 	// Draw the outline
	CGContextSaveGState(context);
	CGPathRef outlinePath = CGPathCreateTokenPath(cellSize, offset);
	CGContextAddPath(context, outlinePath);
	CGPathRelease(outlinePath);

    BOOL drawHighlighted = self.isHighlighted;

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGPoint endPoint = CGPointMake(0, cellSize.height + offset.y);

	CGFloat red = 1;
	CGFloat green = 1;
	CGFloat blue = 1;
	CGFloat alpha = 1;
	[self getTintColorRed:&red green:&green blue:&blue alpha:&alpha highlighted:drawHighlighted];

    CGContextSetFillColor(context, (CGFloat[4]){red , green, blue, 1});
    CGContextFillPath(context);

	CGContextRestoreGState(context);

	CGPathRef innerPath = CGPathCreateTokenPath(cellSize, offset);

	CGContextSaveGState(context);
	CGContextAddPath(context, innerPath);
	CGPathRelease(innerPath);
	CGContextClip(context);

	//CGFloat locations[2] = {0, (drawHighlighted ? 1 : 1)};
    CGFloat highlightedComp[8] = {red, green, blue, 0.8, red, green, blue, .9};
    CGFloat nonHighlightedComp[8] = {red, green, blue, .9, red, green, blue, 1};

	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, (drawHighlighted ? highlightedComp : nonHighlightedComp), /*locations*/NULL, 2);
	CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
	CGGradientRelease(gradient);
	CGContextRestoreGState(context);

	CGFloat accessoryWidth = 0;

	if (_accessoryType == MacTokenAccessoryTypeDisclosureIndicator){
		CGPoint arrowPoint = CGPointMake(cellSize.width - floorf(hTextPadding / 2), (cellSize.height / 2) - 1);
		CGPathRef disclosurePath = CGPathCreateDisclosureIndicatorPath(arrowPoint, usedFont.pointSize, kDisclosureThickness, &accessoryWidth);
		accessoryWidth += floorf(hTextPadding / 2);

		CGContextAddPath(context, disclosurePath);
		CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});

		if (drawHighlighted){
			CGContextFillPath(context);
		}
		else
		{
			CGContextSaveGState(context);
			CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 1, [[[NSColor whiteColor] colorWithAlphaComponent:0.6] CGColor]);
			CGContextFillPath(context);
			CGContextRestoreGState(context);

			CGContextSaveGState(context);
			CGContextAddPath(context, disclosurePath);
			CGContextClip(context);

			CGGradientRef disclosureGradient = CGGradientCreateWithColorComponents(colorspace, highlightedComp, NULL, 2);
			CGContextDrawLinearGradient(context, disclosureGradient, CGPointZero, endPoint, 0);
			CGGradientRelease(disclosureGradient);

			arrowPoint.y += 0.5;
			CGPathRef innerShadowPath = CGPathCreateDisclosureIndicatorPath(arrowPoint, usedFont.pointSize, kDisclosureThickness, NULL);
			CGContextAddPath(context, innerShadowPath);
			CGPathRelease(innerShadowPath);
			CGContextSetStrokeColor(context, (CGFloat[4]){0, 0, 0, 0.3});
			CGContextStrokePath(context);
			CGContextRestoreGState(context);
		}

		CGPathRelease(disclosurePath);
	}

	CGColorSpaceRelease(colorspace);

    CGRect textRect = [_title boundingRectWithSize:CGSizeMake((_maxWidth - hTextPadding - accessoryWidth), MAXFLOAT) options:0 attributes:@{NSFontAttributeName:usedFont}];

    CGSize titleSize = textRect.size; //[_title sizeWithFont:_font forWidth:(_maxWidth - hTextPadding - accessoryWidth) lineBreakMode:kLineBreakMode];
    CGFloat vPadding = floor((cellSize.height - titleSize.height) / 2);
	CGFloat titleWidth = ceilf(cellSize.width - hTextPadding - accessoryWidth);
	CGRect textBounds = CGRectMake(floorf(hTextPadding / 2), vPadding - 1, titleWidth, floorf(cellSize.height - (vPadding * 2)));

    textBounds = NSOffsetRect(textBounds, hTextMargin + offset.x, offset.y);

	NSMutableParagraphStyle *style = defaultParagraphStyle;

    //CGContextSetFillColorWithColor(context, (drawHighlighted ? _highlightedTextColor : _textColor).CGColor);
	[_title drawInRect:textBounds withAttributes:@{NSFontAttributeName:usedFont, NSForegroundColorAttributeName:(drawHighlighted ? _highlightedTextColor : _textColor),NSParagraphStyleAttributeName: style}];
}


//- (void)highlight:(BOOL)flag withFrame:(NSRect)cellFrame inView:(NSView *)aView
//{
//    [self setHighlighted:flag];
//    [super highlight:flag withFrame:cellFrame inView:aView];
//}


@end


@implementation EmptyToken

- (NSSize)cellSize
{
    return (NSSize){0, 19};
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView characterIndex:(NSUInteger)charIndex layoutManager:(NSLayoutManager *)layoutManager
{
    //don't need to draw anything
}

+ (NSAttributedString*)emptyString
{
    NSTextAttachment* textAttachment = [[NSTextAttachment alloc] init];

    EmptyToken* newToken = [EmptyToken new];

    [textAttachment setAttachmentCell:newToken];

    NSAttributedString* attributedString = [NSAttributedString attributedStringWithAttachment:textAttachment];

    return attributedString;
}

@end
