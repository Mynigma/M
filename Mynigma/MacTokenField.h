//
//  MacTokenField.h
//  MacTokenField
//



@class MacTokenField, MacToken;

#pragma mark - Delegate Methods


@protocol MacTokenFieldDelegate <NSTextViewDelegate>
@optional
- (BOOL)tokenField:(MacTokenField *)tokenField willAddToken:(MacToken *)token;
- (void)tokenField:(MacTokenField *)tokenField didAddToken:(MacToken *)token;
- (BOOL)tokenField:(MacTokenField *)tokenField willRemoveToken:(MacToken *)token;
- (void)tokenField:(MacTokenField *)tokenField didRemoveToken:(MacToken *)token;

- (NSString *)tokenField:(MacTokenField *)tokenField displayStringForRepresentedObject:(id)object;
- (MacToken*)tokenForStringComponent:(NSString*)stringComponent insertAtIndex:(NSInteger)insertionIndex;
- (NSColor*)tintColourForToken:(MacToken*)token;
- (NSColor*)highlightTintColourForToken:(MacToken*)token;
- (NSMenu *)menuForToken:(MacToken*)token;

@end

@interface MacTokenFieldInternalDelegate : NSObject <NSTextViewDelegate>
@property (nonatomic) id<MacTokenFieldDelegate> externalDelegate;
@property (nonatomic) MacTokenField * tokenField;
@end


#pragma mark - MacTokenField

typedef enum {
	MacTokenFieldControlEventFrameWillChange = 1 << 24,
	MacTokenFieldControlEventFrameDidChange = 1 << 25,
} MacTokenFieldControlEvents;

@interface MacTokenField : NSTextView
@property (weak, nonatomic, readonly) NSArray * tokens;
@property (nonatomic) NSMutableArray * selectedTokens;
@property (nonatomic) int tokenLimit;
@property (nonatomic, strong) NSCharacterSet * tokenizingCharacters;

@property BOOL needToUpdateHeightAfterTextChange;

- (void)setDelegate:(id<MacTokenFieldDelegate>)del;

- (BOOL)canAddToken:(MacToken *)token;
- (MacToken *)addTokenWithTitle:(NSString *)title;
- (MacToken *)addTokenWithTitle:(NSString *)title representedObject:(id)object insertAtIndex:(NSInteger)insertionIndex;
- (void)removeTokens:(NSArray*)tokenArray;
- (void)removeToken:(MacToken *)token;
- (void)removeAllTokens;

- (void)selectToken:(MacToken *)token byExtendingSelection:(BOOL)extendSelection;
- (void)deselectSelectedTokens;

- (void)tokeniseText;

- (void)updateHeight;

@property BOOL isShowingCompletions;

@property CGFloat contentHeight;
@property CGFloat contentWidth;

@end

#pragma mark - MacToken

typedef enum {
	MacTokenAccessoryTypeNone = 0,
	MacTokenAccessoryTypeDisclosureIndicator = 1,
} MacTokenAccessoryType;

@interface MacToken : NSTextAttachmentCell

@property (nonatomic, copy) NSString * title;
@property (nonatomic, strong) id representedObject;
@property (nonatomic, strong) NSColor * textColor;
@property (nonatomic, strong) NSColor * highlightedTextColor;
@property (nonatomic, strong) NSColor * tintColor;
@property (nonatomic, strong) NSColor * highlightTintColor;
@property (nonatomic, assign) MacTokenAccessoryType accessoryType;
@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, assign) NSFont* font;

+ (NSAttributedString*)attributedStringWithToken:(MacToken*)token paragraphStyle:(NSParagraphStyle*)paragraphStyle;

@property BOOL selected;

@end

//empty token inserted at the beginning of the line and never changed
//ensures that the caret looks right
@interface EmptyToken : NSTextAttachmentCell

+ (NSAttributedString*)emptyString;

@end