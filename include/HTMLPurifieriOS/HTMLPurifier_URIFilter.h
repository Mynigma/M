//
//   HTMLPurifier_URIFilter.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config,HTMLPurifier_Context,HTMLPurifier_URI;

@interface HTMLPurifier_URIFilter : NSObject

/**
 * Unique identifier of filter.
 * @type string
 */
@property NSString* name;

/**
 * True if this filter should be run after scheme validation.
 * @type bool
 */
@property BOOL post; // = false;

/**
 * True if this filter should always be loaded.
 * This permits a filter to be named Foo without the corresponding
 * %URI.Foo directive existing.
 * @type bool
 */
@property BOOL always_load; // = false;

- (BOOL) prepare:(HTMLPurifier_Config*)config;

- (BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
