//
//   HTMLPurifier_AttrTransform_BdoDir.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 22.01.14.


#import "HTMLPurifier_AttrTransform.h"

// this MUST be placed in post, as it assumes that any value in dir is valid

/**
 * Post-trasnform that ensures that bdo tags have the dir attribute set.
 */
@interface HTMLPurifier_AttrTransform_BdoDir : HTMLPurifier_AttrTransform

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
