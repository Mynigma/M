//
//   HTMLPurifier_AttrDef_CSS_Background.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

@class HTMLPurifier_Config;

/**
 * Validates shorthand CSS property background.
 * @warning Does not support url tokens that have internal spaces.
 */
@interface HTMLPurifier_AttrDef_CSS_Background : HTMLPurifier_AttrDef
{

    /**
     * Local copy of component validators.
     * @type HTMLPurifier_AttrDef[]
     * @note See HTMLPurifier_AttrDef_Font::$info for a similar impl.
     */
    NSMutableDictionary* info;
}
    /**
     * @param HTMLPurifier_Config $config
     */
- (id)initWithConfig:(HTMLPurifier_Config*)config;


    /**
     * @param string $string
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return bool|string
     */
- (NSString*)validateWithString:(NSString *)someString config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
