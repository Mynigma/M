//
//   HTMLPurifier_AttrDef_CSS_Color.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

/**
 * Validates Color as defined by CSS.
 */
@interface HTMLPurifier_AttrDef_CSS_Color : HTMLPurifier_AttrDef


    /**
     * @param string $color
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return bool|string
     */
- (NSString*)validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
