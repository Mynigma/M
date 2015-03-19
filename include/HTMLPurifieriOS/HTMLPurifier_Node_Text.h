//
//   HTMLPurifier_Node_Text.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import "HTMLPurifier_Node.h"

/**
 * Concrete text token class.
 *
 * Text tokens comprise of regular parsed character data (PCDATA) and raw
 * character data (from the CDATA sections). Internally, their
 * data is parsed with all entities expanded. Surprisingly, the text token
 * does have a "tag name" called #PCDATA, which is how the DTD represents it
 * in permissible child nodes.
 */
@interface HTMLPurifier_Node_Text : HTMLPurifier_Node

    /**
     * PCDATA tag name compatible with DTD, see
     * HTMLPurifier_ChildDef_Custom for details.
     * @type string
     */

    /**
     * @type string
     */
@property NSString* data;
    /**< Parsed character data of text. */


    /**< Bool indicating if node is whitespace. */

- (id)initWithData:(NSString*)d isWhitespace:(BOOL)isW line:(NSNumber*)l col:(NSNumber*)c;


- (NSArray*)toTokenPair;

@end
