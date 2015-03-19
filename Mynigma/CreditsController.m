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





#import "CreditsController.h"
#import "AppDelegate.h"
#import <WebKit/WebKit.h>


@interface CreditsController ()

@end

@implementation CreditsController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.webview setScalesPageToFit:!RUNNING_AT_LEAST_IOS8];
    
    NSURL *rtfUrl = [[NSBundle mainBundle] URLForResource:@"Credits" withExtension:@"rtf"];

    NSURLRequest *request = [NSURLRequest requestWithURL:rtfUrl];

    if(request)
    {
        [self.webview loadRequest:request];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UIWebView delegate

- (BOOL)webView:(UIWebView*)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType
{
    if ( inType == UIWebViewNavigationTypeLinkClicked )
    {
        [[UIApplication sharedApplication] openURL:[inRequest URL]];
        return NO;
    }
    
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.heightConstraint setConstant:self.webview.scrollView.contentSize.height];
}

@end
