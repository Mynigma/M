//
//   HTMLPurifier_Strategy_FixNesting.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import "HTMLPurifier_Strategy.h"


/**
 * Takes a well formed list of tokens and fixes their nesting.
 *
 * HTML elements dictate which elements are allowed to be their children,
 * for example, you can't have a p tag in a span tag.  Other elements have
 * much more rigorous definitions: tables, for instance, require a specific
 * order for their elements.  There are also constraints not expressible by
 * document type definitions, such as the chameleon nature of ins/del
 * tags and global child exclusions.
 *
 * The first major objective of this strategy is to iterate through all
 * the nodes and determine whether or not their children conform to the
 * element's definition.  If they do not, the child definition may
 * optionally supply an amended list of elements that is valid or
 * require that the entire node be deleted (and the previous node
 * rescanned).
 *
 * The second objective is to ensure that explicitly excluded elements of
 * an element do not appear in its children.  Code that accomplishes this
 * task is pervasive through the strategy, though the two are distinct tasks
 * and could, theoretically, be seperated (although it's not recommended).
 *
 * @note Whether or not unrecognized children are silently dropped or
 *       translated into text depends on the child definitions.
 *
 * @todo Enable nodes to be bubbled out of the structure.  This is
 *       easier with our new algorithm.
 */
@interface HTMLPurifier_Strategy_FixNesting : HTMLPurifier_Strategy

    /**
     * @param HTMLPurifier_Token[] $tokens
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return array|HTMLPurifier_Token[]
     */
- (NSMutableArray*)execute:(NSMutableArray*)tokens config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
