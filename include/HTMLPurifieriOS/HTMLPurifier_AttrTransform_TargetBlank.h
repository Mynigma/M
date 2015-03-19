//
//   HTMLPurifier_AttrTransform_TargetBlank.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

@class HTMLPurifier_URIParser;

/**
 * Adds target="blank" to all outbound links.  This transform is
 * only attached if Attr.TargetBlank is TRUE.  This works regardless
 * of whether or not Attr.AllowedFrameTargets
 */
@interface HTMLPurifier_AttrTransform_TargetBlank : HTMLPurifier_AttrTransform

/**
 * @type HTMLPurifier_URIParser
 */
@property HTMLPurifier_URIParser* parser;

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
