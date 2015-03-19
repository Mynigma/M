//
//   HTMLPurifier_AttrDef_CSS_Border.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_CSS_Border : HTMLPurifier_AttrDef
/**
 * Validates the border property as defined by CSS.
 */
{

/**
     * Local copy of properties this property is shorthand for.
     * @type HTMLPurifier_AttrDef[]
     */
    NSMutableDictionary* info;
}


- (id)initWithConfig:(HTMLPurifier_Config*)config;

- (NSString*)validateWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
