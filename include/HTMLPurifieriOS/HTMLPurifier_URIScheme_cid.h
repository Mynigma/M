//
//  HTMLPurifier_URIScheme_cid.h
//  HTMLPurifier
//
//  Created by Lukas Neumann on 14.02.14.

#import "HTMLPurifier_URIScheme.h"

@interface HTMLPurifier_URIScheme_cid : HTMLPurifier_URIScheme

/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
-(BOOL) doValidate:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
