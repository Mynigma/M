//
//   HTMLPurifier_AttrDef_CSS.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.



/**
 * Validates the HTML attribute style, otherwise known as CSS.
 * @note We don't implement the whole CSS specification, so it might be
 *       difficult to reuse this component in the context of validating
 *       actual stylesheet declarations.
 * @note If we were really serious about validating the CSS, we would
 *       tokenize the styles and then parse the tokens. Obviously, we
 *       are not doing that. Doing that could seriously harm performance,
 *       but would make these components a lot more viable for a CSS
 *       filtering solution.
 */

#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_CSS : HTMLPurifier_AttrDef

/**
 * @param string $css
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)css config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
