//
//   HTMLPurifier_AttrDef_URI.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.



/**
 * Validates a URI as defined by RFC 3986.
 * @note Scheme-specific mechanics deferred to HTMLPurifier_URIScheme
 */

#import "HTMLPurifier_AttrDef.h"

@class HTMLPurifier_Config, HTMLPurifier_Context, HTMLPurifier_URIParser, HTMLPurifier_AttrDef_URI;

@interface HTMLPurifier_AttrDef_URI : HTMLPurifier_AttrDef

/**
 * @type HTMLPurifier_URIParser
 */
@property HTMLPurifier_URIParser* parser;

/**
 * @type bool
 */
@property NSNumber* embedsResource;

/**
 * @param bool $embeds_resource Does the URI here result in an extra HTTP request?
 */
-(id)initWithNumber:(NSNumber*)new_embeds_resource;

/**
 * @param string $string
 * @return HTMLPurifier_AttrDef_URI
 */
-(HTMLPurifier_AttrDef_URI*) make:(NSString*)string;


/**
 * @param string $uri
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString *)uri config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;



@end
