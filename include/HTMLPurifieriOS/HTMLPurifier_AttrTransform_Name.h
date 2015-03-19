//
//   HTMLPurifier_AttrTransform_Name.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"


/**
 * Pre-transform that changes deprecated name attribute to ID if necessary
 */
@interface HTMLPurifier_AttrTransform_Name : HTMLPurifier_AttrTransform

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
