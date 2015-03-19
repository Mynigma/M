//
//   HTMLPurifier_AttrDef_HTML_Color.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_HTML_Color : HTMLPurifier_AttrDef

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */

-(NSString*)validateWithString:string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
