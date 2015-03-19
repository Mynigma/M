//
//   HTMLPurifier_AttrDef_CSS_FontFamily.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import "HTMLPurifier_AttrDef.h"

@class HTMLPurifier_Context, HTMLPurifier_Config;

/**
 * Validates a font family list according to CSS spec
 */
@interface HTMLPurifier_AttrDef_CSS_FontFamily : HTMLPurifier_AttrDef
{
    NSMutableString* mask;
}

- (NSString*)validateWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;



@end
