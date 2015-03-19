//
//   HTMLPurifier_URIFilter_HostBlacklist.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIFilter.h"

@interface HTMLPurifier_URIFilter_HostBlacklist : HTMLPurifier_URIFilter

/**
 * @type array
 */
@property NSArray* blacklist;

- (BOOL) prepare:(HTMLPurifier_Config*)config;

/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
- (BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
