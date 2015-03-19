//
//   HTMLPurifier_Doctype.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 14.01.14.


#import <Foundation/Foundation.h>

/**
 * Represents a document type, contains information on which modules
 * need to be loaded.
 * @note This class is inspected by Printer_HTMLDefinition->renderDoctype.
 *       If structure changes, please update that function.
 */
@interface HTMLPurifier_Doctype : NSObject

    /**
     * Full name of doctype
     * @type string
     */
@property NSString* name;

    /**
     * List of standard modules (string identifiers or literal objects)
     * that this doctype uses
     * @type array
     */
@property NSMutableArray* modules;

    /**
     * List of modules to use for tidying up code
     * @type array
     */
@property NSMutableArray* tidyModules;

    /**
     * Is the language derived from XML (i.e. XHTML)?
     * @type bool
     */
@property BOOL xml;

    /**
     * List of aliases for this doctype
     * @type array
     */
@property NSMutableArray* aliases;

    /**
     * Public DTD identifier
     * @type string
     */
@property NSString* dtdPublic;

    /**
     * System DTD identifier
     * @type string
     */
@property NSString* dtdSystem;


- (id)initWithName:(NSString*)name xml:(BOOL)xml modules:(NSArray*)modules tidyModules:(NSArray*)tidyModules aliases:(NSArray*)aliases dtdPublic:(NSString*)dtdPublic dtdSystem:(NSString*)dtdSystem;


- (id)initWithName:(NSString*)name;


@end
