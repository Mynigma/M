//
//   HTMLPurifier_AttrDef_Text.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.


#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_Text : HTMLPurifier_AttrDef

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
