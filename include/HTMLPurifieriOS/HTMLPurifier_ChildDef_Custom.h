//
//   HTMLPurifier_ChildDef_Custom.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 19.01.14.


#import "HTMLPurifier_ChildDef.h"

/**
 * Custom validation class, accepts DTD child definitions
 *
 * @warning Currently this class is an all or nothing proposition, that is,
 *          it will only give a bool return value.
 */
@interface HTMLPurifier_ChildDef_Custom : HTMLPurifier_ChildDef
{
    /**
     * PCRE regex derived from $dtd_regex.
     * @type string
     */
    NSString* _pcre_regex;
}
    /**
     * @type string
     */
@property NSString* typeString;

    /**
     * @type bool
     */
@property BOOL allow_empty;

    /**
     * Allowed child pattern as defined by the DTD.
     * @type string
     */
@property NSString* dtd_regex;



- (id)initWithDtdRegex:(NSString*)dtd_regex;


@end
