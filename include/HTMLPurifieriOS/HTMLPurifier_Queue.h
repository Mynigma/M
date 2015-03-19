//
//   HTMLPurifier_Queue.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import <Foundation/Foundation.h>

/**
 * A simple array-backed queue, based off of the classic Okasaki
 * persistent amortized queue.  The basic idea is to maintain two
 * stacks: an input stack and an output stack.  When the output
 * stack runs out, reverse the input stack and use it as the output
 * stack.
 *
 * We don't use the SPL implementation because it's only supported
 * on PHP 5.3 and later.
 *
 * Exercise: Prove that push/pop on this queue take amortized O(1) time.
 *
 * Exercise: Extend this queue to be a deque, while preserving amortized
 * O(1) time.  Some care must be taken on rebalancing to avoid quadratic
 * behaviour caused by repeatedly shuffling data from the input stack
 * to the output stack and back.
 */
@interface HTMLPurifier_Queue : NSObject
{
    NSMutableArray* input;
    NSMutableArray* output;
}

- (id)initWithInput:(NSArray*)input;

    /**
     * Shifts an element off the front of the queue.
     */
- (NSObject*)shift;
    /**
     * Pushes an element onto the front of the queue.
     */
- (void)push:(NSObject*)x;

    /**
     * Checks if it's empty.
     */
- (BOOL)isEmpty;


@end
