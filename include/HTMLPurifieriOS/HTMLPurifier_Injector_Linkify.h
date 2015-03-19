//
//   HTMLPurifier_Injector_Linkify.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import "HTMLPurifier_Injector.h"

@class HTMLPurifier_Token;

/**
 * Injector that converts http, https and ftp text URLs to actual links.
 */
@interface HTMLPurifier_Injector_Linkify : HTMLPurifier_Injector

    /**
     * @type string
     */
//inherited
    /**
     * @type array
     */
//inherited
    /**
     * @param HTMLPurifier_Token $token
     */
- (void)handleText:(HTMLPurifier_Token**)token;

@end
