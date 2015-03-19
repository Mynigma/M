//
//   HTMLPurifier_AttrTransform_EnumToCSS.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

/**
 * Generic pre-transform that converts an attribute with a fixed number of
 * values (enumerated) to CSS.
 */
@interface HTMLPurifier_AttrTransform_EnumToCSS : HTMLPurifier_AttrTransform

/**
 * Name of attribute to transform from.
 * @type string
 */
@property NSString* attr_s;

/**
 * Lookup array of attribute values to CSS.
 * @type array
 */
@property NSDictionary* enumToCSS;

/**
 * Case sensitivity of the matching.
 * @type bool
 * @warning Currently can only be guaranteed to work with ASCII
 *          values.
 */
@property NSNumber* caseSensitive; // = false;

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(id) initWithAttr:(NSString*)attr enum:(NSDictionary*)enum_to_css caseSensitive:(NSNumber*)case_sensitive;


@end
