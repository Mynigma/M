//
//   HTMLPurifier_ElementDef.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_ChildDef;

/**
 * Structure that stores an HTML element definition. Used by
 * HTMLPurifier_HTMLDefinition and HTMLPurifier_HTMLModule.
 * @note This class is inspected by HTMLPurifier_Printer_HTMLDefinition.
 *       Please update that class too.
 * @warning If you add new properties to this class, you MUST update
 *          the mergeIn() method.
 */
@interface HTMLPurifier_ElementDef : NSObject

    /**
     * Does the definition work by itself, or is it created solely
     * for the purpose of merging into another definition?
     * @type bool
     */
@property BOOL standalone;

    /**
     * Associative array of attribute name to HTMLPurifier_AttrDef.
     * @type array
     * @note Before being processed by HTMLPurifier_AttrCollections
     *       when modules are finalized during
     *       HTMLPurifier_HTMLDefinition->setup(), this array may also
     *       contain an array at index 0 that indicates which attribute
     *       collections to load into the full array. It may also
     *       contain string indentifiers in lieu of HTMLPurifier_AttrDef,
     *       see HTMLPurifier_AttrTypes on how they are expanded during
     *       HTMLPurifier_HTMLDefinition->setup() processing.
     */
@property NSMutableDictionary* attr;

    // XXX: Design note: currently, it's not possible to override
    // previously defined AttrTransforms without messing around with
    // the final generated config. This is by design; a previous version
    // used an associated list of attr_transform, but it was extremely
    // easy to accidentally override other attribute transforms by
    // forgetting to specify an index (and just using 0.)  While we
    // could check this by checking the index number and complaining,
    // there is a second problem which is that it is not at all easy to
    // tell when something is getting overridden. Combine this with a
    // codebase where this isn't really being used, and it's perfect for
    // nuking.

    /**
     * List of tags HTMLPurifier_AttrTransform to be done before validation.
     * @type array
     */
@property NSMutableDictionary* attr_transform_pre;

    /**
     * List of tags HTMLPurifier_AttrTransform to be done after validation.
     * @type array
     */
@property NSMutableDictionary* attr_transform_post;

    /**
     * HTMLPurifier_ChildDef of this tag.
     * @type HTMLPurifier_ChildDef
     */
@property HTMLPurifier_ChildDef* child;

    /**
     * Abstract string representation of internal ChildDef rules.
     * @see HTMLPurifier_ContentSets for how this is parsed and then transformed
     * into an HTMLPurifier_ChildDef.
     * @warning This is a temporary variable that is not available after
     *      being processed by HTMLDefinition
     * @type string
     */
@property NSString* content_model;

    /**
     * Value of $child->type, used to determine which ChildDef to use,
     * used in combination with $content_model.
     * @warning This must be lowercase
     * @warning This is a temporary variable that is not available after
     *      being processed by HTMLDefinition
     * @type string
     */
@property NSString* content_model_type;

    /**
     * Does the element have a content model (#PCDATA | Inline)*? This
     * is important for chameleon ins and del processing in
     * HTMLPurifier_ChildDef_Chameleon. Dynamically set: modules don't
     * have to worry about this one.
     * @type bool
     */
@property BOOL descendants_are_inline;

    /**
     * List of the names of required attributes this element has.
     * Dynamically populated by HTMLPurifier_HTMLDefinition::getElement()
     * @type array
     */
@property NSMutableArray* required_attr;

    /**
     * Lookup table of tags excluded from all descendants of this tag.
     * @type array
     * @note SGML permits exclusions for all descendants, but this is
     *       not possible with DTDs or XML Schemas. W3C has elected to
     *       use complicated compositions of content_models to simulate
     *       exclusion for children, but we go the simpler, SGML-style
     *       route of flat-out exclusions, which correctly apply to
     *       all descendants and not just children. Note that the XHTML
     *       Modularization Abstract Modules are blithely unaware of such
     *       distinctions.
     */
@property NSMutableDictionary* excludes;

    /**
     * This tag is explicitly auto-closed by the following tags.
     * @type array
     */
@property NSMutableArray* autoclose;

    /**
     * If a foreign element is found in this element, test if it is
     * allowed by this sub-element; if it is, instead of closing the
     * current element, place it inside this element.
     * @type string
     */
@property NSString* wrap;

    /**
     * Whether or not this is a formatting element affected by the
     * "Active Formatting Elements" algorithm.
     * @type bool
     */
@property BOOL formatting;

    /**
     * Low-level factory constructor for creating new standalone element defs
     */
+ (HTMLPurifier_ElementDef*)create:(NSString*)content_model contentModelType:(NSString*)content_model_type attr:(NSDictionary*)attr;

/**
 * Merges the values of another element definition into this one.
 * Values from the new element def take precedence if a value is
 * not mergeable.
 * @param HTMLPurifier_ElementDef $def
 */
- (void)mergeIn:(HTMLPurifier_ElementDef*)def;

/**
 * Merges one array into another, removes values which equal false
 * @param $a1 Array by reference that is merged into
 * @param $a2 Array that merges into $a1
 */
- (void) _mergeIntoAssocArray:(NSMutableDictionary*)a1 from:(NSMutableDictionary*)a2;


- (id)copyWithZone:(NSZone *)zone;


@end
