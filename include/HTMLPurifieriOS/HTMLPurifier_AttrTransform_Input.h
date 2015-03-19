//
//   HTMLPurifier_AttrTransform_Input.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

@class HTMLPurifier_AttrDef_HTML_Pixels;
/**
 * Performs miscellaneous cross attribute validation and filtering for
 * input elements. This is meant to be a post-transform.
 */
@interface HTMLPurifier_AttrTransform_Input : HTMLPurifier_AttrTransform

/**
* @type HTMLPurifier_AttrDef_HTML_Pixels
*/
@property HTMLPurifier_AttrDef_HTML_Pixels* pixels;

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
