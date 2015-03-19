//
//   HTMLPurifier_AttrDef_Number.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

@class HTMLPurifier_Config, HTMLPurifier_Context;

/**
 * Validates a number as defined by the CSS spec.
 */
@interface HTMLPurifier_AttrDef_CSS_Number : HTMLPurifier_AttrDef
{
    /**
     * Indicates whether or not only positive values are allowed.
     * @type bool
     */
    BOOL nonNegative;
}

- (id)initWithNonNegative:(BOOL)newNonNegative;


- (NSString*)validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
