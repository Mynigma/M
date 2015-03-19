//
//   HTMLPurifier_AttrDef_CSS_AlphaValue.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef_CSS_Number.h"

@interface HTMLPurifier_AttrDef_CSS_AlphaValue : HTMLPurifier_AttrDef_CSS_Number

- (NSString*)validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
