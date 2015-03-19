//
//   HTMLPurifier_AttrDef_HTML_FrameTarget.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 11.01.14.


#import "HTMLPurifier_AttrDef_Enum.h"

@interface HTMLPurifier_AttrDef_HTML_FrameTarget : HTMLPurifier_AttrDef_Enum

@property BOOL case_sensitive;

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
