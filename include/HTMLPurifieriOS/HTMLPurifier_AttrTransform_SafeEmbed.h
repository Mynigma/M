//
//   HTMLPurifier_AttrTransform_SafeEmbed.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

@interface HTMLPurifier_AttrTransform_SafeEmbed : HTMLPurifier_AttrTransform

/**
 * @type string
 */
@property NSString* name; // = "SafeEmbed";

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
