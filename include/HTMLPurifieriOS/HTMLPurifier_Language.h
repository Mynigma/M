//
//   HTMLPurifier_Language.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config, HTMLPurifier_Context;

/**
 * Represents a language and defines localizable string formatting and
 * other functions, as well as the localized messages for HTML Purifier.
 */
@interface HTMLPurifier_Language : NSObject
{
    HTMLPurifier_Config* config;
    HTMLPurifier_Context* context;
}


/**
 * ISO 639 language code of language. Prefers shortest possible version.
 * @type string
 */

@property NSString* code;

    /**
     * Fallback language code.
     * @type bool|string
     */
@property NSString* fallback;

    /**
     * Array of localizable messages.
     * @type array
     */
@property NSMutableDictionary* messages;

    /**
     * Array of localizable error codes.
     * @type array
     */
@property NSMutableDictionary* errorNames;

    /**
     * True if no message file was found for this language, so English
     * is being used instead. Check this if you'd like to notify the
     * user that they've used a non-supported language.
     * @type bool
     */
@property BOOL error;

    /**
     * Has the language object been loaded yet?
     * @type bool
     * @todo Make it private, fix usage in HTMLPurifier_LanguageTest
     */
@property BOOL loaded;


- (id)initWithConfig:(HTMLPurifier_Config*)newConfig context:(HTMLPurifier_Context*)newContext;
- (id)initWithConfig:(HTMLPurifier_Config*)newConfig;

    /**
     * Loads language object with necessary info from factory cache
     * @note This is a lazy loader
     */
- (void)load;

    /**
     * Retrieves a localised message.
     * @param string $key string identifier of message
     * @return string localised message
     */
- (NSString*)getMessage:(NSString*)key;

    /**
     * Retrieves a localised error name.
     * @param int $int error number, corresponding to PHP's error reporting
     * @return string localised message
     */
- (NSString*)getErrorName:(NSInteger)phpErrorCode;

    /**
     * Converts an array list into a string readable representation
     * @param array $array
     * @return string
     */
- (NSString*)listify:(NSObject*)object;

    /**
     * Formats a localised message with passed parameters
     * @param string $key string identifier of message
     * @param array $args Parameters to substitute in
     * @return string localised message
     * @todo Implement conditionals? Right now, some messages make
     *     reference to line numbers, but those aren't always available
     */
- (NSString*)formatMessage:(NSString*)key;
- (NSString*)formatMessage:(NSString*)key args:(NSArray*)args;


@end
