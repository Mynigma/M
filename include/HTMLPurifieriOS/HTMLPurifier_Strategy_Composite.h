//
//   HTMLPurifier_Strategy_Composite.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import <Foundation/Foundation.h>

#import "HTMLPurifier_Strategy.h"

@interface HTMLPurifier_Strategy_Composite : HTMLPurifier_Strategy
{
    NSMutableArray* strategies;
}

- (NSMutableArray*)execute:(NSMutableArray*)tokens config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;


@end
