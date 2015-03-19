//
//	Copyright © 2012 - 2015 Roman Priebe
//
//	This file is part of M - Safe email made simple.
//
//	M is free software: you can redistribute it and/or modify
//	it under the terms of the GNU General Public License as published by
//	the Free Software Foundation, either version 3 of the License, or
//	(at your option) any later version.
//
//	M is distributed in the hope that it will be useful,
//	but WITHOUT ANY WARRANTY; without even the implied warranty of
//	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//	GNU General Public License for more details.
//
//	You should have received a copy of the GNU General Public License
//	along with M.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PGPPublicKey+Category.h"
#import "netpgp.h"
#import "keyring.h"
#import "OpenPGPWrapper.h"




@implementation PGPPublicKey (Category)

/* return 1 if the file contains ascii-armoured text */
static unsigned
isarmoured(NSString* string)
{
    return [string hasPrefix:@"-----BEGIN PGP"];
}



+ (BOOL)importKeyFromFileWithURL:(NSURL*)url
{
    __ops_keyring_t	*keyring = NULL; // read keyring
    unsigned realarmor;
    int done;
    __ops_key_t	*key;
    unsigned n = 0;

    NSData* data = [NSData dataWithContentsOfURL:url];

    NSString* string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    const char *f = [url.path cStringUsingEncoding:NSUTF8StringEncoding];

    realarmor = isarmoured(string);

    if ((keyring = calloc(1, sizeof(*keyring))) == NULL)
    {
        (void) fprintf(stderr, "readkeyring: bad alloc\n");
        return 0;
    }

    done = __ops_keyring_fileread(keyring, realarmor, f);

    if (!done)
    {
        NSLog(@"Cannot import key from file %s\n", f);
        return 0;
    }

    BOOL foundAKey = NO;

    for (n = 0, key = keyring->keys; n < keyring->keyc; ++n, ++key)
    {
        if (!__ops_is_key_secret(key))
        {

        }

        foundAKey = YES;
    }


//    // append to netpgp keyring (I could load again but don't have to)
//    done = __ops_append_keyring(netpgp->pubring, keyring);
//
    if (keyring != NULL)
    {
        __ops_keyring_free(keyring);
        free(keyring);
    }

    return foundAKey;
}





@end
