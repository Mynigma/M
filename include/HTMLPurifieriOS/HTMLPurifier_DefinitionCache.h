//
//   HTMLPurifier_DefinitionCache.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 15.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config, HTMLPurifier_Definition;

/**
 * Abstract class representing Definition cache managers that implements
 * useful common methods and is a factory.
 * @todo Create a separate maintenance file advanced users can use to
 *       cache their custom HTMLDefinition, which can be loaded
 *       via a configuration directive
 * @todo Implement memcached
 */
@interface HTMLPurifier_DefinitionCache : NSObject


    /**
     * @type string
     */
@property NSString* typeString;

    /**
     * @param string $type Type of definition objects this instance of the
     *      cache will handle.
     */
- (id)initWithTypeString:(NSString*)type;

    /**
     * Generates a unique identifier for a particular configuration
     * @param HTMLPurifier_Config $config Instance of HTMLPurifier_Config
     * @return string
     */
- (NSString*)generateKey:(HTMLPurifier_Config*)config;

    /**
     * Tests whether or not a key is old with respect to the configuration's
     * version and revision number.
     * @param string $key Key to test
     * @param HTMLPurifier_Config $config Instance of HTMLPurifier_Config to test against
     * @return bool
     */
- (BOOL)isOld:(NSString*)key config:(HTMLPurifier_Config*)config;

    /**
     * Checks if a definition's type jives with the cache's type
     * @note Throws an error on failure
     * @param HTMLPurifier_Definition $def Definition object to check
     * @return bool true if good, false if not
     */
- (BOOL)checkDefType:(HTMLPurifier_Definition*)def;

    /**
     * Adds a definition object to the cache
     * @param HTMLPurifier_Definition $def
     * @param HTMLPurifier_Config $config
     */
- (void)add:(HTMLPurifier_Definition*)def config:(HTMLPurifier_Config*)config;

    /**
     * Unconditionally saves a definition object to the cache
     * @param HTMLPurifier_Definition $def
     * @param HTMLPurifier_Config $config
     */
- (void)set:(HTMLPurifier_Definition*)def config:(HTMLPurifier_Config*)config;

    /**
     * Replace an object in the cache
     * @param HTMLPurifier_Definition $def
     * @param HTMLPurifier_Config $config
     */
- (void)replace:(HTMLPurifier_Definition*)def config:(HTMLPurifier_Config*)config;

    /**
     * Retrieves a definition object from the cache
     * @param HTMLPurifier_Config $config
     */
- (HTMLPurifier_Definition*)get:(HTMLPurifier_Config*)config;

    /**
     * Removes a definition object to the cache
     * @param HTMLPurifier_Config $config
     */
- (void)remove:(HTMLPurifier_Config*)config;

    /**
     * Clears all objects from cache
     * @param HTMLPurifier_Config $config
     **/
- (void)flush:(HTMLPurifier_Config*)config;

    /**
     * Clears all expired (older version or revision) objects from cache
     * @note Be carefuly implementing this method as flush. Flush must
     *       not interfere with other Definition types, and cleanup()
     *       should not be repeatedly called by userland code.
     * @param HTMLPurifier_Config $config
     */
- (void)cleanup:(HTMLPurifier_Config*)config;



@end
