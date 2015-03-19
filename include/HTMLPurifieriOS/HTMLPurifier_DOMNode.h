//
//   HTMLPurifier_DOMNode.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 17.01.14.


#import <Foundation/Foundation.h>

@interface HTMLPurifier_DOMNode : NSObject

@property NSInteger type;

@property NSString* name;

@property NSString* content;

@property NSDictionary* attr;

@property NSArray* sortedAttrKeys;

@property NSArray* children;

@end
