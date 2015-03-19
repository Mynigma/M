//
//   HTMLPurifier_AttrTransform_BgColor.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


/**
 * Pre-transform that changes deprecated bgcolor attribute to CSS.
 */
#import "HTMLPurifier_AttrTransform.h"

@interface HTMLPurifier_AttrTransform_BgColor : HTMLPurifier_AttrTransform

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
