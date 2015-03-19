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






#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>


#else

#define UIImage NSImage

#define UITextFieldDelegate NSTextFieldDelegate
#define UITableViewCell NSTableCellView
#define UITableView NSTableView
#define UITableViewDelegate NSTableViewDelegate
#define UIScrollView NSScrollView
#define UITableViewDataSource NSTableViewDataSource
#define UIView NSView
#define UITextField NSTextField
#define UIControl NSControl
#define UIColor NSColor
#define UIFont NSFont
#define UI_APPEARANCE_SELECTOR 
#define UIPopoverController NSWindowController

#endif

@class TITokenField, TIToken;

//==========================================================
#pragma mark - Delegate Methods -
//==========================================================
@protocol TITokenFieldDelegate <UITextFieldDelegate>
@optional
- (BOOL)tokenField:(TITokenField *)tokenField willAddToken:(TIToken *)token;
- (void)tokenField:(TITokenField *)tokenField didAddToken:(TIToken *)token;
- (BOOL)tokenField:(TITokenField *)tokenField willRemoveToken:(TIToken *)token;
- (void)tokenField:(TITokenField *)tokenField didRemoveToken:(TIToken *)token;

- (BOOL)tokenField:(TITokenField *)field shouldUseCustomSearchForSearchString:(NSString *)searchString;
- (void)tokenField:(TITokenField *)field performCustomSearchForSearchString:(NSString *)searchString withCompletionHandler:(void (^)(NSArray *results))completionHandler;

- (void)tokenField:(TITokenField *)tokenField didFinishSearch:(NSArray *)matches;
- (NSString *)tokenField:(TITokenField *)tokenField displayStringForRepresentedObject:(id)object;
- (NSString *)tokenField:(TITokenField *)tokenField searchResultStringForRepresentedObject:(id)object;
- (NSString *)tokenField:(TITokenField *)tokenField searchResultSubtitleForRepresentedObject:(id)object;
- (UIImage *)tokenField:(TITokenField *)tokenField searchResultImageForRepresentedObject:(id)object;
- (UITableViewCell *)tokenField:(TITokenField *)tokenField resultsTableView:(UITableView *)tableView cellForRepresentedObject:(id)object;
- (CGFloat)tokenField:(TITokenField *)tokenField resultsTableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface TITokenFieldInternalDelegate : NSObject <UITextFieldDelegate>
@end

//==========================================================
#pragma mark - TITokenFieldView -
//==========================================================
@interface TITokenFieldView : UIScrollView <UITableViewDelegate, UITableViewDataSource, TITokenFieldDelegate>
@property (nonatomic, assign) BOOL showAlreadyTokenized;
@property (nonatomic, assign) BOOL searchSubtitles;
@property (nonatomic, assign) BOOL forcePickSearchResult;
@property (nonatomic, assign) BOOL shouldSortResults;
@property (nonatomic, assign) BOOL shouldSearchInBackground;
@property (nonatomic, assign) UIPopoverArrowDirection permittedArrowDirections;
@property (nonatomic) IBOutlet TITokenField * tokenField;
@property (nonatomic) IBOutlet UIView * separator;
@property (nonatomic) IBOutlet UITableView * resultsTable;
//@property (nonatomic, readonly) UIView * contentView;
@property (nonatomic, copy) NSArray * sourceArray;
@property (weak, nonatomic, readonly) NSArray * tokenTitles;
@property NSMutableArray * resultsArray;

@property IBOutlet NSLayoutConstraint* widthConstraint;

@property IBOutlet NSLayoutConstraint* tableViewHeightConstraint;

- (void)updateContentSize;

-(void) reloadResultsTable;

@end

//==========================================================
#pragma mark - TITokenField -
//==========================================================
typedef enum {
	TITokenFieldControlEventFrameWillChange = 1 << 24,
	TITokenFieldControlEventFrameDidChange = 1 << 25,
} TITokenFieldControlEvents;

@interface TITokenField : UITextField
//@property (nonatomic, weak) IBOutlet id <TITokenFieldDelegate> delegate;
@property (weak, nonatomic, readonly) NSArray * tokens;
@property (weak, nonatomic, readonly) TIToken * selectedToken;
@property (weak, nonatomic, readonly) NSArray * tokenTitles;
@property (weak, nonatomic, readonly) NSArray * tokenObjects;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, assign) BOOL resultsModeEnabled;
@property (nonatomic, assign) BOOL removesTokensOnEndEditing;
@property (nonatomic, readonly) int numberOfLines;
@property (nonatomic) int tokenLimit;
@property (nonatomic, strong) NSCharacterSet * tokenizingCharacters;

@property BOOL usePreparedResults;

- (void)addToken:(TIToken *)title;
- (TIToken *)addTokenWithTitle:(NSString *)title;
- (TIToken *)addTokenWithTitle:(NSString *)title representedObject:(id)object;
- (void)addTokensWithTitleList:(NSString *)titleList;
- (void)addTokensWithTitleArray:(NSArray *)titleArray;
- (void)removeToken:(TIToken *)token;
- (void)removeAllTokens;

- (void)selectToken:(TIToken *)token;
- (void)deselectSelectedToken;

- (void)tokenizeText;

- (void)layoutTokensAnimated:(BOOL)animated;
- (void)setResultsModeEnabled:(BOOL)enabled animated:(BOOL)animated;

// Pass nil to hide label
- (void)setPromptText:(NSString *)aText;


@property IBOutlet NSLayoutConstraint* tokenFieldHeightConstraint;

@end

//==========================================================
#pragma mark - TIToken -
//==========================================================
typedef enum {
	TITokenAccessoryTypeNone = 0, // Default
	TITokenAccessoryTypeDisclosureIndicator = 1,
} TITokenAccessoryType;

@interface TIToken : UIControl
@property (nonatomic, copy) NSString * title;
@property (nonatomic, strong) id representedObject;
@property (nonatomic, strong) UIFont * font;
@property (nonatomic, strong) UIColor * textColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor * highlightedTextColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor * tintColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) TITokenAccessoryType accessoryType;
@property (nonatomic, assign) CGFloat maxWidth;

- (instancetype)initWithTitle:(NSString *)aTitle;
- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object;
- (instancetype)initWithTitle:(NSString *)aTitle representedObject:(id)object font:(UIFont *)aFont;

+ (UIColor *)blueTintColor;
+ (UIColor *)redTintColor;
+ (UIColor *)greenTintColor;

@end