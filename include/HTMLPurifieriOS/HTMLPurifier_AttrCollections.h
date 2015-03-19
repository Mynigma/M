//
//   HTMLPurifier_AttrCollections.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 19.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_AttrTypes;

/**
 * Defines common attribute collections that modules reference
 */
@interface HTMLPurifier_AttrCollections : NSObject

   /**
     * Associative array of attribute collections, indexed by name.
     * @type array
     */
@property NSMutableDictionary* info;

    /**
     * Performs all expansions on internal data for use by other inclusions
     * It also collects all attribute collection extensions from
     * modules
     * @param HTMLPurifier_AttrTypes $attr_types HTMLPurifier_AttrTypes instance
     * @param HTMLPurifier_HTMLModule[] $modules Hash array of HTMLPurifier_HTMLModule members
     */
- (id)initWithAttrTypes:(HTMLPurifier_AttrTypes*)attr_types modules:(NSArray*)modules;


    /**
     * Takes a reference to an attribute associative array and performs
     * all inclusions specified by the zero index.
     * @param array &$attr Reference to attribute array
     */
- (void)performInclusions:(NSMutableDictionary*)attr;

/**
 * Expands all string identifiers in an attribute array by replacing
 * them with the appropriate values inside HTMLPurifier_AttrTypes
 * @param array &$attr Reference to attribute array
 * @param HTMLPurifier_AttrTypes $attr_types HTMLPurifier_AttrTypes instance
 */
- (void)expandIdentifiers:(NSMutableDictionary*)attr attrTypes:(HTMLPurifier_AttrTypes*)attr_types;



@end
