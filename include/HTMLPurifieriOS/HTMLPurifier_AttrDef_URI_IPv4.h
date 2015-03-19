//
//   HTMLPurifier_AttrDef_URI_IPv4.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 12.01.14.


#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_URI_IPv4 : HTMLPurifier_AttrDef

/**
 * IPv4 regex, protected so that IPv6 can reuse it.
 * @type string
 */
@property NSString* ip4;

/**
 * @param string $aIP
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) validateWithString:(NSString*)aIP config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * Lazy load function to prevent regex from being stuffed in
 * cache.
 */
-(void) loadRegex;


@end
