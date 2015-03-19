//
//   HTMLPurifier_AttrDef.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 10.01.14.


#import <Foundation/Foundation.h>
#import "HTMLPurifier_Config.h"
#import "HTMLPurifier_Context.h"

@interface HTMLPurifier_AttrDef : NSObject

/**
 * Tells us whether or not an HTML attribute is minimized.
 * Has no meaning in other contexts.
 * @type bool
 */
@property BOOL minimized;

/**
 * Tells us whether or not an HTML attribute is required.
 * Has no meaning in other contexts
 * @type bool
 */
@property BOOL required;

- (NSString*)mungeRgbWithString:(NSString*)string;


/**
 * Validates and cleans passed string according to a definition.
 *
 * @param string $string String to be validated and cleaned.
 * @param HTMLPurifier_Config $config Mandatory HTMLPurifier_Config object.
 * @param HTMLPurifier_Context $context Mandatory HTMLPurifier_Context object.
 */
- (NSString*) validateWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * Convenience method that parses a string as if it were CDATA.
 *
 * This method process a string in the manner specified at
 * <http://www.w3.org/TR/html4/types.html#h-6.2> by removing
 * leading and trailing whitespace, ignoring line feeds, and replacing
 * carriage returns and tabs with spaces.  While most useful for HTML
 * attributes specified as CDATA, it can also be applied to most CSS
 * values.
 *
 * @note This method is not entirely standards compliant, as trim() removes
 *       more types of whitespace than specified in the spec. In practice,
 *       this is rarely a problem, as those extra characters usually have
 *       already been removed by HTMLPurifier_Encoder.
 *
 * @warning This processing is inconsistent with XML's whitespace handling
 *          as specified by section 3.3.3 and referenced XHTML 1.0 section
 *          4.7.  However, note that we are NOT necessarily
 *          parsing XML, thus, this behavior may still be correct. We
 *          assume that newlines have been normalized.
 */
- (NSString*)parseCDATAWithString:(NSString*)string;
/**
 * Factory method for creating this class from a string.
 * @param string $string String construction info
 * @return HTMLPurifier_AttrDef Created AttrDef object corresponding to $string
 */
- (HTMLPurifier_AttrDef*)initWithString:(NSString*)string;

- (HTMLPurifier_AttrDef*)make:(NSString*)string;

/**
 * Parses a possibly escaped CSS string and returns the "pure"
 * version of it.
 */
- (NSString*)expandCSSEscapeWithString:(NSString*)string;

- (id)copyWithZone:(NSZone *)zone;


@end
