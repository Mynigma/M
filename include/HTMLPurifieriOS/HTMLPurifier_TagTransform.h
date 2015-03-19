//
//   HTMLPurifier_TagTransform.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 16.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Token_Tag, HTMLPurifier_Config, HTMLPurifier_Context;

/**
 * Defines a mutation of an obsolete tag into a valid tag.
 */
@interface HTMLPurifier_TagTransform : NSObject
    /**
     * Tag name to transform the tag to.
     * @type string
     */
@property NSString* transform_to;

    /**
     * Transforms the obsolete tag into the valid tag.
     * @param HTMLPurifier_Token_Tag $tag Tag to be transformed.
     * @param HTMLPurifier_Config $config Mandatory HTMLPurifier_Config object
     * @param HTMLPurifier_Context $context Mandatory HTMLPurifier_Context object
     */
- (HTMLPurifier_Token_Tag*)transform:(HTMLPurifier_Token_Tag*)tag config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

    /**
     * Prepends CSS properties to the style attribute, creating the
     * attribute if it doesn't exist.
     * @warning Copied over from AttrTransform, be sure to keep in sync
     * @param array $attr Attribute array to process (passed by reference)
     * @param string $css CSS to prepend
     */
- (void)prependCSS:(NSMutableDictionary*)attr css:(NSString*)css;


@end
