//
//   HTMLPurifier_Definition.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config;

/**
 * Super-class for definition datatype objects, implements serialization
 * functions for the class.
 */
@interface HTMLPurifier_Definition : NSObject


    /**
     * Has setup() been called yet?
     * @type bool
     */
@property BOOL setup;

    /**
     * If true, write out the final definition object to the cache after
     * setup.  This will be true only if all invocations to get a raw
     * definition object are also optimized.  This does not cause file
     * system thrashing because on subsequent calls the cached object
     * is used and any writes to the raw definition object are short
     * circuited.  See enduser-customize.html for the high-level
     * picture.
     * @type bool
     */
@property BOOL optimized;

    /**
     * What type of definition is it?
     * @type string
     */
@property NSString* type;

    /**
     * Sets up the definition object into the final form, something
     * not done by the constructor
     * @param HTMLPurifier_Config $config
     */
- (void)doSetup:(HTMLPurifier_Config*)config;

    /**
     * Setup function that aborts if already setup
     * @param HTMLPurifier_Config $config
     */
- (void)setup:(HTMLPurifier_Config*)config;



@end
