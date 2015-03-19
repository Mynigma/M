//
//   HTMLPurifier_EntityParser.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_EntityLookup;

@interface HTMLPurifier_EntityParser : NSObject
{
    HTMLPurifier_EntityLookup* _entityLookup;

    NSString* _substituteEntitiesRegex;

    NSDictionary* _specialDec2Str;

    NSDictionary* _specialEnt2Dec;
}


//    /**
//     * Reference to entity lookup table.
//     * @type HTMLPurifier_EntityLookup
//     */
//    protected $_entity_lookup;
//
//    /**
//     * Callback regex string for parsing entities.
//     * @type string
//     */
//    protected $_substituteEntitiesRegex =
//    '/&(?:[#]x([a-fA-F0-9]+)|[#]0*(\d+)|([A-Za-z_:][A-Za-z0-9.\-_:]*));?/';
//    //     1. hex             2. dec      3. string (XML style)
//
//    /**
//     * Decimal to parsed string conversion table for special entities.
//     * @type array
//     */
//    protected $_special_dec2str =
//    array(
//          34 => '"',
//          38 => '&',
//          39 => "'",
//          60 => '<',
//          62 => '>'
//          );
//
//    /**
//     * Stripped entity names to decimal conversion table for special entities.
//     * @type array
//     */
//    protected $_special_ent2dec =
//    array(
//          'quot' => 34,
//          'amp'  => 38,
//          'lt'   => 60,
//          'gt'   => 62
//          );
//
//    /**
//     * Substitutes non-special entities with their parsed equivalents. Since
//     * running this whenever you have parsed character is t3h 5uck, we run
//     * it before everything else.
//     *
//     * @param string $string String to have non-special entities parsed.
//     * @return string Parsed string.
//     */
- (NSString*)substituteNonSpecialEntities:(NSString*)string;
//    {
//        // it will try to detect missing semicolons, but don't rely on it
//        return preg_replace_callback(
//                                     $this->_substituteEntitiesRegex,
//                                     array($this, 'nonSpecialEntityCallback'),
//                                     $string
//                                     );
//    }
//
//    /**
//     * Callback function for substituteNonSpecialEntities() that does the work.
//     *
//     * @param array $matches  PCRE matches array, with 0 the entire match, and
//     *                  either index 1, 2 or 3 set with a hex value, dec value,
//     *                  or string (respectively).
//     * @return string Replacement string.
//     */
//
- (NSString*)nonSpecialEntityCallback:(NSArray*)matches;
//
//    /**
//     * Substitutes only special entities with their parsed equivalents.
//     *
//     * @notice We try to avoid calling this function because otherwise, it
//     * would have to be called a lot (for every parsed section).
//     *
//     * @param string $string String to have non-special entities parsed.
//     * @return string Parsed string.
//     */
- (NSString*)substituteSpecialEntities:(NSString*)string;
//
//    /**
//     * Callback function for substituteSpecialEntities() that does the work.
//     *
//     * This callback has same syntax as nonSpecialEntityCallback().
//     *
//     * @param array $matches  PCRE-style matches array, with 0 the entire match, and
//     *                  either index 1, 2 or 3 set with a hex value, dec value,
//     *                  or string (respectively).
//     * @return string Replacement string.
//     */
//    protected function specialEntityCallback($matches)
//    {
//        $entity = $matches[0];
//        $is_num = (@$matches[0][1] === '#');
//        if ($is_num) {
//            $is_hex = (@$entity[2] === 'x');
//            $int = $is_hex ? hexdec($matches[1]) : (int) $matches[2];
//            return isset($this->_special_dec2str[$int]) ?
//            $this->_special_dec2str[$int] :
//            $entity;
//        } else {
//            return isset($this->_special_ent2dec[$matches[3]]) ?
//            $this->_special_ent2dec[$matches[3]] :
//            $entity;
//        }
//    }
//}


@end
