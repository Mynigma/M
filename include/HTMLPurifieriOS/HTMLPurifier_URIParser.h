//
//   HTMLPurifier_URIParser.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_URI, HTMLPurifier_PercentEncoder;

/**
 * Parses a URI into the components and fragment identifier as specified
 * by RFC 3986.
 */
@interface HTMLPurifier_URIParser : NSObject
{
    /**
     * Instance of HTMLPurifier_PercentEncoder to do normalization with.
     */
    HTMLPurifier_PercentEncoder* percentEncoder;
}

    /**
     * Parses a URI.
     * @param $uri string URI to parse
     * @return HTMLPurifier_URI representation of URI. This representation has
     *         not been validated yet and may not conform to RFC.
     */
- (HTMLPurifier_URI*)parse:(NSString*)uri;


@end
