//
//   HTMLPurifier_VarParser.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


#import <Foundation/Foundation.h>

#define V_STRING @1
#define V_ISTRING @2
#define V_TEXT @3
#define V_ITEXT @4
#define V_INT @5
#define V_FLOAT @6
#define V_BOOL @7
#define V_LOOKUP @8
#define V_ALIST @9
#define V_HASH @10
#define V_MIXED @11

/**
 * Parses string representations into their corresponding native PHP
 * variable type. The base implementation does a simple type-check.
 */
@interface HTMLPurifier_VarParser : NSObject

- (id)init;

/**
 * Validate a variable according to type.
 * It may return NULL as a valid type if $allow_null is true.
 *
 * @param mixed $var Variable to validate
 * @param int $type Type of variable, see HTMLPurifier_VarParser->types
 * @param bool $allow_null Whether or not to permit null as a value
 * @return string Validated and type-coerced variable
 * @throws HTMLPurifier_VarParserException
 */
- (NSString*)parse:(NSObject*)var type:(NSNumber*)type;

- (NSString*)parse:(NSObject*)var type:(NSNumber*)type allowNull:(BOOL)allow_null;

/**
 * Actually implements the parsing. Base implementation does not
 * do anything to $var. Subclasses should overload this!
 * @param mixed $var
 * @param int $type
 * @param bool $allow_null
 * @return string
 */
- (NSString*)parseImplementation:(NSObject*)var type:(NSNumber*)type allowNull:(BOOL)allow_null;

/**
 * Throws an exception.
 * @throws HTMLPurifier_VarParserException
 */
- (void)error:(NSString*)msg;

/**
 * Throws an inconsistency exception.
 * @note This should not ever be called. It would be called if we
 *       extend the allowed values of HTMLPurifier_VarParser without
 *       updating subclasses.
 * @param string $class
 * @param int $type
 * @throws HTMLPurifier_Exception
 */
- (void)errorInconsistent:(NSObject*)classDesc type:(NSNumber*)type;

/**
 * Generic error for if a type didn't work.
 * @param mixed $var
 * @param int $type
 */
- (void)errorGeneric:(NSObject*)var type:(NSNumber*)type;

+ (NSDictionary*)types;

+ (NSDictionary*)stringTypes;

+ (NSDictionary*)lookup;
/**
 * @param int $type
 * @return string
 */
+ (NSString*)getTypeName:(NSNumber*)type;






@end
