//
//   HTMLPurifier_ChildDef_StrictBlockquote.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 24.01.14.


#import "HTMLPurifier_ChildDef_Required.h"

@interface HTMLPurifier_ChildDef_StrictBlockquote : HTMLPurifier_ChildDef_Required


@property NSMutableDictionary* real_elements;

@property NSMutableDictionary* fake_elements;

@property BOOL allow_empty; // = true;

@property NSString* type; // = 'strictblockquote';

@property BOOL setup; // = false;



@end
