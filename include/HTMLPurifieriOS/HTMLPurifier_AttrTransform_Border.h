//
//   HTMLPurifier_AttrTransform_Border.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

/**
 * Pre-transform that changes deprecated border attribute to CSS.
 */
@interface HTMLPurifier_AttrTransform_Border : HTMLPurifier_AttrTransform

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
