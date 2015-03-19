//
//   HTMLPurifier_URIScheme_http.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIScheme.h"


/**
 * Validates http (HyperText Transfer Protocol) as defined by RFC 2616
 */
@interface HTMLPurifier_URIScheme_http : HTMLPurifier_URIScheme


/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
-(BOOL) doValidate:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
