//
//   HTMLPurifier_AttrDef_HTML_Bool.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

#import "HTMLPurifier_AttrDef.h"

/**
 * Validates a boolean attribute
 */
@interface HTMLPurifier_AttrDef_HTML_Bool :HTMLPurifier_AttrDef

@property NSString* name;

@property BOOL minimized;


-(id)initWithName:(NSString*)newName;

/**
 * @param string $string
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return bool|string
 */

-(NSString*) validateWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * @param string $string Name of attribute
 * @return HTMLPurifier_AttrDef_HTML_Bool
 */
-(HTMLPurifier_AttrDef_HTML_Bool*) make:(NSString*)string;


@end
