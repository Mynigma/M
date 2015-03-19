//
//   HTMLPurifier_VarParser_Flexible.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


#import "HTMLPurifier_VarParser.h"

/**
 * Performs safe variable parsing based on types which can be used by
 * users. This may not be able to represent all possible data inputs,
 * however.
 */
@interface HTMLPurifier_VarParser_Flexible : HTMLPurifier_VarParser

    /**
     * @param mixed $var
     * @param int $type
     * @param bool $allow_null
     * @return array|bool|float|int|mixed|null|string
     * @throws HTMLPurifier_VarParserException
     */
- (NSObject*)parseImplementation:var type:(NSNumber*)type allowNull:(BOOL)allow_null;


@end
