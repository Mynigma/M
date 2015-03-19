//
//   HTMLPurifier_Node_Element.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import "HTMLPurifier_Node.h"

/**
 * Concrete element node class.
 */
@interface HTMLPurifier_Node_Element : HTMLPurifier_Node

    /**
     * The lower-case name of the tag, like 'a', 'b' or 'blockquote'.
     *
     * @note Strictly speaking, XML tags are case sensitive, so we shouldn't
     * be lower-casing them, but these tokens cater to HTML tags, which are
     * insensitive.
     * @type string
     */

    /**
     * Associative array of the node's attributes.
     * @type array
     */
@property NSMutableDictionary* attr;

@property NSMutableArray* sortedAttrKeys;

/**
     * List of child elements.
     * @type array
     */

    /**
     * Does this use the <a></a> form or the </a> form, i.e.
     * is it a pair of start/end tokens or an empty token.
     * @bool
     */

@property NSNumber* endCol;

@property NSNumber* endLine;

@property NSMutableDictionary* endArmor;

- (id)initWithName:(NSString*)n;

- (id)initWithName:(NSString*)n attr:(NSMutableDictionary*)att sortedAttrKeys:(NSArray*)sortedAttrKeys line:(NSNumber*)l col:(NSNumber*)c armor:(NSMutableDictionary*)arm;

- (NSArray*)toTokenPair;


@end
