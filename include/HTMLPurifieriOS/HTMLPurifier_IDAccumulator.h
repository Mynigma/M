//
//   HTMLPurifier_IDAccumulator.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config, HTMLPurifier_Context;

/**
 * Component of HTMLPurifier_AttrContext that accumulates IDs to prevent dupes
 * @note In Slashdot-speak, dupe means duplicate.
 * @note The default constructor does not accept $config or $context objects:
 *       use must use the static build() factory method to perform initialization.
 */
@interface HTMLPurifier_IDAccumulator : NSObject

    /**
     * Lookup table of IDs we've accumulated.
     * @public
     */
@property NSMutableDictionary* ids;

- (id)init;

/**
 * Builds an IDAccumulator, also initializing the default blacklist
 * @param HTMLPurifier_Config $config Instance of HTMLPurifier_Config
 * @param HTMLPurifier_Context $context Instance of HTMLPurifier_Context
 * @return HTMLPurifier_IDAccumulator Fully initialized HTMLPurifier_IDAccumulator
 */
+ (HTMLPurifier_IDAccumulator*)buildWithConfig:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;
/**
 * Add an ID to the lookup table.
 * @param string $id ID to be added.
 * @return bool status, true if success, false if there's a dupe
 */
- (BOOL)addWithID:(id)newID;
/**
 * Load a list of IDs into the lookup table
 * @param $array_of_ids Array of IDs to load
 * @note This function doesn't care about duplicates
 */
- (void)loadWithIDs:(NSArray*)IDs;


@end
