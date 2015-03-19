//
//   HTMLPurifier_Strategy_ValidateAttributes.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


#import "HTMLPurifier_Strategy.h"

/**
 * Validate all attributes in the tokens.
 */
@interface HTMLPurifier_Strategy_ValidateAttributes : HTMLPurifier_Strategy

    /**
     * @param HTMLPurifier_Token[] $tokens
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return HTMLPurifier_Token[]
     */
- (NSMutableArray*)execute:(NSMutableArray*)tokens config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
