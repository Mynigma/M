//
//   HTMLPurifier_Context.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

@interface HTMLPurifier_Context : NSObject
{
    NSMutableDictionary* _storage;
}

- (void)registerWithName:(NSString*)name ref:(NSObject*)ref;
- (NSObject*)getWithName:(NSString*)name;
- (NSObject*)getWithName:(NSString*)name ignoreError:(BOOL)ignoreError;
- (BOOL)existsWithName:(NSString*)name;
- (void)loadArrayWithContextArray:(NSDictionary*)contextArray;
/**
 * Destroys a variable in the context.
 * @param string $name String name
 */
-(void) destroy:(NSString*)name;

@end
