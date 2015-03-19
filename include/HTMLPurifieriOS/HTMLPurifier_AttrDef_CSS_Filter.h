//
//   HTMLPurifier_AttrDef_CSS_Filter.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 15.01.14.


#import "HTMLPurifier_AttrDef.h"
#import "HTMLPurifier_AttrDef_Integer.h"

/**
 * Microsoft's proprietary filter: CSS property
 * @note Currently supports the alpha filter. In the future, this will
 *       probably need an extensible framework
 */

@interface HTMLPurifier_AttrDef_CSS_Filter : HTMLPurifier_AttrDef

/**
 * @type HTMLPurifier_AttrDef_Integer
 */
@property HTMLPurifier_AttrDef_Integer*  intValidator;

-(id) init;

@end
