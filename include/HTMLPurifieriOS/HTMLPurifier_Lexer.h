//
//   HTMLPurifier_Lexer.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Config, HTMLPurifier_Context, HTMLPurifier_EntityParser;

@interface HTMLPurifier_Lexer : NSObject
{

    /**
     * Whether or not this lexer implements line-number/column-number tracking.
     * If it does, set to true.
     */
    BOOL tracksLineNumbers;

    HTMLPurifier_EntityParser* _entity_parser;

    NSDictionary* _special_entity2str;
}
    // -- STATIC ----------------------------------------------------------

    /**
     * Retrieves or sets the default Lexer as a Prototype Factory.
     *
     * By default HTMLPurifier_Lexer_DOMLex will be returned. There are
     * a few exceptions involving special features that only DirectLex
     * implements.
     *
     * @note The behavior of this class has changed, rather than accepting
     *       a prototype object, it now accepts a configuration object.
     *       To specify your own prototype, set %Core.LexerImpl to it.
     *       This change in behavior de-singletonizes the lexer object.
     *
     * @param HTMLPurifier_Config $config
     * @return HTMLPurifier_Lexer
     * @throws HTMLPurifier_Exception
     */

+ (HTMLPurifier_Lexer*)createWithConfig:(HTMLPurifier_Config*)config;

    // -- CONVENIENCE MEMBERS ---------------------------------------------

- (id)init;

/**
 * Parses special entities into the proper characters.
 *
 * This string will translate escaped versions of the special characters
 * into the correct ones.
 *
 * @warning
 * You should be able to treat the output of this function as
 * completely parsed, but that's only because all other entities should
 * have been handled previously in substituteNonSpecialEntities()
 *
 * @param string $string String character data to be parsed.
 * @return string Parsed character data.
 */
- (NSString*)parseDataWithString:(NSString*)string;

/**
 * Lexes an HTML string into tokens.
 * @param $string String HTML.
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return HTMLPurifier_Token[] array representation of HTML.
 */
- (NSArray*)tokenizeHTMLWithString:(NSString*)string config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * Translates CDATA sections into regular sections (through escaping).
 * @param string $string HTML string to process.
 * @return string HTML with CDATA sections escaped.
 */
- (NSString*)escapeCDATAWithString:(NSString*)string;

/**
 * Special CDATA case that is especially convoluted for <script>
 * @param string $string HTML string to process.
 * @return string HTML with CDATA sections escaped.
 */
- (NSString*)escapeCommentedCDATAWithString:(NSString*)string;

/**
 * Special Internet Explorer conditional comments should be removed.
 * @param string $string HTML string to process.
 * @return string HTML with conditional comments removed.
 */
- (NSString*)removeIEConditionalWithString:string;

/**
 * Callback function for escapeCDATA() that does the work.
 *
 * @warning Though this is public in order to let the callback happen,
 *          calling it directly is not recommended.
 * @param array $matches PCRE matches array, with index 0 the entire match
 *                  and 1 the inside of the CDATA section.
 * @return string Escaped internals of the CDATA section.
 */
+ (NSString*) CDATACallback:(NSArray*)matches;

/**
 * Takes a piece of HTML and normalizes it by converting entities, fixing
 * encoding, extracting bits, and other good stuff.
 * @param string $html HTML.
 * @param HTMLPurifier_Config $config
 * @param HTMLPurifier_Context $context
 * @return string
 * @todo Consider making protected
 */
- (NSString*)normalizeWithHtml:(NSString*)html config:(HTMLPurifier_Config*)config context:(HTMLPurifier_Context*)context;

/**
 * Takes a string of HTML (fragment or document) and returns the content
 * @todo Consider making protected
 */
- (NSString*)extractBodyWithHtml:html;



@end
