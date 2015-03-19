//
//   HTMLPurifier_URIScheme_news.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIScheme.h"

/**
 * Validates news (Usenet) as defined by generic RFC 1738
 */
@interface HTMLPurifier_URIScheme_news : HTMLPurifier_URIScheme

/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
-(BOOL) doValidate:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
