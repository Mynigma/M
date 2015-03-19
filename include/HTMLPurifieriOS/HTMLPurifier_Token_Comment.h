//
//   HTMLPurifier_Token_Comment.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import "HTMLPurifier_Token.h"

@class HTMLPurifier_Node_Comment;

/**
 * Concrete comment token class. Generally will be ignored.
 */
@interface HTMLPurifier_Token_Comment : HTMLPurifier_Token


    /**
     * Character data within comment.
     * @type string
     */
@property NSString* data;

    /**
     * @type bool
     */
@property BOOL is_whitespace;

    /**
     * Transparent constructor.
     *
     * @param string $data String comment data.
     * @param int $line
     * @param int $col
     */
- (id)initWithData:(NSString*)d line:(NSNumber*)l col:(NSNumber*)c;

- (id)initWithData:(NSString*)d;

- (HTMLPurifier_Node_Comment*)toNode;

@end
