//
//   HTMLPurifier_AttrDef_Percentage.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

@class HTMLPurifier_AttrDef_CSS_Number, HTMLPurifier_Config, HTMLPurifier_Context;

@interface HTMLPurifier_AttrDef_CSS_Percentage : HTMLPurifier_AttrDef
{
    /**
     * Instance to defer number validation to.
     * @type HTMLPurifier_AttrDef_CSS_Number
     */
    HTMLPurifier_AttrDef_CSS_Number* numberDef;
}

- (id)initWithNonNegative:(BOOL)nonNegative;

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
- (NSString*)validateWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
