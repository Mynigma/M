//
//   HTMLPurifier_AttrDef_HTML_Class.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import "HTMLPurifier_AttrDef_HTML_Nmtokens.h"

/**
 * Implements special behavior for class attribute (normally NMTOKENS)
 */
@interface HTMLPurifier_AttrDef_HTML_Class : HTMLPurifier_AttrDef_HTML_Nmtokens

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
-(NSString*) splitWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * @param array $tokens
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return array
 */
-(NSMutableArray*) filterWithTokens:(NSMutableArray*)tokens config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
