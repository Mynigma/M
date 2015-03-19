//
//   HTMLPurifier_AttrDef_URI_Email.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 12.01.14.


#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_URI_Email : HTMLPurifier_AttrDef

/**
 * Unpacks a mailbox into its display-name and address
 * @param string $string
 * @return mixed
 */
-(NSMutableDictionary*) unpackWithString:(NSString*)string;

@end
