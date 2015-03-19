//
//   HTMLPurifier_URIDefinition.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 13.01.14.


#import "HTMLPurifier_Definition.h"

@class HTMLPurifier_URI,HTMLPurifier_URIFilter,HTMLPurifier_Context,HTMLPurifier_URIScheme;

@interface HTMLPurifier_URIDefinition : HTMLPurifier_Definition


@property NSString* typeString;

@property NSMutableDictionary* filters;

@property NSMutableDictionary* postFilters;

@property NSMutableDictionary* registeredFilters;

/**
 * HTMLPurifier_URI object of the base specified at %URI.Base
 */
@property HTMLPurifier_URI* base;

/**
 * String host to consider "home" base, derived off of $base
 */
@property NSString* host;

/**
 * Name of default scheme based on %URI.DefaultScheme and %URI.Base
 */
@property NSString* defaultScheme;

-(void) registerFilter:(HTMLPurifier_URIFilter*) filter;

-(void) addFilter:(HTMLPurifier_URIFilter*)filter config:(HTMLPurifier_Config*)config;

-(void) doSetup:(HTMLPurifier_Config*)config;

-(void) setupFilters:(HTMLPurifier_Config*)config;

-(void) setupMemberVariables:(HTMLPurifier_Config*)config;

-(HTMLPurifier_URIScheme*) getDefaultScheme:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(BOOL) postFilter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;



@end
