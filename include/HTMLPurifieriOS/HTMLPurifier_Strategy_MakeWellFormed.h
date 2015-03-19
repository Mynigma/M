//
//   HTMLPurifier_Strategy_MakeWellFormed.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


#import "HTMLPurifier_Strategy.h"

@class HTMLPurifier_Token, HTMLPurifier_Zipper, HTMLPurifier_Injector;

/**
 * Takes tokens makes them well-formed (balance end tags, etc.)
 *
 * Specification of the armor attributes this strategy uses:
 *
 *      - MakeWellFormed_TagClosedError: This armor field is used to
 *        suppress tag closed errors for certain tokens [TagClosedSuppress],
 *        in particular, if a tag was generated automatically by HTML
 *        Purifier, we may rely on our infrastructure to close it for us
 *        and shouldn't report an error to the user [TagClosedAuto].
 */
@interface HTMLPurifier_Strategy_MakeWellFormed : HTMLPurifier_Strategy
{
    /**
     * Array stream of tokens being processed.
     * @type HTMLPurifier_Token[]
     */
    NSMutableArray* _tokens;

    /**
     * Current token.
     * @type HTMLPurifier_Token
     */
    NSObject* _token;

    /**
     * Zipper managing the true state.
     * @type HTMLPurifier_Zipper
     */
    HTMLPurifier_Zipper* _zipper;

    /**
     * Current nesting of elements.
     * @type array
     */
    NSMutableArray* _stack;

    /**
     * Injectors active in this stream processing.
     * @type HTMLPurifier_Injector[]
     */
    NSMutableArray* _injectors;

    /**
     * Current instance of HTMLPurifier_Config.
     * @type HTMLPurifier_Config
     */
    HTMLPurifier_Config* _config;

    /**
     * Current instance of HTMLPurifier_Context.
     * @type HTMLPurifier_Context
     */
    HTMLPurifier_Context* _context;
}
/**
 * @param HTMLPurifier_Token[] $tokens
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return HTMLPurifier_Token[]
 * @throws HTMLPurifier_Exception
 */

/**
 * Processes arbitrary token values for complicated substitution patterns.
 * In general:
 *
 * If $token is an array, it is a list of tokens to substitute for the
 * current token. These tokens then get individually processed. If there
 * is a leading integer in the list, that integer determines how many
 * tokens from the stream should be removed.
 *
 * If $token is a regular token, it is swapped with the current token.
 *
 * If $token is false, the current token is deleted.
 *
 * If $token is an integer, that number of tokens (with the first token
 * being the current one) will be deleted.
 *
 * @param HTMLPurifier_Token|array|int|bool $token Token substitution value
 * @param HTMLPurifier_Injector|int $injector Injector that performed the substitution; default is if
 *        this is not an injector related operation.
 * @throws HTMLPurifier_Exception
 */
- (NSMutableArray*)execute:(NSMutableArray*)tokens config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

/**
 * Processes arbitrary token values for complicated substitution patterns.
 * In general:
 *
 * If $token is an array, it is a list of tokens to substitute for the
 * current token. These tokens then get individually processed. If there
 * is a leading integer in the list, that integer determines how many
 * tokens from the stream should be removed.
 *
 * If $token is a regular token, it is swapped with the current token.
 *
 * If $token is false, the current token is deleted.
 *
 * If $token is an integer, that number of tokens (with the first token
 * being the current one) will be deleted.
 *
 * @param HTMLPurifier_Token|array|int|bool $token Token substitution value
 * @param HTMLPurifier_Injector|int $injector Injector that performed the substitution; default is if
 *        this is not an injector related operation.
 * @throws HTMLPurifier_Exception
 */
- (HTMLPurifier_Token*)processToken:(NSObject*)token remove:(NSNumber*)remove injector:(NSNumber*)injector;

/**
 * Inserts a token before the current token. Cursor now points to
 * this token.  You must reprocess after this.
 * @param HTMLPurifier_Token $token
 */
- (HTMLPurifier_Token*)insertBefore:(HTMLPurifier_Token*)token;

/**
 * Removes current token. Cursor now points to new token occupying previously
 * occupied space.  You must reprocess after this.
 */
- (NSObject*)removeObject;



@end
