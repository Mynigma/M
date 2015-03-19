//
//   HTMLPurifier_AttrTransform_Nofollow.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 23.01.14.


#import "HTMLPurifier_AttrTransform.h"

@class HTMLPurifier_URIParser;

/**
 * Adds rel="nofollow" to all outbound links.  This transform is
 * only attached if Attr.Nofollow is TRUE.
 */
@interface HTMLPurifier_AttrTransform_Nofollow : HTMLPurifier_AttrTransform

/**
 * @type HTMLPurifier_URIParser
 */
@property HTMLPurifier_URIParser* parser;

- (NSDictionary*)transform:(NSDictionary*)attr sortedKeys:(NSMutableArray*)sortedKeys config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
