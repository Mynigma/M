//
//   HTMLPurifier_AttrDef_CSS_Ident.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 15.01.14.


/**
 * Validates based on {ident} CSS grammar production
 */

#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_CSS_Ident : HTMLPurifier_AttrDef

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
