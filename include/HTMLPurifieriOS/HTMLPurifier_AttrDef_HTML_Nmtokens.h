//
//   HTMLPurifier_AttrDef_HTML_Nmtokens.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>
#import "HTMLPurifier_AttrDef.h"


/**
 * Validates contents based on NMTOKENS attribute type.
 */
@interface HTMLPurifier_AttrDef_HTML_Nmtokens : HTMLPurifier_AttrDef

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */
- (NSString*) validateWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


/**
 * Splits a space separated list of tokens into its constituent parts.
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return array
 */
-(NSMutableArray*) splitWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * Template method for removing certain tokens based on arbitrary criteria.
 * @note If we wanted to be really functional, we'd do an array_filter
 *       with a callback. But... we're not.
 * @param array $tokens
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return array
 */
- (NSMutableArray*) filterWithTokens:(NSMutableArray*)tokens config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
