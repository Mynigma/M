//
//   HTMLPurifier_Injector.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config, HTMLPurifier_Zipper, HTMLPurifier_HTMLDefinition, HTMLPurifier_Token, HTMLPurifier_Context;

/**
 * Injects tokens into the document while parsing for well-formedness.
 * This enables "formatter-like" functionality such as auto-paragraphing,
 * smiley-ification and linkification to take place.
 *
 * A note on how handlers create changes; this is done by assigning a new
 * value to the $token reference. These values can take a variety of forms and
 * are best described HTMLPurifier_Strategy_MakeWellFormed->processToken()
 * documentation.
 *
 * @todo Allow injectors to request a re-run on their output. This
 *       would help if an operation is recursive.
 */
@interface HTMLPurifier_Injector : NSObject
{
    HTMLPurifier_HTMLDefinition* htmlDefinition;
    NSMutableArray* currentNesting;
    HTMLPurifier_Token* currentToken;
    HTMLPurifier_Zipper* inputZipper;
    NSInteger rewindOffset;
}

/**
 * Advisory name of injector, this is for friendly error messages.
 * @type string
 */
@property NSString* name;


/**
 * Array of elements and attributes this injector creates and therefore
 * need to be allowed by the definition. Takes form of
 * array('element' => array('attr', 'attr2'), 'element2')
 * @type array
 */
@property NSMutableDictionary* needed;


/**
 * Rewind to a spot to re-perform processing. This is useful if you
 * deleted a node, and now need to see if this change affected any
 * earlier nodes. Rewinding does not affect other injectors, and can
 * result in infinite loops if not used carefully.
 * @param bool|int $offset
 * @warning HTML Purifier will prevent you from fast-forwarding with this
 *          function.
 */
- (void)rewindOffset:(NSInteger)offset;

/**
 * Retrieves rewind offset, and then unsets it.
 * @return bool|int
 */
- (NSInteger)getRewindOffset;

/**
 * Prepares the injector by giving it the config and context objects:
 * this allows references to important variables to be made within
 * the injector. This function also checks if the HTML environment
 * will work with the Injector (see checkNeeded()).
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string Boolean false if success, string of missing needed element/attribute if failure
 */
- (NSString*)prepare:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * This function checks if the HTML environment
 * will work with the Injector: if p tags are not allowed, the
 * Auto-Paragraphing injector should not be enabled.
 * @param HTMLPurifier_Config $config
 * @return bool|string Boolean false if success, string of missing needed element/attribute if failure
 */
- (NSString*)checkNeeded:(HTMLPurifier_Config*)config;

/**
 * Tests if the context node allows a certain element
 * @param string $name Name of element to test for
 * @return bool True if element is allowed, false if it is not
 */
- (BOOL)allowsElement:(NSString*)name;

/**
 * Iterator function, which starts with the next token and continues until
 * you reach the end of the input tokens.
 * @warning Please prevent previous references from interfering with this
 *          functions by setting $i = null beforehand!
 * @param int $i Current integer index variable for inputTokens
 * @param HTMLPurifier_Token $current Current token variable.
 *          Do NOT use $token, as that variable is also a reference
 * @return bool
 */
- (BOOL)forward:(NSInteger*)i current:(HTMLPurifier_Token**)current;
/**
 * Similar to _forward, but accepts a third parameter $nesting (which
 * should be initialized at 0) and stops when we hit the end tag
 * for the node $this->inputIndex starts in.
 * @param int $i Current integer index variable for inputTokens
 * @param HTMLPurifier_Token $current Current token variable.
 *          Do NOT use $token, as that variable is also a reference
 * @param int $nesting
 * @return bool
 */
- (BOOL)forwardUntilEndToken:(NSInteger*)i current:(HTMLPurifier_Token**)current nesting:(NSInteger*)nesting;

/**
 * Iterator function, starts with the previous token and continues until
 * you reach the beginning of input tokens.
 * @warning Please prevent previous references from interfering with this
 *          functions by setting $i = null beforehand!
 * @param int $i Current integer index variable for inputTokens
 * @param HTMLPurifier_Token $current Current token variable.
 *          Do NOT use $token, as that variable is also a reference
 * @return bool
 */
- (BOOL)backward:(NSInteger*)i current:(HTMLPurifier_Token**)current;

/**
 * Handler that is called when a text token is processed
 */
- (void)handleText:(HTMLPurifier_Token**)token;
/**
 * Handler that is called when a start or empty token is processed
 */
- (void)handleElement:(HTMLPurifier_Token**)token;
/**
 * Handler that is called when an end token is processed
 */
- (void)handleEnd:(HTMLPurifier_Token**)token;
- (void)notifyEnd:(HTMLPurifier_Token*)token;


@end
