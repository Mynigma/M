//
//   HTMLPurifier_EntityLookup.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 16.01.14.


#import <Foundation/Foundation.h>

/**
 * Object that provides entity lookup table from entity name to character
 */
@interface HTMLPurifier_EntityLookup : NSObject
    /**
     * Assoc array of entity name to character represented.
     * @type array
     */
@property NSMutableDictionary* table;

    /**
     * Sets up the entity lookup table from the serialized file contents.
     * @param bool $file
     * @note The serialized contents are versioned, but were generated
     *       using the maintenance script generate_entity_file.php
     * @warning This is not in constructor to help enforce the Singleton
     */

    /**
     * Retrieves sole instance of the object.
     * @param bool|HTMLPurifier_EntityLookup $prototype Optional prototype of custom lookup table to overload with.
     * @return HTMLPurifier_EntityLookup
     */
+ (HTMLPurifier_EntityLookup*)instance;

+ (HTMLPurifier_EntityLookup*)instanceWithPrototype:(HTMLPurifier_EntityLookup*)prototype;



@end
