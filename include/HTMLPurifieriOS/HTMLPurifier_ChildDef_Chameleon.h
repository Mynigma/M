//
//   HTMLPurifier_ChildDef_Chameleon.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 18.01.14.


#import "HTMLPurifier_ChildDef.h"

@class HTMLPurifier_ChildDef_Optional;

/**
 * Definition that uses different definitions depending on context.
 *
 * The del and ins tags are notable because they allow different types of
 * elements depending on whether or not they're in a block or inline context.
 * Chameleon allows this behavior to happen by using two different
 * definitions depending on context.  While this somewhat generalized,
 * it is specifically intended for those two tags.
 */
@interface HTMLPurifier_ChildDef_Chameleon : HTMLPurifier_ChildDef


- (id)initWithInline:(NSArray*)inlineArray block:(NSArray*)blockArray;

/**
 * Instance of the definition object to use when inline. Usually stricter.
 * @type HTMLPurifier_ChildDef_Optional
 */
@property HTMLPurifier_ChildDef_Optional* inlineDef;

/**
 * Instance of the definition object to use when block.
 * @type HTMLPurifier_ChildDef_Optional
 */
@property HTMLPurifier_ChildDef_Optional* block;

/**
 * @type string
 */
@property NSString* typeString;


@end
