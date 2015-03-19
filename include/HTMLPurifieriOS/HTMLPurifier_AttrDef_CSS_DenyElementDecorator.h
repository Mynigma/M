//
//   HTMLPurifier_AttrDef_CSS_DenyElementDecorator.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 15.01.14.



/**
 * Decorator which enables CSS properties to be disabled for specific elements.
 */

#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_CSS_DenyElementDecorator : HTMLPurifier_AttrDef

/**
* @type HTMLPurifier_AttrDef
*/
@property HTMLPurifier_AttrDef* def;

/**
 * @type string
 */
@property NSString* element;


/**
 * @param HTMLPurifier_AttrDef def Definition to wrap
 * @param string element Element to deny
 */
-(id) initWithDef:(HTMLPurifier_AttrDef*)ndef Element:(NSString*) nelement;

/**
 * Checks if CurrentToken is set and equal to this->element
 * @param string string
 * @param HTMLPurifier_Config config
 * @param HTMLPurifier_Context context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

@end
