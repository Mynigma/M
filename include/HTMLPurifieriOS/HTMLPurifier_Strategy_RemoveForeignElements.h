//
//   HTMLPurifier_Strategy_RemoveForeignElements.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


#import "HTMLPurifier_Strategy.h"

@class HTMLPurifier_Config, HTMLPurifier_Context, HTMLPurifier_Definition;

/**
 * Removes all unrecognized tags from the list of tokens.
 *
 * This strategy iterates through all the tokens and removes unrecognized
 * tokens. If a token is not recognized but a TagTransform is defined for
 * that element, the element will be transformed accordingly.
 */
@interface HTMLPurifier_Strategy_RemoveForeignElements : HTMLPurifier_Strategy


/**
 * @param HTMLPurifier_Token[] $tokens
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return array|HTMLPurifier_Token[]
 */
- (NSMutableArray*)execute:(NSMutableArray*)tokens config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
