//
//   HTMLPurifier_TagTransform_Font.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 18.01.14.


#import "HTMLPurifier_TagTransform.h"

/**
 * Transforms FONT tags to the proper form (SPAN with CSS styling)
 *
 * This transformation takes the three proprietary attributes of FONT and
 * transforms them into their corresponding CSS attributes.  These are color,
 * face, and size.
 *
 * @note Size is an interesting case because it doesn't map cleanly to CSS.
 *       Thanks to
 *       http://style.cleverchimp.com/font_size_intervals/altintervals.html
 *       for reasonable mappings.
 * @warning This doesn't work completely correctly; specifically, this
 *          TagTransform operates before well-formedness is enforced, so
 *          the "active formatting elements" algorithm doesn't get applied.
 */
@interface HTMLPurifier_TagTransform_Font : HTMLPurifier_TagTransform
{
    NSDictionary* _size_lookup;
}


@property NSString* transform_to;


    /**
     * @param HTMLPurifier_Token_Tag $tag
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return HTMLPurifier_Token_End|string
     */
- (NSObject*)transform:(HTMLPurifier_Token_Tag*)tag config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
