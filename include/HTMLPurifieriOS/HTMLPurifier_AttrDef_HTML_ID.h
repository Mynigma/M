//
//   HTMLPurifier_AttrDef_HTML_ID.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 11.01.14.


#import "HTMLPurifier_AttrDef.h"

/**
 * Validates the HTML attribute ID.
 * @warning Even though this is the id processor, it
 *          will ignore the directive Attr:IDBlacklist, since it will only
 *          go according to the ID accumulator. Since the accumulator is
 *          automatically generated, it will have already absorbed the
 *          blacklist. If you're hacking around, make sure you use load()!
 */

@interface HTMLPurifier_AttrDef_HTML_ID : HTMLPurifier_AttrDef

/**
 * Determines whether or not we're validating an ID in a CSS
 * selector context.
 * @type bool
 */
@property NSNumber* selector;

/**
 * @param string $id
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString*)ID config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
