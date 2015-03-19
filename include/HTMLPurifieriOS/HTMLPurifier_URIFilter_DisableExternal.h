//
//   HTMLPurifier_URIFilter_DisableExternal.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIFilter.h"

@interface HTMLPurifier_URIFilter_DisableExternal : HTMLPurifier_URIFilter

/**
 * @type array
 */
@property NSArray* ourHostParts;

/**
 * @param HTMLPurifier_Config $config
 * @return void
 */

// VOID OR BOOL ?
- (BOOL) prepare:(HTMLPurifier_Config*)config;

/**
 * @param HTMLPurifier_URI $uri Reference
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
- (BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
