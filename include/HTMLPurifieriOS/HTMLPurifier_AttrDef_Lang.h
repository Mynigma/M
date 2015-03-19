//
//   HTMLPurifier_AttrDef_Lang.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.


/**
 * Validates the HTML attribute lang, effectively a language code.
 * @note Built according to RFC 3066, which obsoleted RFC 1766
 */

#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_Lang : HTMLPurifier_AttrDef

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */

-(NSString*) validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
