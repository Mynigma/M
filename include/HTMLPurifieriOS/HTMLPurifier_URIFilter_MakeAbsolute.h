//
//   HTMLPurifier_URIFilter_MakeAbsolute.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIFilter.h"

@interface HTMLPurifier_URIFilter_MakeAbsolute : HTMLPurifier_URIFilter

/**
 * @type
 */
@property HTMLPurifier_URI* base;

/**
 * @type array
 */
@property NSMutableArray* basePathStack;  //= array();

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
-(BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * Resolve dots and double-dots in a path stack
 * @param array $stack
 * @return array
 */
-(NSMutableArray*) collapseStack:(NSArray*)stack;


@end
