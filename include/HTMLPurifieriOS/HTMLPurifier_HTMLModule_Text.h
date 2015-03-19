//
//   HTMLPurifier_HTMLModule_Text.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 19.01.14.


#import "HTMLPurifier_HTMLModule.h"

/**
 * XHTML 1.1 Text Module, defines basic text containers. Core Module.
 * @note In the normative XML Schema specification, this module
 *       is further abstracted into the following modules:
 *          - Block Phrasal (address, blockquote, pre, h1, h2, h3, h4, h5, h6)
 *          - Block Structural (div, p)
 *          - Inline Phrasal (abbr, acronym, cite, code, dfn, em, kbd, q, samp, strong, var)
 *          - Inline Structural (br, span)
 *       This module, functionally, does not distinguish between these
 *       sub-modules, but the code is internally structured to reflect
 *       these distinctions.
 */
@interface HTMLPurifier_HTMLModule_Text : HTMLPurifier_HTMLModule

    /**
     * @type string
     */
@property NSString* name;

    /**
     * @type array
     */
@property NSMutableDictionary* content_sets;


@end
