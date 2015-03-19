//
//   HTMLPurifier_ChildDef_Required.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 18.01.14.


#import "HTMLPurifier_ChildDef.h"

/**
 * Definition that allows a set of elements, but disallows empty children.
 */
@interface HTMLPurifier_ChildDef_Required : HTMLPurifier_ChildDef

- (id)initWithElements:(NSObject*)newElements;


- (NSObject*)validateChildren:(NSArray *)children config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
