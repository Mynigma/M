//
//  BasicPHP.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 10.01.14.


#import <Foundation/Foundation.h>

//use NSLog instead of do_nothing to turn on logs
#define TRIGGER_ERROR do_nothing

#ifndef BASIC_PHP

void do_nothing();

NSString* preg_replace_3(NSString* pattern, NSString* replacement, NSString* subject);
//TODO
NSArray* preg_split_2(NSString* expression, NSString* subject);

// Limit: max limit elements in returned array
NSArray* preg_split_3(NSString* expression, NSString* subject, NSInteger limit);

/* *** Instead directly with FLAG ***
NSArray* preg_split_4(NSString* expression, NSString* subject, NSInteger limit, NSInteger* flag)
{
    
    if (flag == 0)
        return preg_split_3(expression,subject,limit);
    
    NSRegularExpression *exp = [NSRegularExpression regularExpressionWithPattern:expression options:0 error:nil];
    
    NSArray *matches = [exp matchesInString:subject options:0 range:NSMakeRange(0, [subject length])];
    
    NSMutableArray *results = [NSMutableArray new];
    
    if ([matches count] == 0)
    {
        [results addObject:subject];
        return results;
    }
    
    //start @beginning
    NSInteger loc = 0;
    
    for (NSTextCheckingResult *match in matches) {
        
        // we only want #limit-elements
        if ([results count] >= limit - 1)
            break;
        
        //range of the match
        NSRange match_range = [match range];
        
        //lenght from loc to this match
        NSInteger len = match_range.location - loc;
        
        // make range
        NSRange range = NSMakeRange(loc, len);
        //add string, even if empty
        [results addObject:[subject substringWithRange:range]];
        // set the new loc
        loc = match_range.location + match_range.length;
    }
    
    // get the last straw
    if (loc < [subject length])
    {
        [results addObject:[subject substringWithRange:NSMakeRange(loc, [subject length]-loc)]];
    }
    
    return results;
}
*/

NSArray* preg_split_2_PREG_SPLIT_DELIM_CAPTURE(NSString* expression, NSString* subject);

NSArray* preg_split_3_PREG_SPLIT_DELIM_CAPTURE(NSString* expression, NSString* subject, NSInteger limit);

BOOL preg_match_2(NSString* pattern, NSString* subject);

BOOL preg_match_2_WithLineBreak(NSString* pattern, NSString* subject);


//Returns all matches & subpattern matches
// Structure is array of arrays
BOOL preg_match_all_3(NSString* pattern, NSString* subject, NSMutableArray* matches);

BOOL preg_match_3(NSString* pattern, NSString* subject, NSMutableArray* matches);

BOOL preg_match_3_withLineBreak(NSString* pattern, NSString* subject, NSMutableArray* matches);


NSInteger preg_match_all_2(NSString* pattern, NSString* subject);

BOOL ctype_xdigit (NSString* text);

BOOL ctype_digit (NSString* text);

NSString* decodeXMLEntities(NSString* string);

BOOL ctype_lower (NSString* text);
BOOL ctype_alnum(NSString* string);

BOOL stringIsNumeric(NSString *str);

BOOL is_numeric(NSString* string);
NSString* trim(NSString* string);

//trim with Format like 'A..Za..z0..9:-._' some kind of regex
// TODO
NSString* trimWithFormat(NSString* string, NSString* format);
NSString* trimCharacters(NSString* string, NSCharacterSet* characters);

NSString* htmlspecialchars(NSString* string);
NSString* htmlspecialchars_ENT_COMPAT(NSString* string);
NSString* htmlspecialchars_ENT_NOQUOTES(NSString* string);

BOOL ctype_alpha (NSString* text);
BOOL ctype_space(NSString* string);
NSObject* str_replace(NSObject* search, NSObject* replace, NSString* subject);

NSInteger php_strspn(NSString* string, NSString* characterList);

NSInteger strpos(NSString* haystack, NSString* needle);

//Backwardssearch
NSInteger strrpos(NSString* haystack, NSString* needle);

NSString* substr(NSString* string, NSInteger start);


NSInteger substr_count(NSString* haystack , NSString* needle);

//does not work properly if there is overlap between substituted strings and strings to be replaced
NSString* strtr_php(NSString* fromString, NSDictionary* replacementDict);

NSInteger strspn_2(NSString* subject, NSString* mask);

// Find length of initial segment not matching mask
// TODO
NSInteger strcspn_2(NSString* string1, NSString* string2);
NSInteger strcspn_3(NSString* string1, NSString* string2, NSInteger start);

NSInteger hexdec(NSString* hex_string);
NSString* dechex(NSString* hex_string);
NSString* lowercase_dechex(NSData* dec_data);


NSString* ltrim_whitespaces(NSString* string);
NSString* rtrim_whitespaces(NSString* string);
NSString* ltrim_2(NSString* string, NSString* characterSetString);
NSString* rtrim(NSString* string);


NSString* rtrim_2(NSString* string, NSString* characterSetString);
NSString* implode(NSString* glue, NSArray* pieces);

NSArray* explode(NSString* limitString, NSString* string);
NSArray* explodeWithLimit(NSString* delimiter, NSString* string, NSInteger limit);

NSMutableArray* array_slice_2(NSArray* array, NSInteger offset);

NSMutableArray* array_slice_3(NSArray* array, NSInteger offset, NSInteger length);
NSInteger array_unshift_2(NSMutableArray* array, NSObject* object);
NSObject* array_shift(NSMutableArray* array);

NSMutableArray* array_reverse(NSArray* oldArray);

NSObject* array_pop(NSMutableArray* array);

void array_push(NSMutableArray* array, NSObject* x);

//TODO array_map_i
//Call back should be a function callback
NSArray* array_map_2(NSString* callback,NSArray* arrayWithInput);
//Call back should be a function callback
NSArray* array_map_3(NSString* callback,NSArray* arrayWithInput, NSArray* arrayWithArgs);

//array_merge can be used with morge input arrays ad needed.
NSArray* array_merge_2(NSArray* array1, NSArray* array2);
//PHP array_merge also works as "dictionary_merge"
NSDictionary* dict_merge_2(NSDictionary* dict1, NSDictionary* dict2);

NSArray* array_splice_4 (NSArray* input, NSInteger offset, NSInteger length, NSArray* replacement);

NSData* base64_decode(NSString* base64String);

NSString* base64_encode(NSString* plainString);

NSData* hash_hmac(NSString* algo, NSString* data, NSString* key);

#define BASIC_PHP 1

#endif


@interface BasicPHP : NSObject

+ (NSString*)trimWithString:(NSString*)string;

+ (NSString*)strReplaceWithSearch:(NSString*)search replace:(NSString*)replace subject:(NSString*)subject;

+ (NSString*)pregReplaceWithPattern:(NSString*)pattern replacement:(NSString*)replacement subject:(NSString*)subject;

+ (NSString*)pregReplace:(NSString*)pattern callback:(NSString*(^)(NSArray*))callBack haystack:(NSString*)haystack;


@end
