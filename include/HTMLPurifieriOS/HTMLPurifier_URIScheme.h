//
//   HTMLPurifier_URIScheme.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.



/**
 * Validator for the components of a URI for a specific scheme
 */
#import <Foundation/Foundation.h>

@class HTMLPurifier_URI,HTMLPurifier_Config,HTMLPurifier_Context;

@interface HTMLPurifier_URIScheme : NSObject

/**
 * Scheme's default port (integer). If an explicit port number is
 * specified that coincides with the default port, it will be
 * elided.
 * @type int
 */
@property NSNumber* default_port;  //= null;

/**
 * Whether or not URIs of this scheme are locatable by a browser
 * http and ftp are accessible, while mailto and news are not.
 * @type bool
 */
@property NSNumber* browsable; // = false;

/**
 * Whether or not data transmitted over this scheme is encrypted.
 * https is secure, http is not.
 * @type bool
 */
@property NSNumber* secure; // = false;

/**
 * Whether or not the URI always uses <hier_part>, resolves edge cases
 * with making relative URIs absolute
 * @type bool
 */
@property NSNumber* hierarchical; // = false;

/**
 * Whether or not the URI may omit a hostname when the scheme is
 * explicitly specified, ala file:///path/to/file. As of writing,
 * 'file' is the only scheme that browsers support his properly.
 * @type bool
 */
@property NSNumber* may_omit_host; // = false;

/**
 * Validates the components of a URI for a specific scheme.
 * @param HTMLPurifier_URI $uri Reference to a HTMLPurifier_URI object
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool success or failure
 */
-(BOOL) doValidate:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * Public interface for validating components of a URI.  Performs a
 * bunch of default actions. Don't overload this method.
 * @param HTMLPurifier_URI $uri Reference to a HTMLPurifier_URI object
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool success or failure
 */
-(BOOL) validate:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;




@end
