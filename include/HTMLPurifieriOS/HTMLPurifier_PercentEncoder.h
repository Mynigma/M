//
//   HTMLPurifier_PercentEncoder.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import <Foundation/Foundation.h>

/**
 * Class that handles operations involving percent-encoding in URIs.
 *
 * @warning
 *      Be careful when reusing instances of PercentEncoder. The object
 *      you use for normalize() SHOULD NOT be used for encode(), or
 *      vice-versa.
 */
@interface HTMLPurifier_PercentEncoder : NSObject
{
    /**
     * Reserved characters to preserve when using encode().
     * @type array
     */
    NSCharacterSet* preservedChars;
}

- (id)initWithPreservedChars:(NSString*)preservedChars;


- (NSString*)encode:(NSString*)string;
/**
 * Fix up percent-encoding by decoding unreserved characters and normalizing.
 * @warning This function is affected by $preserve, even though the
 *          usual desired behavior is for this not to preserve those
 *          characters. Be careful when reusing instances of PercentEncoder!
 * @param string $string String to normalize
 * @return string
 */
- (NSString*)normalize:(NSString*)string;

@end
