//
//   HTMLPurifier_Token_End.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import "HTMLPurifier_Token_Tag.h"

/**
 * Concrete end token class.
 *
 * @warning This class accepts attributes even though end tags cannot. This
 * is for optimization reasons, as under normal circumstances, the Lexers
 * do not pass attributes.
 */
@interface HTMLPurifier_Token_End : HTMLPurifier_Token_Tag


    /**
     * Token that started this node.
     * Added by MakeWellFormed. Please do not edit this!
     * @type HTMLPurifier_Token
     */
@property HTMLPurifier_Token* start;

- (HTMLPurifier_Node*)toNode;


@end
