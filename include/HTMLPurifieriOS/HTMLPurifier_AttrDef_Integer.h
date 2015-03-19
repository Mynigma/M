//
//   HTMLPurifier_AttrDef_Integer.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.


/**
 * Validates an integer.
 * @note While this class was modeled off the CSS definition, no currently
 *       allowed CSS uses this type.  The properties that do are: widows,
 *       orphans, z-index, counter-increment, counter-reset.  Some of the
 *       HTML attributes, however, find use for a non-negative version of this.
 */

#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_Integer : HTMLPurifier_AttrDef

/**
 * Whether or not negative values are allowed.
 * @type bool
 */
@property NSNumber* negative;

/**
 * Whether or not zero is allowed.
 * @type bool
 */
@property NSNumber* zero;

/**
 * Whether or not positive values are allowed.
 * @type bool
 */
@property NSNumber* positive;

/**
 * @param $negative Bool indicating whether or not negative values are allowed
 * @param $zero Bool indicating whether or not zero is allowed
 * @param $positive Bool indicating whether or not positive values are allowed
 */
-(id) initWithNegative:(NSNumber*)nnegative Zero:(NSNumber*)nzero Positive:(NSNumber*)npositive;

/**
 * @param string $integer
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString*)integer config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
