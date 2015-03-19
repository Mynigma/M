//
//   HTMLPurifier_AttrTransform_Length.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

/**
 * Class for handling width/height length attribute transformations to CSS
 */
@interface HTMLPurifier_AttrTransform_Length : HTMLPurifier_AttrTransform

/**
* @type string
*/
@property NSString* name;

/**
 * @type string
 */
@property NSString* cssName;

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(id) initWithName:(NSString*)nname css:(NSString*)css_name;

-(id) initWithName:(NSString*)nname;


@end
