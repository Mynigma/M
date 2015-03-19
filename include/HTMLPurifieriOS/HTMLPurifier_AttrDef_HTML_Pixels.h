//
//   HTMLPurifier_AttrDef_HTML_Pixels.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

/**
 * Validates an integer representation of pixels according to the HTML spec.
 */
@interface HTMLPurifier_AttrDef_HTML_Pixels : HTMLPurifier_AttrDef

@property NSNumber* max;

/**
 * @param int $max
 */
- (id)initWithMax:(NSNumber*)newMax;

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
- (NSString*)validateWithString:(NSString*)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

/**
 * @param string $string
 * @return HTMLPurifier_AttrDef
 */
- (HTMLPurifier_AttrDef*)make:(NSString*)string;

@end
