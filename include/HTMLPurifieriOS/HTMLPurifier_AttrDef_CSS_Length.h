//
//   HTMLPurifier_AttrDef_CSS_Length.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

@class HTMLPurifier_Length;

@interface HTMLPurifier_AttrDef_CSS_Length : HTMLPurifier_AttrDef
{

    /**
     * @type HTMLPurifier_Length|string
     */
    HTMLPurifier_Length* min;

    /**
     * @type HTMLPurifier_Length|string
     */
    HTMLPurifier_Length* max;
}

- (id)initWithMin:(NSObject*)newMin max:(NSObject*)newMax;
- (id)initWithMin:(NSObject*)newMin;
- (id)init;

- (NSString*)validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;



@end
