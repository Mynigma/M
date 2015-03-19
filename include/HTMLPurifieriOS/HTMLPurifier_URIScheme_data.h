//
//   HTMLPurifier_URIScheme_data.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIScheme.h"

/**
 * Implements data: URI for base64 encoded images supported by GD.
 */
@interface HTMLPurifier_URIScheme_data : HTMLPurifier_URIScheme


/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
-(BOOL) doValidate:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end