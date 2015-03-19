//
//   HTMLPurifier_CSSDefinition.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 10.01.14.


#import "HTMLPurifier_Definition.h"

@class HTMLPurifier_Config;

@interface HTMLPurifier_CSSDefinition : HTMLPurifier_Definition

@property NSString* typeString;
@property NSMutableDictionary* info;

- (void)doSetup:(HTMLPurifier_Config*)config;

- (void)setupConfigStuff:(HTMLPurifier_Config*)config;


@end
