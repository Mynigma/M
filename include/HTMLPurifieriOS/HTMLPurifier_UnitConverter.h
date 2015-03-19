//
//   HTMLPurifier_UnitConverter.h
//   HTMLPurifier
//
//  Created by Roman Priebe on 18.01.14.


@class HTMLPurifier_Length;

@interface HTMLPurifier_UnitConverter : NSObject
{
    /**
     * Minimum bcmath precision for output.
     * @type int
     */
    NSInteger outputPrecision;

    /**
     * Bcmath precision for internal calculations.
     * @type int
     */
    NSInteger internalPrecision;
}

- (HTMLPurifier_Length*)convert:(HTMLPurifier_Length*)length unit:(NSString*)to_unit;

- (id)initWithOutputPrecision:(NSInteger)output_precision internalPrecision:(NSInteger)internal_precision;

- (NSInteger)getSigFigs:(NSString*)n;


@end
