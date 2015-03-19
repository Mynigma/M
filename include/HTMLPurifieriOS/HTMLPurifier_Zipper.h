//
//   HTMLPurifier_Zipper.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 13.01.14.


/**
 * A zipper is a purely-functional data structure which contains
 * a focus that can be efficiently manipulated.  It is known as
 * a "one-hole context".  This mutable variant implements a zipper
 * for a list as a pair of two arrays, laid out as follows:
 *
 *      Base list: 1 2 3 4 [ ] 6 7 8 9
 *      Front list: 1 2 3 4
 *      Back list: 9 8 7 6
 *
 * User is expected to keep track of the "current element" and properly
 * fill it back in as necessary.  (ToDo: Maybe it's more user friendly
 * to implicitly track the current element?)
 *
 * Nota bene: the current class gets confused if you try to store NULLs
 * in the list.
 */
@interface HTMLPurifier_Zipper : NSObject 



@property NSMutableArray* front;
@property NSMutableArray* back;


- (id)initWithFront:(NSArray*)newFront back:(NSArray*)newBack;
/**
 * Creates a zipper from an array, with a hole in the
 * 0-index position.
 * @param Array to zipper-ify.
 * @return Tuple of zipper and element of first position.
 */
+ (NSArray*)fromArray:(NSArray*)array;

/**
 * Convert zipper back into a normal array, optionally filling in
 * the hole with a value. (Usually you should supply a $t, unless you
 * are at the end of the array.)
 */
- (NSArray*)toArray:(NSObject*)t;

/**
 * Move hole to the next element.
 * @param $t Element to fill hole with
 * @return Original contents of new hole.
 */
- (NSObject*)next:(NSObject*)t;

/**
 * Iterated hole advancement.
 * @param $t Element to fill hole with
 * @param $i How many forward to advance hole
 * @return Original contents of new hole, i away
 */
- (NSObject*) advance:(NSObject*)t by:(NSInteger)n;

/**
 * Move hole to the previous element
 * @param $t Element to fill hole with
 * @return Original contents of new hole.
 */
- (NSObject*)prev:(NSObject*)t;

/**
 * Delete contents of current hole, shifting hole to
 * next element.
 * @return Original contents of new hole.
 */
- (NSObject*)delete;

/**
 * Returns true if we are at the end of the list.
 * @return bool
 */
- (BOOL)done;
/**
 * Insert element before hole.
 * @param Element to insert
 */
- (void)insertBefore:(NSObject*)t;

/**
 * Insert element after hole.
 * @param Element to insert
 */
- (void)insertAfter:(NSObject*)t;

/**
 * Splice in multiple elements at hole.  Functional specification
 * in terms of array_splice:
 *
 *      $arr1 = $arr;
 *      $old1 = array_splice($arr1, $i, $delete, $replacement);
 *
 *      list($z, $t) = HTMLPurifier_Zipper::fromArray($arr);
 *      $t = $z->advance($t, $i);
 *      list($old2, $t) = $z->splice($t, $delete, $replacement);
 *      $arr2 = $z->toArray($t);
 *
 *      assert($old1 === $old2);
 *      assert($arr1 === $arr2);
 *
 * NB: the absolute index location after this operation is
 * *unchanged!*
 *
 * @param Current contents of hole.
 */
- (NSObject*)splice:(NSObject*)t delete:(NSInteger)delete replacement:(NSArray*)replacement;


@end
