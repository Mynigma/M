//
//   HTMLPurifier_DoctypeRegistry.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 19.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Doctype, HTMLPurifier_Config;

@interface HTMLPurifier_DoctypeRegistry : NSObject
{

    /**
     * Hash of doctype names to doctype objects.
     * @type array
     */
    NSMutableDictionary* doctypes;

    /**
     * Lookup table of aliases to real doctype names.
     * @type array
     */
    NSMutableDictionary* aliases;
}


/**
 * Registers a doctype to the registry
 * @note Accepts a fully-formed doctype object, or the
 *       parameters for constructing a doctype object
 * @param string $doctype Name of doctype or literal doctype object
 * @param bool $xml
 * @param array $modules Modules doctype will load
 * @param array $tidy_modules Modules doctype will load for certain modes
 * @param array $aliases Alias names for doctype
 * @param string $dtd_public
 * @param string $dtd_system
 * @return HTMLPurifier_Doctype Editable registered doctype
 */
- (HTMLPurifier_Doctype*)registerDoctype:(NSObject*)doctype xml:(BOOL)xml modules:(NSArray*)modules tidy_modules:(NSArray*)tidy_modules aliases:(NSArray*)newAliases dtdPublic:(NSString*)dtd_public dtdSystem:(NSString*)dtd_system;

/**
 * Retrieves reference to a doctype of a certain name
 * @note This function resolves aliases
 * @note When possible, use the more fully-featured make()
 * @param string $doctype Name of doctype
 * @return HTMLPurifier_Doctype Editable doctype object
 */
- (HTMLPurifier_Doctype*)getDoctype:(NSString*)doctype;

/**
 * Creates a doctype based on a configuration object,
 * will perform initialization on the doctype
 * @note Use this function to get a copy of doctype that config
 *       can hold on to (this is necessary in order to tell
 *       Generator whether or not the current document is XML
 *       based or not).
 * @param HTMLPurifier_Config $config
 * @return HTMLPurifier_Doctype
 */
- (HTMLPurifier_Doctype*)make:(HTMLPurifier_Config*)config;


/**
 * Retrieves the doctype from the configuration object
 * @param HTMLPurifier_Config $config
 * @return string
 */
- (NSString*)getDoctypeFromConfig:(HTMLPurifier_Config*)config;


@end
