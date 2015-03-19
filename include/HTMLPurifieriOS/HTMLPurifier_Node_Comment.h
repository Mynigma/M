//
//   HTMLPurifier_Node_Comment.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import "HTMLPurifier_Node.h"

/**
 * Concrete comment node class.
 */
@interface HTMLPurifier_Node_Comment : HTMLPurifier_Node


    /**
     * Character data within comment.
     * @type string
     */
@property NSString* data;


- (id)initWithData:(NSString*)d line:(NSNumber*)l col:(NSNumber*)c;


@end
