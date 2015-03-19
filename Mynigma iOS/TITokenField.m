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





#import "TITokenField.h"
#import <QuartzCore/QuartzCore.h>
#import "IconListAndColourHelper.h"
#import "Recipient.h"
#import "Contact.h"
#import "EmailContactDetail+Category.h"

#define PROMPT_FONT_SIZE 17
#define TOKEN_FONT_SIZE 17

#define PROMPT_OFFSET 0
#define TEXT_OFFSET -3
#define TOKENS_OFFSET 0

@protocol AdjustHeightProtocol <NSObject>

- (void)adjustField:(TITokenField*)tokenField toHeight:(NSNumber*)height;

@end

@interface TITokenField ()
@property (nonatomic, assign) BOOL forcePickSearchResult;
@end

//==========================================================
#pragma mark - TITokenFieldView -
//==========================================================

@interface TITokenFieldView (Private)
- (void)setup;
- (NSString *)displayStringForRepresentedObject:(id)object;
- (NSString *)searchResultStringForRepresentedObject:(id)object;
- (void)setSearchResultsVisible:(BOOL)visible;
- (void)resultsForSearchString:(NSString *)searchString;
- (void)presentpopoverAtTokenFieldCaretAnimated:(BOOL)animated;
@end

@implementation TITokenFieldView {
	UIView * _contentView;
	NSMutableArray * _resultsArray;
	UIPopoverController * _popoverController;
}
#if TARGET_OS_IPHONE
@dynamic delegate;
#endif
@synthesize showAlreadyTokenized = _showAlreadyTokenized;
@synthesize searchSubtitles = _searchSubtitles;
@synthesize forcePickSearchResult = _forcePickSearchResult;
@synthesize shouldSortResults = _shouldSortResults;
@synthesize shouldSearchInBackground = _shouldSearchInBackground;
@synthesize permittedArrowDirections = _permittedArrowDirections;
@synthesize tokenField = _tokenField;
@synthesize resultsTable = _resultsTable;
//@synthesize contentView = _contentView;
@synthesize separator = _separator;
@synthesize sourceArray = _sourceArray;






- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    return CGRectContainsPoint(self.frame, point);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if([self.tokenField pointInside:point withEvent:event])
        return self.tokenField;

    return nil;
}






#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])){
		[self setup];
	}
	
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self setup];
	}
	
	return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup {

	_showAlreadyTokenized = NO;
    _searchSubtitles = YES;
    _forcePickSearchResult = NO;
	_resultsArray = [NSMutableArray array];

    [self.tableViewHeightConstraint setConstant:0];

	[_tokenField addTarget:self action:@selector(tokenFieldDidBeginEditing:) forControlEvents:UIControlEventEditingDidBegin];
	[_tokenField addTarget:self action:@selector(tokenFieldDidEndEditing:) forControlEvents:UIControlEventEditingDidEnd];
	[_tokenField addTarget:self action:@selector(tokenFieldTextDidChange:) forControlEvents:UIControlEventEditingChanged];
	[_tokenField addTarget:self action:@selector(tokenFieldFrameWillChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];
	[_tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];

    /*
    [self.layer setMasksToBounds:NO];
    [self.layer setShadowRadius:12];
    [self.layer setShadowColor:[UIColor grayColor].CGColor];
    [self.layer setShadowOpacity:1];
     */

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){

//		UITableViewController * tableViewController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
//		[tableViewController.tableView setDelegate:self];
//		[tableViewController.tableView setDataSource:self];
//		[tableViewController setPreferredContentSize:CGSizeMake(400, 400)];
//
//		_resultsTable = tableViewController.tableView;

//		_popoverController = [[UIPopoverController alloc] initWithContentViewController:tableViewController];
	}
	else
	{
		[_resultsTable setSeparatorColor:[UIColor colorWithWhite:0.85 alpha:1]];
		[_resultsTable setBackgroundColor:[UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1]];
		[_resultsTable setHidden:YES];

		_popoverController = nil;
	}

    [self updateContentSize];
}

#pragma mark Property Overrides
- (void)setFrame:(CGRect)frame {
	
	[super setFrame:frame];
	
	//CGFloat width = frame.size.width;
	//[_separator setFrame:((CGRect){_separator.frame.origin, {width, _separator.bounds.size.height}})];
	//[_resultsTable setFrame:((CGRect){_resultsTable.frame.origin, {width, _resultsTable.bounds.size.height}})];
	//[_contentView setFrame:((CGRect){_contentView.frame.origin, {width, (frame.size.height - CGRectGetMaxY(_tokenField.frame))}})];
	//[_tokenField setFrame:((CGRect){_tokenField.frame.origin, {width, _tokenField.bounds.size.height}})];

#if TARGET_OS_IPHONE
	if (_popoverController.popoverVisible)
    {
		[_popoverController dismissPopoverAnimated:NO];
		[self presentpopoverAtTokenFieldCaretAnimated:NO];
	}
#endif

	[self updateContentSize];
#if TARGET_OS_IPHONE
	[self setNeedsLayout];
#endif
}

- (void)setContentOffset:(CGPoint)offset {
#if TARGET_OS_IPHONE
	[super setContentOffset:offset];
	[self setNeedsLayout];
#endif
}

- (NSArray *)tokenTitles {
	return _tokenField.tokenTitles;
}

- (void)setForcePickSearchResult:(BOOL)forcePickSearchResult
{
    _tokenField.forcePickSearchResult = forcePickSearchResult;
    _forcePickSearchResult = forcePickSearchResult;
}

#pragma mark Event Handling
- (void)layoutSubviews {

    [super layoutSubviews];

	//CGFloat relativeFieldHeight = CGRectGetMaxY(_tokenField.frame) - self.contentOffset.y;
	//CGFloat newHeight = self.bounds.size.height - relativeFieldHeight;
	//omif (newHeight > -1) [_resultsTable setFrame:((CGRect){_resultsTable.frame.origin, {_resultsTable.bounds.size.width, newHeight}})];

}

- (void)updateContentSize {

    [self.superview.superview invalidateIntrinsicContentSize];
    //[self setContentSize:CGSizeMake(self.bounds.size.width, CGRectGetMaxY(_contentView.frame) + 1)];
}


- (BOOL)canBecomeFirstResponder {
	return [_tokenField canBecomeFirstResponder];
}

- (BOOL)becomeFirstResponder {

    BOOL result = [_tokenField becomeFirstResponder];

    if(_tokenField.usePreparedResults)
    {
        [self reloadResultsTable];
    }

    return result;
}

- (BOOL)resignFirstResponder {

    if(_resultsArray.count>0)
    {
        [_resultsArray removeAllObjects];
        [self reloadResultsTable];
    }

	return [_tokenField resignFirstResponder];
}

#pragma mark TableView Methods
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
//	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:resultsTableView:heightForRowAtIndexPath:)]){
//		return [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField resultsTableView:tableView heightForRowAtIndexPath:indexPath];
//	}

	return 44;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	
//	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:didFinishSearch:)]){
//		[(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField didFinishSearch:_resultsArray];
//	}

    //NSLog(@"Table view rows: %ld, height: %f, constraint: %f", (unsigned long)_resultsArray.count, tableView.bounds.size.height, self.tableViewHeightConstraint.constant);

	return _resultsArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	NSManagedObjectID* representedObject = [_resultsArray objectAtIndex:indexPath.row];
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:resultsTableView:cellForRepresentedObject:)])
    {
		return [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField resultsTableView:tableView cellForRepresentedObject:representedObject];
	}
	
    static NSString * CellIdentifier = @"MynTokenCell";
    UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    NSString * subtitle = [self searchResultSubtitleForRepresentedObject:representedObject];
	
	if (!cell) cell = [[UITableViewCell alloc] initWithStyle:(subtitle ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault) reuseIdentifier:CellIdentifier];
	
	[cell.textLabel setText:[self searchResultStringForRepresentedObject:representedObject]];
    [cell.textLabel setTextColor:self.tintColor];
	[cell.detailTextLabel setText:subtitle];
    [cell.detailTextLabel setTextColor:self.tintColor];
	
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSManagedObjectID* representedObjectID = [_resultsArray objectAtIndex:indexPath.row];

    if([representedObjectID isKindOfClass:[Recipient class]])
    {
        if(_tokenField.usePreparedResults)
            [_tokenField removeAllTokens];

        TIToken * token = [[TIToken alloc] initWithTitle:[self displayStringForRepresentedObject:representedObjectID] representedObject:representedObjectID];

        [_tokenField addToken:token];

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self setSearchResultsVisible:NO];

        return;
    }

    if(!representedObjectID)
        return;

    NSManagedObject* managedObject = [MAIN_CONTEXT existingObjectWithID:representedObjectID error:nil];

    if(![managedObject isKindOfClass:[Contact class]] && ![managedObject isKindOfClass:[EmailContactDetail class]])
        return;

    Recipient* recipient = nil;

    if([managedObject isKindOfClass:[EmailContactDetail class]])
        recipient = [[Recipient alloc] initWithEmailContactDetail:(EmailContactDetail*)managedObject];

    if([managedObject isKindOfClass:[Contact class]])
        recipient = [[Recipient alloc] initWithContact:(Contact*)managedObject];

    TIToken * token = [[TIToken alloc] initWithTitle:[self displayStringForRepresentedObject:recipient] representedObject:recipient];

    [_tokenField addToken:token];
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self setSearchResultsVisible:NO];
}

#pragma mark TextField Methods

- (void)tokenFieldDidBeginEditing:(TITokenField *)field {
    if(!self.tokenField.usePreparedResults)
        [_resultsArray removeAllObjects];
	[_resultsTable reloadData];
}

- (void)tokenFieldDidEndEditing:(TITokenField *)field {
	[self tokenFieldDidBeginEditing:field];
}

- (void)tokenFieldTextDidChange:(TITokenField *)field {
    [self resultsForSearchString:_tokenField.text];
    
    if (_forcePickSearchResult) {
        [self setSearchResultsVisible:YES];
    } else {
        [self setSearchResultsVisible:(_resultsArray.count > 0)];
    }

}

- (void)tokenFieldFrameWillChange:(TITokenField *)field {

	//CGFloat tokenFieldBottom = CGRectGetMaxY(_tokenField.frame);
	//[_separator setFrame:((CGRect){{_separator.frame.origin.x, tokenFieldBottom}, _separator.bounds.size})];
	//[_resultsTable setFrame:((CGRect){{_resultsTable.frame.origin.x, (tokenFieldBottom + 1)}, _resultsTable.bounds.size})];


	//[_contentView setFrame:((CGRect){{_contentView.frame.origin.x, (tokenFieldBottom + 1)}, _contentView.bounds.size})];
}

- (void)tokenFieldFrameDidChange:(TITokenField *)field {
	[self updateContentSize];
}

#pragma mark Results Methods
- (NSString *)displayStringForRepresentedObject:(id)object {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:displayStringForRepresentedObject:)]){
		return [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField displayStringForRepresentedObject:object];
	}
	
	if ([object isKindOfClass:[NSString class]]){
		return (NSString *)object;
	}
	
	return [NSString stringWithFormat:@"%@", object];
}

- (NSString *)searchResultStringForRepresentedObject:(id)object {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultStringForRepresentedObject:)]){
		return [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField searchResultStringForRepresentedObject:object];
	}
	
	return [self displayStringForRepresentedObject:object];
}

- (NSString *)searchResultSubtitleForRepresentedObject:(id)object {
	
	if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultSubtitleForRepresentedObject:)]){
		return [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField searchResultSubtitleForRepresentedObject:object];
	}
	
	return nil;
}

- (UIImage *)searchResultImageForRepresentedObject:(id)object {
    if ([_tokenField.delegate respondsToSelector:@selector(tokenField:searchResultImageForRepresentedObject:)]) {
        return [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField searchResultImageForRepresentedObject:object];
    }
    
    return nil;
}


- (void)setSearchResultsVisible:(BOOL)visible {
//	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
//		
//		if (visible) [self presentpopoverAtTokenFieldCaretAnimated:YES];
//		else [_popoverController dismissPopoverAnimated:YES];
//	}
//	else
	{
		[_resultsTable setHidden:!visible];

        if(visible)
            [self reloadResultsTable];
        else
        {
            [self.tableViewHeightConstraint setConstant:0];

            [_resultsTable setNeedsLayout];

            [_resultsTable layoutIfNeeded];

            [self.superview.superview invalidateIntrinsicContentSize];
        }


        [_tokenField setResultsModeEnabled:visible];
	}
}

- (void)resultsForSearchString:(NSString *)searchString {
	
	// The brute force searching method.
	// Takes the input string and compares it against everything in the source array.
	// If the source is massive, this could take some time.
	// You could always subclass and override this if needed or do it on a background thread.
	// GCD would be great for that.
	if(!self.tokenField.usePreparedResults)
        [_resultsArray removeAllObjects];

    [_resultsTable reloadData];
	
	searchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if(searchString.length==0)
    {
        if(!_forcePickSearchResult)
        {
            [_resultsArray removeAllObjects];
            [self reloadResultsTable];
            return;
        }
    }

    if(searchString.length || _forcePickSearchResult){

        if ([(id<TITokenFieldDelegate>)_tokenField.delegate respondsToSelector:@selector(tokenField:shouldUseCustomSearchForSearchString:)] && [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField shouldUseCustomSearchForSearchString:searchString]) {
            if ([_tokenField.delegate respondsToSelector:@selector(tokenField:performCustomSearchForSearchString:withCompletionHandler:)]) {
                [(id<TITokenFieldDelegate>)_tokenField.delegate tokenField:_tokenField performCustomSearchForSearchString:searchString withCompletionHandler:^(NSArray *results) {
                    [self searchDidFinish:results];
                }];
            }
        } else {

            if (_shouldSearchInBackground) {
                [self performSelectorInBackground:@selector(performSearch:) withObject:searchString];
            } else {
                [self performSearch:searchString];
            }
        }
	}
}

- (void) performSearch:(NSString *)searchString {

    if(self.tokenField.usePreparedResults)
    {
        [self searchDidFinish:@[]];
        return;
    }

  NSMutableArray * resultsToAdd = [[NSMutableArray alloc] init];
  [_sourceArray enumerateObjectsUsingBlock:^(id sourceObject, NSUInteger idx, BOOL *stop){

    NSString * query = [self searchResultStringForRepresentedObject:sourceObject];
    NSString * querySubtitle = [self searchResultSubtitleForRepresentedObject:sourceObject];
    if (!querySubtitle || !_searchSubtitles) querySubtitle = @"";
    
    if ([query rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
				[querySubtitle rangeOfString:searchString options:NSCaseInsensitiveSearch].location != NSNotFound ||
        (_forcePickSearchResult && searchString.length == 0)){

      __block BOOL shouldAdd = ![resultsToAdd containsObject:sourceObject];
      if (shouldAdd && !_showAlreadyTokenized){

        [_tokenField.tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *secondStop){
          if ([token.representedObject isEqual:sourceObject]){
            shouldAdd = NO;
            *secondStop = YES;
          }
        }];
      }

      if (shouldAdd) [resultsToAdd addObject:sourceObject];
    }
  }];

    [self searchDidFinish:resultsToAdd];
}

- (void)searchDidFinish:(NSArray *)results
{
    if(self.tokenField.usePreparedResults)
    {
        _resultsArray = [_sourceArray mutableCopy];
    }
    else
    {
        [_resultsArray addObjectsFromArray:results];
        if (_resultsArray.count > 0) {
            if (_shouldSortResults) {
                [_resultsArray sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    return [[self searchResultStringForRepresentedObject:obj1] localizedCaseInsensitiveCompare:[self searchResultStringForRepresentedObject:obj2]];
                }];
            }
        }
    }

    [self performSelectorOnMainThread:@selector(reloadResultsTable) withObject:nil waitUntilDone:YES];
}

-(void) reloadResultsTableAnimated:(BOOL)animated
{
    [_resultsTable setHidden:NO];

    NSInteger numberOfResults = _resultsArray.count;

    CGFloat tableViewHeight = numberOfResults*44;

    if(!self.tokenField.usePreparedResults && numberOfResults>4)
        tableViewHeight = 4*44;

    [self.tableViewHeightConstraint setConstant:tableViewHeight];

    if(animated)
    {
    [UIView animateWithDuration:0.1 animations:^{

        [_resultsTable setNeedsLayout];

        [_resultsTable layoutIfNeeded];

        [_resultsTable reloadData];

        [self.superview.superview invalidateIntrinsicContentSize];
    }];
    }
    else
    {

        [_resultsTable setNeedsLayout];

        [_resultsTable layoutIfNeeded];

        [_resultsTable reloadData];

        [self.superview.superview invalidateIntrinsicContentSize];

    }

}


-(void) reloadResultsTable {

    [_resultsTable setHidden:NO];

    NSInteger numberOfResults = _resultsArray.count;

    CGFloat tableViewHeight = numberOfResults*44;

    if(!self.tokenField.usePreparedResults && numberOfResults>4)
        tableViewHeight = 4*44;

        [self.tableViewHeightConstraint setConstant:tableViewHeight];

        [UIView animateWithDuration:0.1 animations:^{

            [_resultsTable setNeedsLayout];

            [_resultsTable layoutIfNeeded];

            [_resultsTable reloadData];

            [self.superview.superview invalidateIntrinsicContentSize];
        }];
}

- (void)presentpopoverAtTokenFieldCaretAnimated:(BOOL)animated {

#if TARGET_OS_IPHONE
    UITextPosition * position = [_tokenField positionFromPosition:_tokenField.beginningOfDocument offset:2];

    if(_tokenField.window)
        [_popoverController presentPopoverFromRect:[_tokenField caretRectForPosition:position] inView:_tokenField
					 permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
#endif
	//[_popoverController presentPopoverFromRect:[_tokenField caretRectForPosition:position] inView:_tokenField permittedArrowDirections:[self permittedArrowDirections] animated:animated];
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TITokenFieldView %p; Token count = %lu>", self, (unsigned long)self.tokenTitles.count];
}

- (void)dealloc {
	[self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenField -
//==========================================================
NSString * const kTextEmpty = @"\u200B"; // Zero-Width Space
NSString * const kTextHidden = @"\u200D"; // Zero-Width Joiner

@interface TITokenFieldInternalDelegate ()
@property (nonatomic, weak) id <UITextFieldDelegate> delegate;
@property (nonatomic, weak) TITokenField * tokenField;
@end

@interface TITokenField ()
@property (nonatomic, readonly) CGFloat leftViewWidth;
@property (nonatomic, readonly) CGFloat rightViewWidth;
@property (weak, nonatomic, readonly) UIScrollView * scrollView;
@end

@interface TITokenField (Private)
- (void)setup;
- (CGFloat)layoutTokensInternal;
@end

@implementation TITokenField {
	//id __weak delegate;
	TITokenFieldInternalDelegate * _internalDelegate;
	NSMutableArray * _tokens;
	CGPoint _tokenCaret;
    UILabel * _placeHolderLabel;
}
@synthesize delegate = delegate;
@synthesize editable = _editable;
@synthesize resultsModeEnabled = _resultsModeEnabled;
@synthesize removesTokensOnEndEditing = _removesTokensOnEndEditing;
@synthesize numberOfLines = _numberOfLines;
@synthesize selectedToken = _selectedToken;
@synthesize tokenizingCharacters = _tokenizingCharacters;
@synthesize forcePickSearchResult = _forcePickSearchResult;


#pragma mark Init
- (instancetype)initWithFrame:(CGRect)frame {
	
    if ((self = [super initWithFrame:frame])){
		[self setup];
    }
	
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	
	if ((self = [super initWithCoder:aDecoder])){
		[self setup];
	}
	
	return self;
}

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup {

    _tokenLimit = -1;

    _usePreparedResults = NO;

	[self addTarget:self action:@selector(didBeginEditing) forControlEvents:UIControlEventEditingDidBegin];
	[self addTarget:self action:@selector(didEndEditing) forControlEvents:UIControlEventEditingDidEnd];
	[self addTarget:self action:@selector(didChangeText) forControlEvents:UIControlEventEditingChanged];

	[self.layer setShadowColor:[[UIColor blackColor] CGColor]];
	[self.layer setShadowOpacity:0.6];
	[self.layer setShadowRadius:12];
	
	[self setPromptText:@"To:"];
	[self setText:kTextEmpty];
	
	_internalDelegate = [[TITokenFieldInternalDelegate alloc] init];
	[_internalDelegate setTokenField:self];
	[super setDelegate:_internalDelegate];
	
	_tokens = [NSMutableArray array];
	_editable = YES;
	_removesTokensOnEndEditing = NO;
	_tokenizingCharacters = [NSCharacterSet characterSetWithCharactersInString:@","];

    [self setResultsModeEnabled:YES];

    [self.scrollView setBounces:NO];
    [self.scrollView setScrollEnabled:NO];
    [self.scrollView setShowsHorizontalScrollIndicator:NO];
    [self.scrollView setShowsVerticalScrollIndicator:NO];
}

#pragma mark Property Overrides
- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	//[self.layer setShadowPath:[[UIBezierPath bezierPathWithRect:self.bounds] CGPath]];
	[self layoutTokensAnimated:NO];
}

- (void)setText:(NSString *)text {
	[super setText:(text.length == 0 ? kTextEmpty : text)];
}

- (void)setFont:(UIFont *)font {
	[super setFont:font];
	
	if ([self.leftView isKindOfClass:[UILabel class]]){
		[self setPromptText:((UILabel *)self.leftView).text];
	}
}

- (void)setDelegate:(id<TITokenFieldDelegate>)del
{
	delegate = del;
	[_internalDelegate setDelegate:delegate];
}

- (NSArray *)tokens
{
	return [_tokens copy];
}

- (NSArray *)tokenTitles
{
	NSMutableArray * titles = [NSMutableArray array];
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		if (token.title) [titles addObject:token.title];
	}];
	return titles;
}

- (NSArray *)tokenObjects
{
	NSMutableArray * objects = [NSMutableArray array];
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		if (token.representedObject) [objects addObject:token.representedObject];
		else if (token.title) [objects addObject:token.title];
	}];
	return objects;
}

- (UIScrollView *)scrollView {
	return ([self.superview isKindOfClass:[UIScrollView class]] ? (UIScrollView *)self.superview : nil);
}

#pragma mark Event Handling
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    if([self canBecomeFirstResponder])
        [self becomeFirstResponder];
}


- (BOOL)canBecomeFirstResponder {

    if(self.usePreparedResults)
    {
        return self.tokens.count>0;
    }

	return (_editable ? [super canBecomeFirstResponder] : NO);
}

- (BOOL)becomeFirstResponder
{
    if(self.usePreparedResults)
    {
        if(self.tokens.count>0)
        {
            TIToken* token = self.tokens[0];

            [token setSelected:YES];

            [self setEditable:NO];

            BOOL result = [super becomeFirstResponder];

            [self endEditing:YES];

            [(TITokenFieldView*)self.superview performSearch:@""];

            [(TITokenFieldView*)self.superview reloadResultsTableAnimated:NO];

            return result;
        }
    }

	return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {

    if([[(TITokenFieldView*)self.superview resultsArray] count]>0)
    {
        [self setText:@""];
        [[(TITokenFieldView*)self.superview resultsArray] removeAllObjects];
        if(!self.usePreparedResults)
            [(TITokenFieldView*)self.superview performSearch:@""];
        [(TITokenFieldView*)self.superview reloadResultsTableAnimated:NO];
    }

	return [super resignFirstResponder];
}

- (void)didBeginEditing {
    if (_removesTokensOnEndEditing) {
        	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[self addToken:token];}];
    }
}

- (void)didEndEditing {
	
	[_selectedToken setSelected:NO];
	_selectedToken = nil;
	
	[self tokenizeText];
	
	if (_removesTokensOnEndEditing){
		
		[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){[token removeFromSuperview];}];
		
		NSString * untokenized = kTextEmpty;
		if (_tokens.count){
			
			NSArray * titles = self.tokenTitles;
			untokenized = [titles componentsJoinedByString:@", "];
			
			CGSize untokSize = [untokenized sizeWithAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:TOKEN_FONT_SIZE]}];
			CGFloat availableWidth = self.bounds.size.width - self.leftView.bounds.size.width - self.rightView.bounds.size.width;
			
			if (_tokens.count > 1 && untokSize.width > availableWidth){
				untokenized = [NSString stringWithFormat:@"%lu recipients", (unsigned long)titles.count];
			}
			
		}
		
		[self setText:untokenized];
	}
	
	[self setResultsModeEnabled:NO];
	if (_tokens.count < 1 && self.forcePickSearchResult)
    {
		[self becomeFirstResponder];
	}
}

- (void)didChangeText {
	//if (!self.text.length)[self setText:kTextEmpty];
	//[self showOrHidePlaceHolderLabel];
}


- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
	
	// Stop the cut, copy, select and selectAll appearing when the field is 'empty'.
	if (action == @selector(cut:) || action == @selector(copy:) || action == @selector(select:) || action == @selector(selectAll:))
		return ![self.text isEqualToString:kTextEmpty];
	
	return [super canPerformAction:action withSender:sender];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
	
	if (_selectedToken && touch.view == self) [self deselectSelectedToken];
	return [super beginTrackingWithTouch:touch withEvent:event];
}

#pragma mark Token Handling
- (TIToken *)addTokenWithTitle:(NSString *)title {
	return [self addTokenWithTitle:title representedObject:nil];
}

- (TIToken *)addTokenWithTitle:(NSString *)title representedObject:(id)object {
	
	if (title.length){
		TIToken * token = [[TIToken alloc] initWithTitle:title representedObject:object font:self.font];
		[self addToken:token];
		return token;
	}
	
	return nil;
}

- (void)addTokensWithTitleList:(NSString *)titleList {
    if ([titleList length] > 0) {
        self.text = titleList;
        [self tokenizeText];
    }
}

- (void)addTokensWithTitleArray:(NSArray *)titleArray {
    for (NSString *title in titleArray) {
        [self addTokenWithTitle:title];
    }
}

- (void)addToken:(TIToken *)token {
	
	BOOL shouldAdd = YES;
	if ([delegate respondsToSelector:@selector(tokenField:willAddToken:)]){
		shouldAdd = [(id<TITokenFieldDelegate>)delegate tokenField:self willAddToken:token];
	}
	
	if (shouldAdd){
		
		//[self becomeFirstResponder];
		
		[token addTarget:self action:@selector(tokenTouchDown:) forControlEvents:UIControlEventTouchDown];
		[token addTarget:self action:@selector(tokenTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:token];
		
//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
//        [token addGestureRecognizer:tap];


		if (![_tokens containsObject:token]) {
			[_tokens addObject:token];
		
			if ([delegate respondsToSelector:@selector(tokenField:didAddToken:)]){
				[(id<TITokenFieldDelegate>)delegate tokenField:self didAddToken:token];
			}
            
			//[self showOrHidePlaceHolderLabel];
		}

        //[self layoutTokensAnimated:YES];
		
		[self setResultsModeEnabled:NO];
		[self deselectSelectedToken];
	}
}

//- (IBAction)handleTapGesture:(UITapGestureRecognizer*)tapRecogniser
//{
//    UIView* targetToken = tapRecogniser.view;
//
//
//}

- (void)removeToken:(TIToken *)token {
	
	if (token == _selectedToken) [self deselectSelectedToken];
	
	BOOL shouldRemove = YES;
	if ([delegate respondsToSelector:@selector(tokenField:willRemoveToken:)]){
		shouldRemove = [(id<TITokenFieldDelegate>)delegate tokenField:self willRemoveToken:token];
	}
	
	if (shouldRemove){

		[token removeFromSuperview];
		[_tokens removeObject:token];
		
		if ([delegate respondsToSelector:@selector(tokenField:didRemoveToken:)]){
			[(id<TITokenFieldDelegate>)delegate tokenField:self didRemoveToken:token];
		}
		
		//[self showOrHidePlaceHolderLabel];
		[self setResultsModeEnabled:_forcePickSearchResult];
	}
}

- (void)removeAllTokens {
	
	[_tokens enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop) {
		[self removeToken:token];
	}];
	
    [self setText:@""];
}

- (void)selectToken:(TIToken *)token {
	
	[self deselectSelectedToken];
	
	_selectedToken = token;
	[_selectedToken setSelected:YES];
	
	[self becomeFirstResponder];
	[self setText:kTextHidden];
}

- (void)deselectSelectedToken {
	
	[_selectedToken setSelected:NO];
	_selectedToken = nil;
	
	[self setText:kTextEmpty];
}

- (void)tokenizeText {
	
	__block BOOL textChanged = NO;
	
	if (![self.text isEqualToString:kTextEmpty] && ![self.text isEqualToString:kTextHidden] && !_forcePickSearchResult){
		[[self.text componentsSeparatedByCharactersInSet:_tokenizingCharacters] enumerateObjectsUsingBlock:^(NSString * component, NSUInteger idx, BOOL *stop){
			[self addTokenWithTitle:[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
			textChanged = YES;
		}];
	}
	
	if (textChanged) [self sendActionsForControlEvents:UIControlEventEditingChanged];
}

- (void)tokenTouchDown:(TIToken *)token
{
	if (_selectedToken != token){
		[_selectedToken setSelected:NO];
		_selectedToken = nil;
	}
}

- (void)tokenTouchUpInside:(TIToken *)token
{
	if (_editable) [self selectToken:token];
}



- (CGFloat)layoutTokensInternal {
	
	CGFloat topMargin = floor(self.font.lineHeight * 4 / 7) + 2 + TOKENS_OFFSET;
	CGFloat leftMargin = self.leftViewWidth + 12;
	CGFloat hPadding = 4;
	CGFloat rightMargin = self.rightViewWidth + hPadding;
	CGFloat lineHeight = self.font.lineHeight + topMargin + 2;
	
	_numberOfLines = 1;
	_tokenCaret = (CGPoint){leftMargin, (topMargin - 1)};
	
	[_tokens enumerateObjectsUsingBlock:^(TIToken * token, NSUInteger idx, BOOL *stop){
		
		[token setFont:self.font];
		[token setMaxWidth:(self.bounds.size.width - rightMargin - (_numberOfLines > 1 ? hPadding : leftMargin))];
		
		if (token.superview){
			
			if (_tokenCaret.x + token.bounds.size.width + rightMargin > self.bounds.size.width)
                //if(self.isEnabled || (idx != _tokens.count-1))
                if(!self.usePreparedResults || (idx != _tokens.count-1))
                {
				_numberOfLines++;
				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
				_tokenCaret.y += lineHeight;
			}
			
			[token setFrame:(CGRect){_tokenCaret, token.bounds.size}];
			_tokenCaret.x += token.bounds.size.width + 4;
			
			if (self.bounds.size.width - _tokenCaret.x - rightMargin < 50)
                if((self.isEnabled && !self.usePreparedResults) || (idx != _tokens.count-1))
            {
				_numberOfLines++;
				_tokenCaret.x = (_numberOfLines > 1 ? hPadding : leftMargin);
				_tokenCaret.y += lineHeight;
			}
		}
	}];
	
	return _tokenCaret.y + lineHeight;
}


//- (CGSize)intrinsicContentSize
//{
//    return CGSizeMake(self.window.screen.bounds.size.width, self.tokenFieldHeightConstraint.constant);
//}

#pragma mark View Handlers
- (void)layoutTokensAnimated:(BOOL)animated {
	
	CGFloat newHeight = [self layoutTokensInternal];

    if(fabs(self.tokenFieldHeightConstraint.constant - newHeight)>0.001)
    {
        [self.tokenFieldHeightConstraint setConstant:newHeight];

        if(animated)
            [UIView animateWithDuration:0.3 animations:^{
                [self.superview.superview.superview setNeedsLayout];
                [self.superview.superview.superview layoutIfNeeded];
            }];
        else
        {
            [self.superview.superview.superview setNeedsLayout];
            [self.superview.superview.superview layoutIfNeeded];
        }

    }

    if (fabs(self.bounds.size.height - newHeight)>0.001){
		
        //[self setFrame:((CGRect){self.frame.origin, {self.bounds.size.width, newHeight}})];
		// Animating this seems to invoke the triple-tap-delete-key-loop-problem-thing™
		//[UIView animateWithDuration:(animated ? 0.3 : 0) animations:^{


            [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameWillChange];

		//} completion:^(BOOL complete){
		//	if (complete)
                [self sendActionsForControlEvents:(UIControlEvents)TITokenFieldControlEventFrameDidChange];
		//}];
	}

}

- (void)setResultsModeEnabled:(BOOL)flag {
	[self setResultsModeEnabled:flag animated:YES];
}

- (void)setResultsModeEnabled:(BOOL)flag animated:(BOOL)animated {

	[self layoutTokensAnimated:animated];
	
	if (_resultsModeEnabled != flag){
		
		//Hide / show the shadow
		//[self.layer setMasksToBounds:!flag];
		
		//UIScrollView * scrollView = self.scrollView;
		//[scrollView setScrollsToTop:!flag];
		//[scrollView setScrollEnabled:!flag];
		
		//CGFloat offset = ((_numberOfLines == 1 || !flag) ? 0 : _tokenCaret.y - floor(self.font.lineHeight * 4 / 7) + 1);
		//[scrollView setContentOffset:CGPointMake(0, self.frame.origin.y + offset) animated:animated];
	}
	
	_resultsModeEnabled = flag;
}

#pragma mark Left / Right view stuff
- (void)setPromptText:(NSString *)text {
	
	if (text){
		
		UILabel * label = (UILabel *)self.leftView;
		if (!label || ![label isKindOfClass:[UILabel class]]){
			label = [[UILabel alloc] initWithFrame:CGRectZero];
			[label setTextColor:self.tintColor];
			[self setLeftView:label];

			[self setLeftViewMode:UITextFieldViewModeAlways];
		}
		
		[label setText:text];
		[label setFont:[UIFont systemFontOfSize:(PROMPT_FONT_SIZE)]];
		[label sizeToFit];
	}
	else
	{
		[self setLeftView:nil];
	}
	
	[self layoutTokensAnimated:YES];
}

- (void)setPlaceholder:(NSString *)placeholder {
	
	if (placeholder){
        
        UILabel * label =  _placeHolderLabel;
		if (!label || ![label isKindOfClass:[UILabel class]]){
			label = [[UILabel alloc] initWithFrame:CGRectMake(_tokenCaret.x + 3, _tokenCaret.y + 2, self.rightView.bounds.size.width, self.rightView.bounds.size.height)];
			[label setTextColor:NAVBAR_COLOUR];
			 _placeHolderLabel = label;
            [self addSubview: _placeHolderLabel];
		}
		
		[label setText:placeholder];
		[label setFont:[UIFont systemFontOfSize:(PROMPT_FONT_SIZE)]];
		[label sizeToFit];
	}
	else
	{
		[_placeHolderLabel removeFromSuperview];
		_placeHolderLabel = nil;
	}
    
    [self layoutTokensAnimated:YES];
}

#pragma mark Layout
- (CGRect)textRectForBounds:(CGRect)bounds {
	
	if ([self.text isEqualToString:kTextHidden]) return CGRectMake(0, -20, 0, 0);
	
	CGRect frame = CGRectOffset(bounds, _tokenCaret.x + 2, _tokenCaret.y + 5 + TEXT_OFFSET);
	frame.size.width -= (_tokenCaret.x + self.rightViewWidth + 10);

    return frame;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    return [self textRectForBounds:bounds];
}

- (CGRect)placeholderRectForBounds:(CGRect)bounds {
	return [self textRectForBounds:bounds];
}

- (CGRect)leftViewRectForBounds:(CGRect)bounds {
	return ((CGRect){{8, ceilf(self.font.lineHeight * 4 / 7) + 2 + PROMPT_OFFSET}, self.leftView.bounds.size});
}

- (CGRect)rightViewRectForBounds:(CGRect)bounds {
	return ((CGRect){{bounds.size.width - self.rightView.bounds.size.width - 6,
		bounds.size.height - self.rightView.bounds.size.height - 6}, self.rightView.bounds.size});
}

- (CGFloat)leftViewWidth {
	
	if (self.leftViewMode == UITextFieldViewModeNever ||
		(self.leftViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
		(self.leftViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
	
	return self.leftView.bounds.size.width;
}

- (CGFloat)rightViewWidth {
	
	if (self.rightViewMode == UITextFieldViewModeNever ||
		(self.rightViewMode == UITextFieldViewModeUnlessEditing && self.editing) ||
		(self.rightViewMode == UITextFieldViewModeWhileEditing && !self.editing)) return 0;
	
	return self.rightView.bounds.size.width;
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TITokenField %p; prompt = \"%@\">", self, ((UILabel *)self.leftView).text];
}

- (void)dealloc {
	[self setDelegate:nil];
}

@end

//==========================================================
#pragma mark - TITokenFieldInternalDelegate -
//==========================================================
@implementation TITokenFieldInternalDelegate
@synthesize delegate = _delegate;
@synthesize tokenField = _tokenField;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)]){
		return [_delegate textFieldShouldBeginEditing:textField];
	}
	
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldDidBeginEditing:)]){
		[_delegate textFieldDidBeginEditing:textField];
	}
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldEndEditing:)]){
		return [_delegate textFieldShouldEndEditing:textField];
	}
	
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldDidEndEditing:)]){
		[_delegate textFieldDidEndEditing:textField];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	
	if (_tokenField.tokens.count && [string isEqualToString:@""] && [_tokenField.text isEqualToString:kTextEmpty]){
		[_tokenField selectToken:[_tokenField.tokens lastObject]];
		return NO;
	}
	
	if ([textField.text isEqualToString:kTextHidden]){
		[_tokenField removeToken:_tokenField.selectedToken];
		return (![string isEqualToString:@""]);
	}
	
	if ([string rangeOfCharacterFromSet:_tokenField.tokenizingCharacters].location != NSNotFound && !_tokenField.forcePickSearchResult){
		[_tokenField tokenizeText];
		return NO;
	}
	
	if ([_delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]){
		return [_delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
	}
    
    if (_tokenField.tokenLimit!=-1 &&
        [_tokenField.tokens count] >= _tokenField.tokenLimit) {
        return NO;
    }
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	[_tokenField tokenizeText];
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldReturn:)]){
		return [_delegate textFieldShouldReturn:textField];
	}
	
	return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
	
	if ([_delegate respondsToSelector:@selector(textFieldShouldClear:)]){
		return [_delegate textFieldShouldClear:textField];
	}
	
	return YES;
}

@end


//==========================================================
#pragma mark - TIToken -
//==========================================================

CGFloat const hTextPadding = 25;
CGFloat const vTextPadding = 5;
CGFloat const kDisclosureThickness = 2.5;
NSLineBreakMode const kLineBreakMode = NSLineBreakByTruncatingMiddle;

@interface TIToken (Private)
CGPathRef CGPathCreateTokenPath(CGSize size, BOOL innerPath);
CGPathRef CGPathCreateDisclosureIndicatorPath(CGPoint arrowPointFront, CGFloat height, CGFloat thickness, CGFloat * width);
- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha;
@end

@implementation TIToken
@synthesize title = _title;
@synthesize representedObject = _representedObject;
@synthesize font = _font;
@synthesize tintColor = _tintColor;
@synthesize textColor = _textColor;
@synthesize highlightedTextColor = _highlightedTextColor;
@synthesize accessoryType = _accessoryType;
@synthesize maxWidth = _maxWidth;

#pragma mark Init
- (instancetype)initWithTitle:(NSString *)aTitle {
    _font = [UIFont systemFontOfSize:TOKEN_FONT_SIZE];
    self.font = _font;
	return [self initWithTitle:aTitle representedObject:nil];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object {
    self.font = [UIFont systemFontOfSize:TOKEN_FONT_SIZE];
	return [self initWithTitle:aTitle representedObject:object font:self.font];
}

- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object font:(UIFont *)aFont {
	
	if ((self = [super init])){

        self.font = aFont;

		_title = [aTitle copy];
		_representedObject = object;
		
		_font = aFont;
        _tintColor = self.superview.tintColor;
		_textColor = [UIColor whiteColor];
		_highlightedTextColor = [UIColor whiteColor];
		
		_accessoryType = TITokenAccessoryTypeNone;
		_maxWidth = 200;

//        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
//        [self addGestureRecognizer:tap];

		[self setBackgroundColor:[UIColor clearColor]];
		[self sizeToFit];
	}
	
	return self;
}


//- (IBAction)handleTapGesture:(UIGestureRecognizer*)tapRecogniser
//{
//
//}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];

    if([self.superview canBecomeFirstResponder])
        [self.superview becomeFirstResponder];
}


#pragma mark Property Overrides
- (void)setHighlighted:(BOOL)flag {
	
	if (self.highlighted != flag){
		[super setHighlighted:flag];
		[self setNeedsDisplay];
	}
}

- (void)setSelected:(BOOL)flag {
	
	if (self.selected != flag){
		[super setSelected:flag];
		[self setNeedsDisplay];
	}
}

- (void)setTitle:(NSString *)newTitle {
	
	if (newTitle){
		_title = [newTitle copy];
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setFont:(UIFont *)newFont {
	
	if (!newFont) newFont = [UIFont systemFontOfSize:TOKEN_FONT_SIZE];
	
	if (_font != newFont){
		_font = newFont;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setTintColor:(UIColor *)newTintColor {
	
//	if (!newTintColor) newTintColor = [TIToken blueTintColor];

	if (_tintColor != newTintColor){
		_tintColor = newTintColor;
		[self setNeedsDisplay];
	}
}

- (void)setAccessoryType:(TITokenAccessoryType)type {
	
	if (_accessoryType != type){
		_accessoryType = type;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

- (void)setMaxWidth:(CGFloat)width {
	
	if (_maxWidth != width){
		_maxWidth = width;
		[self sizeToFit];
        [self setNeedsDisplay];
	}
}

#pragma Tint Color Convenience

+ (UIColor *)blueTintColor {
	return [UIColor colorWithRed:0.216 green:0.373 blue:0.965 alpha:1];
}

+ (UIColor *)redTintColor {
	return [UIColor colorWithRed:1 green:0.15 blue:0.15 alpha:1];
}

+ (UIColor *)greenTintColor {
	return [UIColor colorWithRed:0.333 green:0.741 blue:0.235 alpha:1];
}

#pragma mark Layout
- (CGSize)sizeThatFits:(CGSize)size {
	
	CGFloat accessoryWidth = 0;
	
	if (_accessoryType == TITokenAccessoryTypeDisclosureIndicator){
		CGPathRelease(CGPathCreateDisclosureIndicatorPath(CGPointZero, _font.pointSize, kDisclosureThickness, &accessoryWidth));
		accessoryWidth += floorf(hTextPadding / 2);
	}

    NSMutableParagraphStyle* paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [paragraphStyle setLineBreakMode:kLineBreakMode];

    /*
	CGSize titleSize = [_title sizeWithFont:_font forWidth:(_maxWidth - hTextPadding - accessoryWidth) lineBreakMode:kLineBreakMode];
	CGFloat height = floorf(titleSize.height + vTextPadding);

    return (CGSize){MAX(floorf(titleSize.width + hTextPadding + accessoryWidth), height - 3), height};
*/


    CGRect titleRect = [_title boundingRectWithSize:CGSizeMake((_maxWidth - hTextPadding - accessoryWidth), MAXFLOAT) options:0 attributes:@{NSParagraphStyleAttributeName:paragraphStyle,NSFontAttributeName:_font} context:[NSStringDrawingContext new]];
    CGFloat height = floorf(titleRect.size.height + vTextPadding);

    return (CGSize){MAX(ceilf(titleRect.size.width + hTextPadding + accessoryWidth), height - 3), height};
}

#pragma mark Drawing
- (void)drawRect:(CGRect)rect {

	CGContextRef context = UIGraphicsGetCurrentContext();

    if(!context)
    {
        NSLog(@"Attempting to draw with invalid context!!!");
        return;
    }

 	// Draw the outline.
	CGContextSaveGState(context);
	CGPathRef outlinePath = CGPathCreateTokenPath(self.bounds.size, NO);
	CGContextAddPath(context, outlinePath);
	CGPathRelease(outlinePath);
	
	BOOL drawHighlighted = (self.selected || self.highlighted);
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGPoint endPoint = CGPointMake(0, self.bounds.size.height);
	
	CGFloat red = 1;
	CGFloat green = 1;
	CGFloat blue = 1;
	CGFloat alpha = 1;
	[self getTintColorRed:&red green:&green blue:&blue alpha:&alpha];
	
	if (drawHighlighted){
		CGContextSetFillColor(context, (CGFloat[4]){red, green, blue, 1});
		CGContextFillPath(context);
	}
	else
	{
		CGContextClip(context);
		CGFloat locations[2] = {0, 0.95};
		CGFloat components[8] = {red + 0.2, green + 0.2, blue + 0.2, alpha, red, green, blue, 0.8};
		CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, locations, 2);
		CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
		CGGradientRelease(gradient);
	}
	
	CGContextRestoreGState(context);
	
	CGPathRef innerPath = CGPathCreateTokenPath(self.bounds.size, YES);
    
    // Draw a white background so we can use alpha to lighten the inner gradient
    CGContextSaveGState(context);
	CGContextAddPath(context, innerPath);
    CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});
    CGContextFillPath(context);
    CGContextRestoreGState(context);
	
	// Draw the inner gradient.
	CGContextSaveGState(context);
	CGContextAddPath(context, innerPath);
	CGPathRelease(innerPath);
	CGContextClip(context);
	
	//CGFloat locations[2] = {0, (drawHighlighted ? 1 : 1)};
    CGFloat highlightedComp[8] = {red, green, blue, 0.4, red, green, blue, .5};
    CGFloat nonHighlightedComp[8] = {red, green, blue, .9, red, green, blue, 1};
	
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, (drawHighlighted ? highlightedComp : nonHighlightedComp), /*locations*/NULL, 2);
	CGContextDrawLinearGradient(context, gradient, CGPointZero, endPoint, 0);
	CGGradientRelease(gradient);
	CGContextRestoreGState(context);
	
	CGFloat accessoryWidth = 0;
	
	if (_accessoryType == TITokenAccessoryTypeDisclosureIndicator){
		CGPoint arrowPoint = CGPointMake(self.bounds.size.width - floorf(hTextPadding / 2), (self.bounds.size.height / 2) - 1);
		CGPathRef disclosurePath = CGPathCreateDisclosureIndicatorPath(arrowPoint, _font.pointSize, kDisclosureThickness, &accessoryWidth);
		accessoryWidth += floorf(hTextPadding / 2);
		
		CGContextAddPath(context, disclosurePath);
		CGContextSetFillColor(context, (CGFloat[4]){1, 1, 1, 1});
		
		if (drawHighlighted){
			CGContextFillPath(context);
		}
		else
		{
			CGContextSaveGState(context);
			CGContextSetShadowWithColor(context, CGSizeMake(0, 1), 1, [[[UIColor whiteColor] colorWithAlphaComponent:0.6] CGColor]);
			CGContextFillPath(context);
			CGContextRestoreGState(context);
			
			CGContextSaveGState(context);
			CGContextAddPath(context, disclosurePath);
			CGContextClip(context);
			
			CGGradientRef disclosureGradient = CGGradientCreateWithColorComponents(colorspace, highlightedComp, NULL, 2);
			CGContextDrawLinearGradient(context, disclosureGradient, CGPointZero, endPoint, 0);
			CGGradientRelease(disclosureGradient);
			
			arrowPoint.y += 0.5;
			CGPathRef innerShadowPath = CGPathCreateDisclosureIndicatorPath(arrowPoint, _font.pointSize, kDisclosureThickness, NULL);
			CGContextAddPath(context, innerShadowPath);
			CGPathRelease(innerShadowPath);
			CGContextSetStrokeColor(context, (CGFloat[4]){0, 0, 0, 0.3});
			CGContextStrokePath(context);
			CGContextRestoreGState(context);
		}
		
		CGPathRelease(disclosurePath);
	}
	
	CGColorSpaceRelease(colorspace);

    CGRect textRect = [_title boundingRectWithSize:CGSizeMake((_maxWidth - hTextPadding - accessoryWidth), MAXFLOAT) options:0 attributes:@{NSFontAttributeName:_font} context:nil];

    CGSize titleSize = textRect.size; //[_title sizeWithFont:_font forWidth:(_maxWidth - hTextPadding - accessoryWidth) lineBreakMode:kLineBreakMode];
    CGFloat vPadding = floor((self.bounds.size.height - titleSize.height) / 2);
	CGFloat titleWidth = ceilf(self.bounds.size.width - hTextPadding - accessoryWidth);
	CGRect textBounds = CGRectMake(floorf(hTextPadding / 2), vPadding - 1, titleWidth, floorf(self.bounds.size.height - (vPadding * 2)));
	
	NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [style setLineBreakMode:NSLineBreakByTruncatingMiddle];

    //CGContextSetFillColorWithColor(context, (drawHighlighted ? _highlightedTextColor : _textColor).CGColor);
	[_title drawInRect:textBounds withAttributes:@{NSFontAttributeName:_font, NSForegroundColorAttributeName:(drawHighlighted ? _highlightedTextColor : _textColor),NSParagraphStyleAttributeName: style}];
}

CGPathRef CGPathCreateTokenPath(CGSize size, BOOL innerPath) {
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGFloat arcValue = (size.height / 2) - 1;
	CGFloat radius = arcValue - (innerPath ? (1 / [[UIScreen mainScreen] scale]) : 0);
	CGPathAddArc(path, NULL, arcValue, arcValue, radius, (M_PI / 2), (M_PI * 3 / 2), NO);
	CGPathAddArc(path, NULL, size.width - arcValue, arcValue, radius, (M_PI  * 3 / 2), (M_PI / 2), NO);
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

- (BOOL)getTintColorRed:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
	CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGColorGetColorSpace(_tintColor.CGColor));
	const CGFloat * components = CGColorGetComponents(_tintColor.CGColor);
	
	if (colorSpaceModel == kCGColorSpaceModelMonochrome || colorSpaceModel == kCGColorSpaceModelRGB){
		
		if (red) *red = components[0];
		if (green) *green = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[1]);
		if (blue) *blue = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[0] : components[2]);
		if (alpha) *alpha = (colorSpaceModel == kCGColorSpaceModelMonochrome ? components[1] : components[3]);
		
		return YES;
	}
	
	return NO;
}

#pragma mark Other
- (NSString *)description {
	return [NSString stringWithFormat:@"<TIToken %p; title = \"%@\"; representedObject = \"%@\">", self, _title, _representedObject];
}


@end
