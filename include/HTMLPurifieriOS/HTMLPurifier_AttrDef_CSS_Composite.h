//
//   HTMLPurifier_AttrDef_CSS_Composite.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 10.01.14.


#import "HTMLPurifier_AttrDef.h"

@interface HTMLPurifier_AttrDef_CSS_Composite : HTMLPurifier_AttrDef


    /**
     * List of objects that may process strings.
     * @type HTMLPurifier_AttrDef[]
     * @todo Make protected
     */
@property NSMutableArray* defs;

- (id)initWithDefs:(NSArray*)newDefs;


@end
