//
//   HTMLPurifier_URIFilter_DisableExternalResources.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIFilter_DisableExternal.h"

@interface HTMLPurifier_URIFilter_DisableExternalResources : HTMLPurifier_URIFilter_DisableExternal

/**
 * @param HTMLPurifier_URI $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool
 */
- (BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
