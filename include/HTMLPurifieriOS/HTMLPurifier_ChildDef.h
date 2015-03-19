//
//   HTMLPurifier_ChildDef.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 15.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Context, HTMLPurifier_Config;

/**
 * Defines allowed child nodes and validates nodes against it.
 */
@interface HTMLPurifier_ChildDef : NSObject
{
    BOOL whitespace;
}

    /**
     * Type of child definition, usually right-most part of class name lowercase.
     * Used occasionally in terms of context.
     * @type string
     */
@property NSString* typeString;

    /**
     * Indicates whether or not an empty array of children is okay.
     *
     * This is necessary for redundant checking when changes affecting
     * a child node may cause a parent node to now be disallowed.
     * @type bool
     */
@property BOOL allow_empty;

    /**
     * Lookup array of all elements that this definition could possibly allow.
     * @type array
     */
@property NSMutableDictionary* elements;

    /**
     * Get lookup of tag names that should not close this element automatically.
     * All other elements will do so.
     * @param HTMLPurifier_Config $config HTMLPurifier_Config object
     * @return array
     */
- (NSMutableDictionary*)getAllowedElements:(HTMLPurifier_Config*)config;

    /**
     * Validates nodes according to definition and returns modification.
     *
     * @param HTMLPurifier_Node[] $children Array of HTMLPurifier_Node
     * @param HTMLPurifier_Config $config HTMLPurifier_Config object
     * @param HTMLPurifier_Context $context HTMLPurifier_Context object
     * @return bool|array true to leave nodes as is, false to remove parent node, array of replacement children
     */
- (NSObject*)validateChildren:(NSArray*)children config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;




@end
