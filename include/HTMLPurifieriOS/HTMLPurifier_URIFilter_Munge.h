//
//   HTMLPurifier_URIFilter_Munge.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 19.01.14.


#import "HTMLPurifier_URIFilter.h"

@class HTMLPurifier_URIParser;

@interface HTMLPurifier_URIFilter_Munge : HTMLPurifier_URIFilter

/**
 * @type string
 */
@property NSString* target;

/**
 * @type HTMLPurifier_URIParser
 */
@property HTMLPurifier_URIParser* parser;

/**
 * @type bool
 */
@property BOOL doEmbed;

/**
 * @type string
 */
@property NSString* secretKey;

/**
 * @type array
 */
@property NSMutableDictionary* replace;

/**
 * @param HTMLPurifier_Config $config
 * @return bool
 */
-(BOOL) prepare:(HTMLPurifier_Config*)config;

-(BOOL) filter:(HTMLPurifier_URI**)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

-(void) makeReplace:(HTMLPurifier_URI*)uri config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

@end
