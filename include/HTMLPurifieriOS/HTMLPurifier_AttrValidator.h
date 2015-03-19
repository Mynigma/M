//
//   HTMLPurifier_AttrValidator.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 16.01.14.


#import <Foundation/Foundation.h>


@class HTMLPurifier_Config, HTMLPurifier_Context, HTMLPurifier_Token;

/**
 * Validates the attributes of a token. Doesn't manage required attributes
 * very well. The only reason we factored this out was because RemoveForeignElements
 * also needed it besides ValidateAttributes.
 */
@interface HTMLPurifier_AttrValidator : NSObject

    /**
     * Validates the attributes of a token, mutating it as necessary.
     * that has valid tokens
     * @param HTMLPurifier_Token $token Token to validate.
     * @param HTMLPurifier_Config $config Instance of HTMLPurifier_Config
     * @param HTMLPurifier_Context $context Instance of HTMLPurifier_Context
     */
- (void)validateToken:(HTMLPurifier_Token*)token config:(HTMLPurifier_Config*)config  context:(HTMLPurifier_Context*)context;



@end
