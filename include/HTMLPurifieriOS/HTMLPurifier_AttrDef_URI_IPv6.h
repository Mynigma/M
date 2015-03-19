//
//   HTMLPurifier_AttrDef_URI_IPv6.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 12.01.14.


#import "HTMLPurifier_AttrDef_URI_IPv4.h"

@interface HTMLPurifier_AttrDef_URI_IPv6 : HTMLPurifier_AttrDef_URI_IPv4

/**
 * @param string $aIP
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)aIP config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
