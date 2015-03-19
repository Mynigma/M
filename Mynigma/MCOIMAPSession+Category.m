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





#import "MCOIMAPSession+Category.h"

@implementation MCOIMAPSession (Category)


//to be overwritten in unit tests
+ (MCOIMAPSession*)freshSession
{
    return [MCOIMAPSession new];
}

- (MCOIMAPSession*)copyThisSession
{
    MCOIMAPSession* newSession = [MCOIMAPSession freshSession];

    [newSession setAllowsFolderConcurrentAccessEnabled:self.allowsFolderConcurrentAccessEnabled];
    [newSession setAuthType:self.authType];
    [newSession setCheckCertificateEnabled:self.checkCertificateEnabled];
    [newSession setConnectionLogger:self.connectionLogger];
    [newSession setConnectionType:self.connectionType];
    [newSession setDefaultNamespace:self.defaultNamespace];
    [newSession setDispatchQueue:self.dispatchQueue];
    [newSession setHostname:self.hostname];
    [newSession setMaximumConnections:self.maximumConnections];
    [newSession setOAuth2Token:self.OAuth2Token];
    [newSession setPassword:self.password];
    [newSession setPort:self.port];
    [newSession setTimeout:self.timeout];
    [newSession setUsername:self.username];
    [newSession setVoIPEnabled:self.voIPEnabled];

    return newSession;
}


- (BOOL)isValid
{
    if (!self.hostname)
        return NO;
    if (!self.port)
        return NO;
    if (!self.username)
        return NO;
    if (!self.password && !self.OAuth2Token)
        return NO;
    if (!self.authType)
        return NO;
    if (!self.connectionType)
        return NO;
    
    return YES;
}

- (NSString*)identifierString
{
    return [NSString stringWithFormat:@"(%@|%@|%@|%@|%@|%@|%@)", self.hostname, @(self.port), self.username, self.password, self.OAuth2Token, @(self.authType), @(self.connectionType)];
}

@end
