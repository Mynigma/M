//
//   HTMLPurifier_PropertyList.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 15.01.14.


#import <Foundation/Foundation.h>

/**
 * Generic property list implementation
 */
@interface HTMLPurifier_PropertyList : NSObject
{
    /**
     * Internal data-structure for properties.
     * @type array
     */
    NSMutableDictionary* data;

    /**
     * Parent plist.
     * @type HTMLPurifier_PropertyList
     */
    HTMLPurifier_PropertyList* parent;

    /**
     * Cache.
     * @type array
     */
    NSMutableDictionary* cache;
}

- (id)initWithParent:(HTMLPurifier_PropertyList*)parentPlist;
- (id)init;

/**
 * Recursively retrieves the value for a key
 * @param string $name
 * @throws HTMLPurifier_Exception
 */
- (NSObject*)get:(NSString*)name;
/**
 * Sets the value of a key, for this plist
 * @param string $name
 * @param mixed $value
 */
- (void)set:(NSString*)name value:(NSObject*)value;
/**
 * Returns true if a given key exists
 * @param string $name
 * @return bool
 */
- (BOOL)has:(NSString*)name;

/**
 * Resets a value to the value of it's parent, usually the default. If
 * no value is specified, the entire plist is reset.
 * @param string $name
 */
- (void)reset:(NSString*)name;

- (void)reset;

/**
 * Squashes this property list and all of its property lists into a single
 * array, and returns the array. This value is cached by default.
 * @param bool $force If true, ignores the cache and regenerates the array.
 * @return array
 */
- (NSDictionary*)squash:(BOOL)force;

- (NSDictionary*)squash;

/**
 * Returns the parent plist.
 * @return HTMLPurifier_PropertyList
 */
- (HTMLPurifier_PropertyList*)getParent;
/**
 * Sets the parent plist.
 * @param HTMLPurifier_PropertyList $plist Parent plist
 */
- (void)setParent:(HTMLPurifier_PropertyList*)plist;




@end
