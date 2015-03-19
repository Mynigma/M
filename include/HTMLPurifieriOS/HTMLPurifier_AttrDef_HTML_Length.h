//
//   HTMLPurifier_AttrDef_HTML_Length.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 12.01.14.


#import "HTMLPurifier_AttrDef_HTML_Pixels.h"

@interface HTMLPurifier_AttrDef_HTML_Length : HTMLPurifier_AttrDef_HTML_Pixels

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
- (NSString*)validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
