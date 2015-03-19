//
//   HTMLPurifier_LanguageFactory.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Language, HTMLPurifier_Context, HTMLPurifier_Config;

/**
 * Class responsible for generating HTMLPurifier_Language objects, managing
 * caching and fallbacks.
 * @note Thanks to MediaWiki for the general logic, although this version
 *       has been entirely rewritten
 * @todo Serialized cache for languages
 */
@interface HTMLPurifier_LanguageFactory : NSObject
{
    /**
     * Cached copy of dirname(__FILE__), directory of current file without
     * trailing slash.
     * @type string
     */
    NSString* dir;

    /**
     * Keys whose contents are a hash map and can be merged.
     * @type array
     */
    NSMutableDictionary* mergeable_keys_map;

    /**
     * Keys whose contents are a list and can be merged.
     * @value array lookup
     */
    NSMutableDictionary* mergeable_keys_list;


}


@property NSMutableDictionary* cache;

    /**
     * Valid keys in the HTMLPurifier_Language object. Designates which
     * variables to slurp out of a message file.
     * @type array
     */
@property NSMutableArray* keys;

    /**
     * Instance to validate language codes.
     * @type HTMLPurifier_AttrDef_Lang
     *
     */
//    protected $validator;



    /**
     * Retrieve sole instance of the factory.
     * @param HTMLPurifier_LanguageFactory $prototype Optional prototype to overload sole instance with,
     *                   or bool true to reset to default factory.
     * @return HTMLPurifier_LanguageFactory
     */
+ (HTMLPurifier_LanguageFactory*)instance;
+ (HTMLPurifier_LanguageFactory*)instanceWithPrototype:(HTMLPurifier_LanguageFactory*)prototype;

    /**
     * Sets up the singleton, much like a constructor
     * @note Prevents people from getting this outside of the singleton
     */
- (void)setup;

    /**
     * Creates a language object, handles class fallbacks
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @param bool|string $code Code to override configuration with. Private parameter.
     * @return HTMLPurifier_Language
     */
- (HTMLPurifier_Language*)create:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

    /**
     * Returns the fallback language for language
     * @note Loads the original language into cache
     * @param string $code language code
     * @return string|bool
     */
- (NSString*)getFallbackFor:(NSString*)code;
    /**
     * Loads language into the cache, handles message file and fallbacks
     * @param string $code language code
     */
- (NSString*)loadLanguage:(NSString*)code;

@end
