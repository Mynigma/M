//
//   HTMLPurifier_AttrTypes.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 19.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_AttrDef;

@interface HTMLPurifier_AttrTypes : NSObject
{
    /**
     * Provides lookup array of attribute types to HTMLPurifier_AttrDef objects
     */
    NSMutableDictionary* info;
}


- (HTMLPurifier_AttrDef*)get:(NSString*)type;


@end
