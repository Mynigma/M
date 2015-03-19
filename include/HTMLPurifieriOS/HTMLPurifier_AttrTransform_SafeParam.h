//
//   HTMLPurifier_AttrTransform_SafeParam.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

@class HTMLPurifier_AttrDef_URI,HTMLPurifier_AttrDef_Enum;


/**
 * Validates name/value pairs in param tags to be used in safe objects. This
 * will only allow name values it recognizes, and pre-fill certain attributes
 * with required values.
 *
 * @note
 *      This class only supports Flash. In the future, Quicktime support
 *      may be added.
 *
 * @warning
 *      This class expects an injector to add the necessary parameters tags.
 */
@interface HTMLPurifier_AttrTransform_SafeParam : HTMLPurifier_AttrTransform

/**
 * @type string
 */
@property NSString* name; // = "SafeParam";

/**
 * @type HTMLPurifier_AttrDef_URI
 */
@property HTMLPurifier_AttrDef_URI* uri;

@property HTMLPurifier_AttrDef_Enum* wmode;

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
