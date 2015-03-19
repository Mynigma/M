//
//   HTMLPurifier_HTMLModuleManager.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_DoctypeRegistry, HTMLPurifier_AttrTypes, HTMLPurifier_Config, HTMLPurifier_AttrCollections, HTMLPurifier_HTMLModule, HTMLPurifier_ElementDef, HTMLPurifier_ContentSets;

@interface HTMLPurifier_HTMLModuleManager : NSObject

/**
 * @type HTMLPurifier_DoctypeRegistry
 */
@property HTMLPurifier_DoctypeRegistry* doctypes;

/**
 * Instance of current doctype.
 * @type string
 */
@property NSObject* doctype;

/**
 * @type HTMLPurifier_AttrTypes
 */
@property HTMLPurifier_AttrTypes* attrTypes;

/**
 * Active instances of modules for the specified doctype are
 * indexed, by name, in this array.
 * @type HTMLPurifier_HTMLModule[]
 */
@property NSMutableArray* modules;

/**
 * Array of recognized HTMLPurifier_HTMLModule instances,
 * indexed by module's class name. This array is usually lazy loaded, but a
 * user can overload a module by pre-emptively registering it.
 * @type HTMLPurifier_HTMLModule[]
 */
@property NSMutableDictionary* registeredModules;

/**
 * List of extra modules that were added by the user
 * using addModule(). These get unconditionally merged into the current doctype, whatever
 * it may be.
 * @type HTMLPurifier_HTMLModule[]
 */
@property NSMutableArray* userModules;

/**
 * Associative array of element name to list of modules that have
 * definitions for the element; this array is dynamically filled.
 * @type array
 */
@property NSMutableDictionary* elementLookup;

/**
 * List of prefixes we should use for registering small names.
 * @type array
 */
@property NSMutableArray* prefixes;

/**
 * @type HTMLPurifier_ContentSets
 */
@property HTMLPurifier_ContentSets* contentSets;

/**
 * @type HTMLPurifier_AttrCollections
 */
@property HTMLPurifier_AttrCollections* attrCollections;

/**
 * If set to true, unsafe elements and attributes will be allowed.
 * @type bool
 */
@property BOOL trusted;

- (NSString*)registerModule:(NSObject*)module withConfig:(HTMLPurifier_Config*)config;

- (NSString*)registerModule:(NSObject*)module withConfig:(HTMLPurifier_Config*)config overload:(BOOL)overload;

/**
 * Adds a module to the current doctype by first registering it,
 * and then tacking it on to the active doctype
 */
- (void)addModule:(NSObject*)module withConfig:(HTMLPurifier_Config*)config;

/**
 * Adds a class prefix that registerModule() will use to resolve a
 * string name to a concrete class
 */
- (void)addPrefix:(NSString*)prefix;

/**
 * Performs processing on modules, after being called you may
 * use getElement() and getElements()
 * @param HTMLPurifier_Config $config
 */
- (void)setup:(HTMLPurifier_Config*)config;

/**
 * Takes a module and adds it to the active module collection,
 * registering it if necessary.
 */
- (void)processModule:(NSString*)module withConfig:(HTMLPurifier_Config*)config;

/**
 * Retrieves merged element definitions.
 * @return Array of HTMLPurifier_ElementDef
 */
- (NSMutableDictionary*)getElements;
/**
 * Retrieves a single merged element definition
 * @param string $name Name of element
 * @param bool $trusted Boolean trusted overriding parameter: set to true
 *                 if you want the full version of an element
 * @return HTMLPurifier_ElementDef Merged HTMLPurifier_ElementDef
 * @note You may notice that modules are getting iterated over twice (once
 *       in getElements() and once here). This
 *       is because
 */
- (HTMLPurifier_ElementDef*)getElement:(NSString*)name;

- (HTMLPurifier_ElementDef*)getElement:(NSString*)name trusted:(BOOL)trusted;


@end
