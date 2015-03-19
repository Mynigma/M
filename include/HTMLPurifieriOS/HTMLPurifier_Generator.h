//
//   HTMLPurifier_Generator.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Context, HTMLPurifier_Config, HTMLPurifier_Token;

@interface HTMLPurifier_Generator : NSObject

- (id)initWithConfig:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;



/**
 * Generates HTML from an array of tokens.
 * @param HTMLPurifier_Token[] $tokens Array of HTMLPurifier_Token
 * @return string Generated HTML
 */
- (NSString*)generateFromTokens:(NSArray*)tokens;

/**
 * Generates HTML from a single token.
 * @param HTMLPurifier_Token $token HTMLPurifier_Token object.
 * @return string Generated HTML
 */
- (NSString*)generateFromToken:(HTMLPurifier_Token*)token;

/**
 * Special case processor for the contents of script tags
 * @param HTMLPurifier_Token $token HTMLPurifier_Token object.
 * @return string
 * @warning This runs into problems if there's already a literal
 *          --> somewhere inside the script contents.
 */
- (NSString*)generateScriptFromToken:(HTMLPurifier_Token*)token;

/**
 * Generates attribute declarations from attribute array.
 * @note This does not include the leading or trailing space.
 * @param array $assoc_array_of_attributes Attribute array
 * @param string $element Name of element attributes are for, used to check
 *        attribute minimization.
 * @return string Generated HTML fragment for insertion.
 */
- (NSString*)generateAttributes:(NSDictionary*)assoc_array_of_attributes sortedKeys:(NSMutableArray*)sortedKeys;
- (NSString*)generateAttributes:(NSDictionary*)assoc_array_of_attributes sortedKeys:(NSMutableArray*)sortedKeys element:(NSString*)element;

/**
 * Escapes raw text data.
 * @todo This really ought to be protected, but until we have a facility
 *       for properly generating HTML here w/o using tokens, it stays
 *       public.
 * @param string $string String data to escape for HTML.
 * @param int $quote Quoting style, like htmlspecialchars. ENT_NOQUOTES is
 *               permissible for non-attribute output.
 * @return string escaped data.
 */
- (NSString*)escape:(NSString*)string quote:(NSString*)quote;
- (NSString*)escape:(NSString*)string;

@end
