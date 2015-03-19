//
//   HTMLPurifier_Node.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import <Foundation/Foundation.h>

/**
 * Abstract base node class that all others inherit from.
 *
 * Why do we not use the DOM extension?  (1) It is not always available,
 * (2) it has funny constraints on the data it can represent,
 * whereas we want a maximally flexible representation, and (3) its
 * interface is a bit cumbersome.
 */
@interface HTMLPurifier_Node : NSObject


@property NSString* name;


@property NSMutableArray* children;


@property BOOL empty;



@property BOOL isWhitespace;
    /**
     * Line number of the start token in the source document
     * @type int
     */
@property NSNumber* line;

    /**
     * Column number of the start token in the source document. Null if unknown.
     * @type int
     */
@property NSNumber* col;

    /**
     * Lookup array of processing that this token is exempt from.
     * Currently, valid values are "ValidateAttributes".
     * @type array
     */
@property NSMutableDictionary* armor;

    /**
     * When true, this node should be ignored as non-existent.
     *
     * Who is responsible for ignoring dead nodes?  FixNesting is
     * responsible for removing them before passing on to child
     * validators.
     */
@property BOOL dead;

    /**
     * Returns a pair of start and end tokens, where the end token
     * is null if it is not necessary. Does not include children.
     * @type array
     */
- (NSArray*)toTokenPair;



@end
