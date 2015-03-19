//
//   HTMLPurifier_TagTransform_Simple.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 18.01.14.


#import "HTMLPurifier_TagTransform.h"

/**
 * Simple transformation, just change tag name to something else,
 * and possibly add some styling. This will cover most of the deprecated
 * tag cases.
 */
@interface HTMLPurifier_TagTransform_Simple : HTMLPurifier_TagTransform
{
    /**
     * @type string
     */
    NSString* style;
}


- (HTMLPurifier_Token_Tag*)transform:(HTMLPurifier_Token_Tag*)tag config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context *)context;


@end
