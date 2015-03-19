//
//   HTMLPurifier_Tidy.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 25.01.14.


#import "HTMLPurifier_HTMLModule.h"

/**
 * Abstract class for a set of proprietary modules that clean up (tidy)
 * poorly written HTML.
 * @todo Figure out how to protect some of these methods/properties
 */
@interface HTMLPurifier_HTMLModule_Tidy : HTMLPurifier_HTMLModule

/**
 * List of supported levels.
 * Index zero is a special case "no fixes" level.
 * @type array
 */
@property NSArray* levels;

/**
 * Default level to place all fixes in.
 * Disabled by default.
 * @type string
 */
@property NSString* defaultLevel;

/**
 * Lists of fixes used by getFixesForLevel().
 * Format is:
 *      HTMLModule_Tidy->fixesForLevel[$level] = array('fix-1', 'fix-2');
 * @type array
 */
@property NSMutableDictionary* fixesForLevel;


@end
