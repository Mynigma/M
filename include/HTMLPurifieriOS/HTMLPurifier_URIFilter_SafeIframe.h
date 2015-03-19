//
//   HTMLPurifier_URIFilter_SafeIframe.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIFilter.h"

/**
 * Implements safety checks for safe iframes.
 *
 * @warning This filter is *critical* for ensuring that %HTML.SafeIframe
 * works safely.
 */
@interface HTMLPurifier_URIFilter_SafeIframe : HTMLPurifier_URIFilter


/**
 * @type string
 */
@property NSString* regexp; // = null;

// XXX: The not so good bit about how this is all set up now is we
// can't check HTML.SafeIframe in the 'prepare' step: we have to
// defer till the actual filtering.
/**
 * @param HTMLPurifier_Config $config
 * @return bool
 */
- (BOOL) prepare:(HTMLPurifier_Config*)config;

/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
- (BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;



@end
