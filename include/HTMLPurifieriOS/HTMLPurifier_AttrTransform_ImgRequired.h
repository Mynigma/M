//
//   HTMLPurifier_AttrTransform_ImgRequired.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 18.01.14.


#import "HTMLPurifier_AttrTransform.h"

@interface HTMLPurifier_AttrTransform_ImgRequired : HTMLPurifier_AttrTransform


- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
