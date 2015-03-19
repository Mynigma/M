//
//   HTMLPurifier_AttrDef_CSS_Multiple.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 10.01.14.


#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_CSS_Multiple : HTMLPurifier_AttrDef

@property HTMLPurifier_AttrDef* single;

@property NSInteger max;

- (id)initWithSingle:(HTMLPurifier_AttrDef*)single max:(NSInteger)max;
- (id)initWithSingle:(HTMLPurifier_AttrDef*)single;

- (NSString*)validateWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
