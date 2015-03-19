//
//   HTMLPurifier_Token_Empty.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import "HTMLPurifier_Token_Tag.h"

@class  HTMLPurifier_Node;

@interface HTMLPurifier_Token_Empty : HTMLPurifier_Token_Tag

- (HTMLPurifier_Node*)toNode;

@end
