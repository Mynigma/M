//
//   HTMLPurifier_URIScheme_file.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIScheme.h"

/**
 * Validates file as defined by RFC 1630 and RFC 1738.
 */
@interface HTMLPurifier_URIScheme_file : HTMLPurifier_URIScheme

/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
-(BOOL) doValidate:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
