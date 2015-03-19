//
//   HTMLPurifier_ContentSets.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 19.01.14.


#import <Foundation/Foundation.h>


@class HTMLPurifier_HTMLModule, HTMLPurifier_ChildDef, HTMLPurifier_ElementDef;


@interface HTMLPurifier_ContentSets : NSObject



    /**
     * List of content set strings (pipe separators) indexed by name.
     * @type array
     */
@property NSMutableDictionary* info;

    /**
     * List of content set lookups (element => true) indexed by name.
     * @type array
     * @note This is in HTMLPurifier_HTMLDefinition->info_content_sets
     */
@property NSMutableDictionary* lookup;

    /**
     * Synchronized list of defined content sets (keys of info).
     * @type array
     */
@property NSMutableSet* keys;
    /**
     * Synchronized list of defined content values (values of info).
     * @type array
     */
@property NSMutableSet* values;

    /**
     * Merges in module's content sets, expands identifiers in the content
     * sets and populates the keys, values and lookup member variables.
     * @param HTMLPurifier_HTMLModule[] $modules List of HTMLPurifier_HTMLModule
     */
- (id)initWithModules:(NSObject*)modules;


/**
 * Accepts a definition; generates and assigns a ChildDef for it
 * @param HTMLPurifier_ElementDef $def HTMLPurifier_ElementDef reference
 * @param HTMLPurifier_HTMLModule $module Module that defined the ElementDef
 */
- (void)generateChildDef:(HTMLPurifier_ElementDef*)def module:(HTMLPurifier_HTMLModule*)module;

- (NSString*)generateChildDefCallback:(NSArray*)matches;

/**
 * Instantiates a ChildDef based on content_model and content_model_type
 * member variables in HTMLPurifier_ElementDef
 * @note This will also defer to modules for custom HTMLPurifier_ChildDef
 *       subclasses that need content set expansion
 * @param HTMLPurifier_ElementDef $def HTMLPurifier_ElementDef to have ChildDef extracted
 * @param HTMLPurifier_HTMLModule $module Module that defined the ElementDef
 * @return HTMLPurifier_ChildDef corresponding to ElementDef
 */
- (HTMLPurifier_ChildDef*)getChildDef:(HTMLPurifier_ElementDef*)def module:(HTMLPurifier_HTMLModule*)module;

                      /**
                       * Converts a string list of elements separated by pipes into
                       * a lookup array.
                       * @param string $string List of elements
                       * @return array Lookup array of elements
                       */
- (NSSet*)convertToLookup:(NSString*)string;

@end
