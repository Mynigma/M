//
//   HTMLPurifier_AttrDef_CSS_ImportantDecorator.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 15.01.14.


/**
 * Decorator which enables !important to be used in CSS values.
 */

#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_CSS_ImportantDecorator : HTMLPurifier_AttrDef

/**
 * @type HTMLPurifier_AttrDef
 */
@property HTMLPurifier_AttrDef* def;

/**
 * @type bool
 */
@property NSNumber* allow;


/**
 * @param HTMLPurifier_AttrDef $def Definition to wrap
 * @param bool $allow Whether or not to allow !important
 */
-(id) initWithDef:(HTMLPurifier_AttrDef*)ndef AllowImportant:(NSNumber*)nallow;

/**
 * Intercepts and removes !important if necessary
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
