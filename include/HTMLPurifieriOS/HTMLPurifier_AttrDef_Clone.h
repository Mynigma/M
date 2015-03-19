//
//   HTMLPurifier_AttrDef_Clone.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.


/**
 * Dummy AttrDef that mimics another AttrDef, BUT it generates clones
 * with make.
 */
#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_Clone : HTMLPurifier_AttrDef

/**
 * What we're cloning.
 * @type HTMLPurifier_AttrDef
 */
@property HTMLPurifier_AttrDef* clone;

/**
 * @param HTMLPurifier_AttrDef $clone
 */
-(id) initWithClone:(HTMLPurifier_AttrDef*)nclone;

/**
 * @param string $v
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)string config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

/**
 * @param string $string
 * @return HTMLPurifier_AttrDef
 */
-(HTMLPurifier_AttrDef*) make:(NSString*)string;

@end
