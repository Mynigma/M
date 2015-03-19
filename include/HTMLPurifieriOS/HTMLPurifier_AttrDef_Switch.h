//
//   HTMLPurifier_AttrDef_Switch.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

/**
 * Decorator that, depending on a token, switches between two definitions.
 */
@interface HTMLPurifier_AttrDef_Switch : HTMLPurifier_AttrDef
{

    /**
     * @type string
     */
    NSString* tag;

    /**
     * @type HTMLPurifier_AttrDef
     */
    HTMLPurifier_AttrDef* withTag;

    /**
     * @type HTMLPurifier_AttrDef
     */
    HTMLPurifier_AttrDef* withoutTag;
}

    /**
     * @param string $tag Tag name to switch upon
     * @param HTMLPurifier_AttrDef $with_tag Call if token matches tag
     * @param HTMLPurifier_AttrDef $without_tag Call if token doesn't match, or there is no token
     */
- (id)initWithTag:(NSString*)newTag withTag:(HTMLPurifier_AttrDef*)newWithTag  withoutTag:(HTMLPurifier_AttrDef*)newWithoutTag;

    /**
     * @param string $string
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return bool|string
     */
- (NSString*)validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
