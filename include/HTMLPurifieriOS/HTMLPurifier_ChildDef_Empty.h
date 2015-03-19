//
//   HTMLPurifier_ChildDef_Empty.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 19.01.14.


#import "HTMLPurifier_ChildDef.h"

@class HTMLPurifier_Context, HTMLPurifier_Config;


/**
 * Definition that disallows all elements.
 * @warning validateChildren() in this class is actually never called, because
 *          empty elements are corrected in HTMLPurifier_Strategy_MakeWellFormed
 *          before child definitions are parsed in earnest by
 *          HTMLPurifier_Strategy_FixNesting.
 */
@interface HTMLPurifier_ChildDef_Empty : HTMLPurifier_ChildDef

    /**
     * @type bool
     */
@property BOOL allow_empty;

    /**
     * @type string
     */
@property NSString* typeString;


    /**
     * @param HTMLPurifier_Node[] $children
     * @param HTMLPurifier_Config $config
     * @param HTMLPurifier_Context $context
     * @return array
     */
- (NSArray*)validateChildren:(NSArray*)children config:(HTMLPurifier_Config *)config context:(HTMLPurifier_Context *)context;


@end
