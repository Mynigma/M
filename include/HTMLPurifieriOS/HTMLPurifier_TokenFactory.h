//
//   HTMLPurifier_TokenFactory.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 12.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_Token_Start, HTMLPurifier_Token_End, HTMLPurifier_Token_Empty, HTMLPurifier_Token_Text, HTMLPurifier_Token_Comment;

/**
 * Factory for token generation.
 *
 * @note Doing some benchmarking indicates that the new operator is much
 *       slower than the clone operator (even discounting the cost of the
 *       constructor).  This class is for that optimization.
 *       Other then that, there's not much point as we don't
 *       maintain parallel HTMLPurifier_Token hierarchies (the main reason why
 *       you'd want to use an abstract factory).
 * @todo Port DirectLex to use this
 */
@interface HTMLPurifier_TokenFactory : NSObject

    // p stands for prototype

    /**
     * @type HTMLPurifier_Token_Start
     */
@property HTMLPurifier_Token_Start* p_start;

    /**
     * @type HTMLPurifier_Token_End
     */
@property HTMLPurifier_Token_End* p_end;

    /**
     * @type HTMLPurifier_Token_Empty
     */
@property HTMLPurifier_Token_Empty* p_empty;

    /**
     * @type HTMLPurifier_Token_Text
     */
@property HTMLPurifier_Token_Text* p_text;

    /**
     * @type HTMLPurifier_Token_Comment
     */
@property HTMLPurifier_Token_Comment* p_comment;

/**
 * Creates a HTMLPurifier_Token_Start.
 * @param string $name Tag name
 * @param array $attr Associative array of attributes
 * @return HTMLPurifier_Token_Start Generated HTMLPurifier_Token_Start
 */
- (HTMLPurifier_Token_Start*)createStartWithName:(NSString*)name attr:(NSMutableDictionary*)att sortedAttrKeys:(NSArray*)sortedAttrKeys;

/**
 * Creates a HTMLPurifier_Token_End.
 * @param string $name Tag name
 * @return HTMLPurifier_Token_End Generated HTMLPurifier_Token_End
 */
- (HTMLPurifier_Token_End*)createEndWithName:(NSString*)name;

/**
 * Creates a HTMLPurifier_Token_Empty.
 * @param string $name Tag name
 * @param array $attr Associative array of attributes
 * @return HTMLPurifier_Token_Empty Generated HTMLPurifier_Token_Empty
 */
- (HTMLPurifier_Token_Empty*)createEmptyWithName:(NSString*)name attr:(NSDictionary*)attr sortedAttrKeys:(NSArray*)sortedAttrKeys;

/**
 * Creates a HTMLPurifier_Token_Text.
 * @param string $data Data of text token
 * @return HTMLPurifier_Token_Text Generated HTMLPurifier_Token_Text
 */
- (HTMLPurifier_Token_Text*)createTextWithData:(NSString*)data;

/**
 * Creates a HTMLPurifier_Token_Comment.
 * @param string $data Data of comment token
 * @return HTMLPurifier_Token_Comment Generated HTMLPurifier_Token_Comment
 */
- (HTMLPurifier_Token_Comment*)createCommentWithData:(NSString*)data;


@end
