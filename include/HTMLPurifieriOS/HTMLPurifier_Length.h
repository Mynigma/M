//
//   HTMLPurifier_Length.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 10.01.14.


#import <Foundation/Foundation.h>

@interface HTMLPurifier_Length : NSObject
{

    /**
     * String numeric magnitude.
     * @type string
     */
    NSString* n;

    /**
     * String unit. False is permitted if $n = 0.
     * @type string|bool
     */
    NSString* unit;

    /**
     * Whether or not this length is valid. Null if not calculated yet.
     * @type bool
     */
    NSNumber* isValid;

    /**
     * Array Lookup array of units recognized by CSS 2.1
     * @type array
     */
    NSDictionary* allowedUnits;
}

+ (NSDictionary*)allowedUnits;

- (id)initWithN:(NSString*)newN u:(NSString*)newU;

- (id)initWithN:(NSString*)newN;

- (id)init;

/**
 * @param string $s Unit string, like '2em' or '3.4in'
 * @return HTMLPurifier_Length
 * @warning Does not perform validation.
 */
+ (HTMLPurifier_Length*)makeWithS:(NSObject*)s;

/**
 * Validates the number and unit.
 * @return bool
 */
- (BOOL)validate;

/**
 * Returns string representation of number.
 * @return string
 */
- (NSString*)toString;
/**
 * Retrieves string numeric magnitude.
 * @return string
 */
-(NSString*)getN;

/**
 * Retrieves string unit.
 * @return string
 */
-(NSString*)getUnit;
/**
 * Returns true if this length unit is valid.
 * @return bool
 */
- (BOOL)isValid;


- (NSNumber*)compareTo:(HTMLPurifier_Length*)l;


@end
