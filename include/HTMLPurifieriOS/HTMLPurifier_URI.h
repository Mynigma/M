//
//   HTMLPurifier_URI.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config , HTMLPurifier_Context,HTMLPurifier_URIScheme;

@interface HTMLPurifier_URI : NSObject

- (id)initWithScheme:(NSString*)scheme userinfo:(NSString*)userinfo host:(NSString*)host port:(NSNumber*)port path:(NSString*)path query:(NSString*)query fragment:(NSString*)fragment;

/**
 * @type string
 */
@property NSString* scheme;

/**
 * @type string
 */
@property NSString* userinfo;

/**
 * @type string
 */
@property NSString* host;

/**
 * @type int
 */
@property NSNumber* port;

/**
 * @type string
 */
@property NSString* path;

/**
 * @type string
 */
@property NSString* query;

/**
 * @type string
 */
@property NSString* fragment;

-(HTMLPurifier_URIScheme*) getSchemeObj:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(BOOL) validateWithConfig:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(BOOL) isBenign:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(BOOL) isLocal:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(NSString*) toString;

- (id)copyWithZone:(NSZone *)zone;


@end
