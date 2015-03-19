//
//   HTMLPurifier_HTMLDefinition.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


#import "HTMLPurifier_Definition.h"

@class HTMLPurifier_Doctype, HTMLPurifier_ElementDef, HTMLPurifier_HTMLModule, HTMLPurifier_HTMLModuleManager;


/**
 * Definition of the purified HTML that describes allowed children,
 * attributes, and many other things.
 *
 * Conventions:
 *
 * All member variables that are prefixed with info
 * (including the main $info array) are used by HTML Purifier internals
 * and should not be directly edited when customizing the HTMLDefinition.
 * They can usually be set via configuration directives or custom
 * modules.
 *
 * On the other hand, member variables without the info prefix are used
 * internally by the HTMLDefinition and MUST NOT be used by other HTML
 * Purifier internals. Many of them, however, are public, and may be
 * edited by userspace code to tweak the behavior of HTMLDefinition.
 *
 * @note This class is inspected by Printer_HTMLDefinition; please
 *       update that class if things here change.
 *
 * @warning Directives that change this object's structure must be in
 *          the HTML or Attr namespace!
 */
@interface HTMLPurifier_HTMLDefinition : HTMLPurifier_Definition
{
    HTMLPurifier_HTMLModule* _anonModule;
}


// PUBLIC BUT INTERNAL VARIABLES --------------------------------------

/**
 * @type string
 */
@property NSString* typeString;

/**
 * @type HTMLPurifier_HTMLModuleManager
 */
@property HTMLPurifier_HTMLModuleManager* manager;



    // FULLY-PUBLIC VARIABLES ---------------------------------------------

    /**
     * Associative array of element names to HTMLPurifier_ElementDef.
     * @type HTMLPurifier_ElementDef[]
     */
@property NSMutableDictionary* info;

    /**
     * Associative array of global attribute name to attribute definition.
     * @type array
     */
@property NSMutableDictionary* info_global_attr;

    /**
     * String name of parent element HTML will be going into.
     * @type string
     */
@property NSString* info_parent;

    /**
     * Definition for parent element, allows parent element to be a
     * tag that's not allowed inside the HTML fragment.
     * @type HTMLPurifier_ElementDef
     */
@property HTMLPurifier_ElementDef* info_parent_def;

    /**
     * String name of element used to wrap inline elements in block context.
     * @type string
     * @note This is rarely used except for BLOCKQUOTEs in strict mode
     */
@property NSString* info_block_wrapper;

    /**
     * Associative array of deprecated tag name to HTMLPurifier_TagTransform.
     * @type array
     */
@property NSMutableDictionary* info_tag_transform;

    /**
     * Indexed list of HTMLPurifier_AttrTransform to be performed before validation.
     * @type HTMLPurifier_AttrTransform[]
     */
@property NSMutableDictionary* info_attr_transform_pre;

    /**
     * Indexed list of HTMLPurifier_AttrTransform to be performed after validation.
     * @type HTMLPurifier_AttrTransform[]
     */
@property NSMutableDictionary* info_attr_transform_post;

    /**
     * Nested lookup array of content set name (Block, Inline) to
     * element name to whether or not it belongs in that content set.
     * @type array
     */
@property NSMutableDictionary* info_content_sets;

    /**
     * Indexed list of HTMLPurifier_Injector to be used.
     * @type HTMLPurifier_Injector[]
     */
@property NSMutableDictionary* info_injector;

    /**
     * Doctype object
     * @type HTMLPurifier_Doctype
     */
@property HTMLPurifier_Doctype* doctype;



    // RAW CUSTOMIZATION STUFF --------------------------------------------

    /**
     * Adds a custom attribute to a pre-existing element
     * @note This is strictly convenience, and does not have a corresponding
     *       method in HTMLPurifier_HTMLModule
     * @param string $element_name Element name to add attribute to
     * @param string $attr_name Name of attribute
     * @param mixed $def Attribute definition, can be string or object, see
     *             HTMLPurifier_AttrTypes for details
     */
- (void)addAttribute:(NSString*)element_name attrName:(NSString*)attr_name def:(NSObject*)def;
    /**
     * Adds a custom element to your HTML definition
     * @see HTMLPurifier_HTMLModule::addElement() for detailed
     *       parameter and return value descriptions.
     */
- (HTMLPurifier_ElementDef*)addElement:(NSString*)element_name type:(NSString*)type contents:(NSDictionary*)contents attrCollections:(NSDictionary*)attr_collections attributes:(NSDictionary*)attributes;
    /**
     * Adds a blank element to your HTML definition, for overriding
     * existing behavior
     * @param string $element_name
     * @return HTMLPurifier_ElementDef
     * @see HTMLPurifier_HTMLModule::addBlankElement() for detailed
     *       parameter and return value descriptions.
     */
- (HTMLPurifier_ElementDef*)addBlankElement:(NSString*)element_name;
    /**
     * Retrieves a reference to the anonymous module, so you can
     * bust out advanced features without having to make your own
     * module.
     * @return HTMLPurifier_HTMLModule
     */
- (HTMLPurifier_HTMLModule*)getAnonymousModule;


    /**
     * @param HTMLPurifier_Config $config
     */
- (void)doSetup:(HTMLPurifier_Config*)config;
    /**
     * Extract out the information from the manager
     * @param HTMLPurifier_Config $config
     */
- (void)processModules:(HTMLPurifier_Config*)config;
    /**
     * Sets up stuff based on config. We need a better way of doing this.
     * @param HTMLPurifier_Config $config
     */
- (void)setupConfigStuff:(HTMLPurifier_Config*)config;
    /**
     * Parses a TinyMCE-flavored Allowed Elements and Attributes list into
     * separate lists for processing. Format is element[attr1|attr2],element2...
     * @warning Although it's largely drawn from TinyMCE's implementation,
     *      it is different, and you'll probably have to modify your lists
     * @param array $list String list to parse
     * @return array
     * @todo Give this its own class, probably static interface
     */
- (NSDictionary*)parseTinyMCEAllowedList:(NSArray*)list;


@end
