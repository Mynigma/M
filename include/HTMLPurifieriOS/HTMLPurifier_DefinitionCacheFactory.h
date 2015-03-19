//
//   HTMLPurifier_DefinitionCacheFactory.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 15.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config;

/**
 * Responsible for creating definition caches.
 */
@interface HTMLPurifier_DefinitionCacheFactory : NSObject
{
    /**
     * @type array
     */
    NSMutableDictionary* caches;

    /**
     * @type array
     */
    NSMutableDictionary* implementations;

    /**
     * @type HTMLPurifier_DefinitionCache_Decorator[]
     */
    NSMutableDictionary* decorators;
}
    /**
     * Initialize default decorators
     */
- (void)setup;
    /**
     * Retrieves an instance of global definition cache factory.
     * @param HTMLPurifier_DefinitionCacheFactory $prototype
     * @return HTMLPurifier_DefinitionCacheFactory
     */
+ (HTMLPurifier_DefinitionCacheFactory*)instance;
+ (HTMLPurifier_DefinitionCacheFactory*)instanceWithPrototype:(HTMLPurifier_DefinitionCacheFactory*)prototype;

    /**
     * Registers a new definition cache object
     * @param string $short Short name of cache object, for reference
     * @param string $long Full class name of cache object, for construction
     */
- (void)registerWithShortName:(NSString*)shortName longName:(NSString*)longName;

    /**
     * Factory method that creates a cache object based on configuration
     * @param string $type Name of definitions handled by cache
     * @param HTMLPurifier_Config $config Config instance
     * @return mixed
     */
- (NSObject*)create:(NSString*)type config:(HTMLPurifier_Config*)config;

    /**
     * Registers a decorator to add to all new cache objects
     * @param HTMLPurifier_DefinitionCache_Decorator|string $decorator An instance or the name of a decorator
     */
- (void)addDecorator:(NSObject*)decorator;


@end
