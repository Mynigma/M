//
//   HTMLPurifier_AttrDef_CSS_Font.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import "HTMLPurifier_AttrDef.h"

/**
 * Validates shorthand CSS property font.
 */
@interface HTMLPurifier_AttrDef_CSS_Font : HTMLPurifier_AttrDef
{
    /**
     * Local copy of validators
     * @type HTMLPurifier_AttrDef[]
     * @note If we moved specific CSS property definitions to their own
     *       classes instead of having them be assembled at run time by
     *       CSSDefinition, this wouldn't be necessary.  We'd instantiate
     *       our own copies.
     */
     NSMutableDictionary* info;
}     /**
     * @param HTMLPurifier_Config $config
     */
- (id)initWithConfig:(HTMLPurifier_Config*)config;

    /**
     * @param string $string
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return bool|string
     */
- (NSString*)validateWithString:(NSString *)theString config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
