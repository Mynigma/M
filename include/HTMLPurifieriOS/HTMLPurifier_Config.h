//
//   HTMLPurifier_Config.h
//   HTMLPurifier
//
//  Created by Lukas Neumann on 10.01.14.


#import <Foundation/Foundation.h>

@class HTMLPurifier_ConfigSchema, HTMLPurifier_VarParser_Flexible, HTMLPurifier_PropertyList, HTMLPurifier_Definition, HTMLPurifier_CSSDefinition, HTMLPurifier_URIDefinition, HTMLPurifier_HTMLDefinition, HTMLPurifier_PropertyList;

@interface HTMLPurifier_Config : NSObject
{
    HTMLPurifier_PropertyList* plist;
    HTMLPurifier_VarParser_Flexible* parser;
    HTMLPurifier_PropertyList* parent;

    NSString* lock;
    BOOL aliasMode;

    NSMutableDictionary* serials;
    NSString* serial;

    NSMutableDictionary* definitions;

    BOOL finalized;
}


@property BOOL auto_finalize;

@property HTMLPurifier_ConfigSchema* def;

@property BOOL chatty;

+ (HTMLPurifier_Config*)createWithConfig:(HTMLPurifier_Config*)config;

//- (HTMLPurifier_ConfigSchema*)definition;


- (id)initWithDefinition:(HTMLPurifier_ConfigSchema*)definition parent:(HTMLPurifier_PropertyList*)newParent;

/**
 * Convenience constructor that creates a config object based on a mixed var
 * @param mixed $config Variable that defines the state of the config
 *                      object. Can be: a HTMLPurifier_Config() object,
 *                      an array of directives based on loadArray(),
 *                      or a string filename of an ini file.
 * @param HTMLPurifier_ConfigSchema $schema Schema object
 * @return HTMLPurifier_Config Configured object
 */
+ (HTMLPurifier_Config*)createWithConfig:(HTMLPurifier_Config*)config schema:(HTMLPurifier_ConfigSchema*)schema;

/**
 * Convenience constructor that creates a default configuration object.
 * @return HTMLPurifier_Config default object.
 */
+ (HTMLPurifier_Config*)createDefault;

/**
 * Retrieves a value from the configuration.
 *
 * @param string $key String key
 * @param mixed $a
 *
 * @return mixed
 */
- (NSObject*)get:(NSString*)key;

/**
 * Retrieves an array of directives to values from a given namespace
 *
 * @param string $namespace String namespace
 *
 * @return array
 */
- (NSDictionary*)getBatch:(NSString*)namespace;

/**
 * Returns a SHA-1 signature of a segment of the configuration object
 * that uniquely identifies that particular configuration
 *
 * @param string $namespace Namespace to get serial for
 *
 * @return string
 * @note Revision is handled specially and is removed from the batch
 *       before processing!
 */
- (NSString*)getBatchSerial:(NSString*)namespace;

/**
 * Returns a SHA-1 signature for the entire configuration object
 * that uniquely identifies that particular configuration
 *
 * @return string
 */
- (NSString*)getSerial;

/**
 * Retrieves all directives, organized by namespace
 *
 * @warning This is a pretty inefficient function, avoid if you can
 */
- (NSDictionary*)getAll;

/**
 * Sets a value to configuration.
 *
 * @param string $key key
 * @param mixed $value value
 * @param mixed $a
 */
- (void)setString:(NSString*)key object:(NSObject*)value;

/**
 * Convenience function for error reporting
 *
 * @param array $lookup
 *
 * @return string
 */
- (NSString*)_listify:(NSDictionary*)lookup;

/**
 * Retrieves object reference to the HTML definition.
 *
 * @param bool $raw Return a copy that has not been setup yet. Must be
 *             called before it's been setup, otherwise won't work.
 * @param bool $optimized If true, this method may return null, to
 *             indicate that a cached version of the modified
 *             definition object is available and no further edits
 *             are necessary.  Consider using
 *             maybeGetRawHTMLDefinition, which is more explicitly
 *             named, instead.
 *
 * @return HTMLPurifier_HTMLDefinition
 */
- (HTMLPurifier_HTMLDefinition*)getHTMLDefinition;

/**
 * Retrieves object reference to the CSS definition
 *
 * @param bool $raw Return a copy that has not been setup yet. Must be
 *             called before it's been setup, otherwise won't work.
 * @param bool $optimized If true, this method may return null, to
 *             indicate that a cached version of the modified
 *             definition object is available and no further edits
 *             are necessary.  Consider using
 *             maybeGetRawCSSDefinition, which is more explicitly
 *             named, instead.
 *
 * @return HTMLPurifier_CSSDefinition
 */
- (HTMLPurifier_CSSDefinition*)getCSSDefinition;

/**
 * Retrieves object reference to the URI definition
 *
 * @param bool $raw Return a copy that has not been setup yet. Must be
 *             called before it's been setup, otherwise won't work.
 * @param bool $optimized If true, this method may return null, to
 *             indicate that a cached version of the modified
 *             definition object is available and no further edits
 *             are necessary.  Consider using
 *             maybeGetRawURIDefinition, which is more explicitly
 *             named, instead.
 *
 * @return HTMLPurifier_URIDefinition
 */
- (HTMLPurifier_URIDefinition*)getURIDefinition;

- (HTMLPurifier_Definition*)getDefinition:(NSString*)type;
/**
 * Retrieves a definition
 *
 * @param string $type Type of definition: HTML, CSS, etc
 * @param bool $raw Whether or not definition should be returned raw
 * @param bool $optimized Only has an effect when $raw is true.  Whether
 *        or not to return null if the result is already present in
 *        the cache.  This is off by default for backwards
 *        compatibility reasons, but you need to do things this
 *        way in order to ensure that caching is done properly.
 *        Check out enduser-customize.html for more details.
 *        We probably won't ever change this default, as much as the
 *        maybe semantics is the "right thing to do."
 *
 * @throws HTMLPurifier_Exception
 * @return HTMLPurifier_Definition
 */
- (HTMLPurifier_Definition*)getDefinition:(NSString*)type raw:(BOOL)raw optimized:(BOOL)optimized;

/**
 * Initialise definition
 *
 * @param string $type What type of definition to create
 *
 * @return HTMLPurifier_CSSDefinition|HTMLPurifier_HTMLDefinition|HTMLPurifier_URIDefinition
 * @throws HTMLPurifier_Exception
 */

- (HTMLPurifier_Definition*)InitialiseDefinition:(NSString*)type;

- (HTMLPurifier_Definition*)maybeGetRawDefinition:(NSString*)name;

- (HTMLPurifier_Definition*)maybeGetRawHTMLDefinition;

- (HTMLPurifier_Definition*)maybeGetRawCSSDefinition;

- (HTMLPurifier_Definition*)maybeGetRawURIDefinition;

//    /**
//     * Loads configuration values from an array with the following structure:
//     * Namespace.Directive => Value
//     *
//     * @param array $config_array Configuration associative array
//     */
//    public function loadArray($config_array)
//    {
//        if ($this->isFinalized('Cannot load directives after finalization')) {
//            return;
//        }
//        foreach ($config_array as $key => $value) {
//            $key = str_replace('_', '.', $key);
//            if (strpos($key, '.') !== false) {
//                $this->set($key, $value);
//            } else {
//                $namespace = $key;
//                $namespace_values = $value;
//                foreach ($namespace_values as $directive => $value2) {
//                    $this->set($namespace .'.'. $directive, $value2);
//                }
//            }
//        }
//    }
//
//    /**
//     * Returns a list of array(namespace, directive) for all directives
//     * that are allowed in a web-form context as per an allowed
//     * namespaces/directives list.
//     *
//     * @param array $allowed List of allowed namespaces/directives
//     * @param HTMLPurifier_ConfigSchema $schema Schema to use, if not global copy
//     *
//     * @return array
//     */
//    public static function getAllowedDirectivesForForm($allowed, $schema = null)
//    {
//        if (!$schema) {
//            $schema = HTMLPurifier_ConfigSchema::instance();
//        }
//        if ($allowed !== true) {
//            if (is_string($allowed)) {
//                $allowed = array($allowed);
//            }
//            $allowed_ns = array();
//            $allowed_directives = array();
//            $blacklisted_directives = array();
//            foreach ($allowed as $ns_or_directive) {
//                if (strpos($ns_or_directive, '.') !== false) {
//                    // directive
//                    if ($ns_or_directive[0] == '-') {
//                        $blacklisted_directives[substr($ns_or_directive, 1)] = true;
//                    } else {
//                        $allowed_directives[$ns_or_directive] = true;
//                    }
//                } else {
//                    // namespace
//                    $allowed_ns[$ns_or_directive] = true;
//                }
//            }
//        }
//        $ret = array();
//        foreach ($schema->info as $key => $def) {
//            list($ns, $directive) = explode('.', $key, 2);
//            if ($allowed !== true) {
//                if (isset($blacklisted_directives["$ns.$directive"])) {
//                    continue;
//                }
//                if (!isset($allowed_directives["$ns.$directive"]) && !isset($allowed_ns[$ns])) {
//                    continue;
//                }
//            }
//            if (isset($def->isAlias)) {
//                continue;
//            }
//            if ($directive == 'DefinitionID' || $directive == 'DefinitionRev') {
//                continue;
//            }
//            $ret[] = array($ns, $directive);
//        }
//        return $ret;
//    }
//
//    /**
//     * Loads configuration values from $_GET/$_POST that were posted
//     * via ConfigForm
//     *
//     * @param array $array $_GET or $_POST array to import
//     * @param string|bool $index Index/name that the config variables are in
//     * @param array|bool $allowed List of allowed namespaces/directives
//     * @param bool $mq_fix Boolean whether or not to enable magic quotes fix
//     * @param HTMLPurifier_ConfigSchema $schema Schema to use, if not global copy
//     *
//     * @return mixed
//     */
//    public static function loadArrayFromForm($array, $index = false, $allowed = true, $mq_fix = true, $schema = null)
//    {
//        $ret = HTMLPurifier_Config::prepareArrayFromForm($array, $index, $allowed, $mq_fix, $schema);
//        $config = HTMLPurifier_Config::create($ret, $schema);
//        return $config;
//    }
//
//    /**
//     * Merges in configuration values from $_GET/$_POST to object. NOT STATIC.
//     *
//     * @param array $array $_GET or $_POST array to import
//     * @param string|bool $index Index/name that the config variables are in
//     * @param array|bool $allowed List of allowed namespaces/directives
//     * @param bool $mq_fix Boolean whether or not to enable magic quotes fix
//     */
//    public function mergeArrayFromForm($array, $index = false, $allowed = true, $mq_fix = true)
//    {
//        $ret = HTMLPurifier_Config::prepareArrayFromForm($array, $index, $allowed, $mq_fix, $this->def);
//        $this->loadArray($ret);
//    }
//
//    /**
//     * Prepares an array from a form into something usable for the more
//     * strict parts of HTMLPurifier_Config
//     *
//     * @param array $array $_GET or $_POST array to import
//     * @param string|bool $index Index/name that the config variables are in
//     * @param array|bool $allowed List of allowed namespaces/directives
//     * @param bool $mq_fix Boolean whether or not to enable magic quotes fix
//     * @param HTMLPurifier_ConfigSchema $schema Schema to use, if not global copy
//     *
//     * @return array
//     */
//    public static function prepareArrayFromForm($array, $index = false, $allowed = true, $mq_fix = true, $schema = null)
//    {
//        if ($index !== false) {
//            $array = (isset($array[$index]) && is_array($array[$index])) ? $array[$index] : array();
//        }
//        $mq = $mq_fix && function_exists('get_magic_quotes_gpc') && get_magic_quotes_gpc();
//
//        $allowed = HTMLPurifier_Config::getAllowedDirectivesForForm($allowed, $schema);
//        $ret = array();
//        foreach ($allowed as $key) {
//            list($ns, $directive) = $key;
//            $skey = "$ns.$directive";
//            if (!empty($array["Null_$skey"])) {
//                $ret[$ns][$directive] = null;
//                continue;
//            }
//            if (!isset($array[$skey])) {
//                continue;
//            }
//            $value = $mq ? stripslashes($array[$skey]) : $array[$skey];
//            $ret[$ns][$directive] = $value;
//        }
//        return $ret;
//    }



/**
 * Checks whether or not the configuration object is finalized.
 *
 * @param string|bool $error String error message, or false for no error
 *
 * @return bool
 */
- (BOOL)isFinalized:(NSString*)error;
/**
 * Finalizes configuration only if auto finalize is on and not
 * already finalized
 */
- (void)autoFinalize;

/**
 * Finalizes a configuration object, prohibiting further change
 */
- (void)finalize;

/**
 * Returns a serialized form of the configuration object that can
 * be reconstituted.
 *
 * @return string
 */
- (NSString*)serialize;




@end
