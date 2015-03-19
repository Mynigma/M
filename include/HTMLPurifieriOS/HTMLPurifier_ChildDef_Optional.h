//
//   HTMLPurifier_ChidDef_Optional.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 18.01.14.


#import "HTMLPurifier_ChildDef_Required.h"


/**
 * Definition that allows a set of elements, and allows no children.
 * @note This is a hack to reuse code from HTMLPurifier_ChildDef_Required,
 *       really, one shouldn't inherit from the other.  Only altered behavior
 *       is to overload a returned false with an array.  Thus, it will never
 *       return false.
 */
@interface HTMLPurifier_ChildDef_Optional : HTMLPurifier_ChildDef_Required


   /**
     * @type bool
     */
@property BOOL allow_empty;

    /**
     * @type string
     */
//@property NSString* typeString = 'optional';

    /**
     * @param array $children
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return array
     */
- (NSObject*)validateChildren:(NSArray *)children config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;

- (id)initWithElements:(NSObject*)newElements;


@end
