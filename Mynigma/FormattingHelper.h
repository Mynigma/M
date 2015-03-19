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





#import <Foundation/Foundation.h>

@class EmailFooter, DOMDocument, EmailMessageInstance, Recipient, EmailMessage, EmailRecipient, WebView;

@interface FormattingHelper : NSObject


+ (NSString*)trimLeadingWhitespaces:(NSString*)originalString;

+ (NSString*)stripReReRes:(NSString*)subjectString;

//adds a reference to the CSS style sheet (only needed on iOS)
+ (NSString*)addBlockquoteCSSStylesheetToHTML:(NSString*)HTMLString;

//takes an email (possibly received, with complicated HTML) and adds the footer at the appropriate point
+ (NSString*)addFooter:(EmailFooter*)footer toHTMLEmail:(NSString*)htmlEmail;

//creates an empty message with the specified footer
+ (NSString*)emptyEmailWithFooter:(EmailFooter*)footer;

//creates an invitation message with the specified footer
+ (NSString*)invitationEmailToRecipients:(NSArray*)recipients fromSender:(EmailRecipient*)sender withFooter:(EmailFooter*)footer style:(NSString*)styleString;

//changes the footer of a that is in the process of being composed
+ (void)changeHTMLEmail:(DOMDocument*)htmlEmail toFooter:(EmailFooter*)footer;

#if TARGET_OS_IPHONE

#else

+ (void)addTitleAttributeToAllLinksInWebView:(WebView*)webview;

+ (void)collapseLatestQuote:(WebView*)webview;

+ (void)uncollapseQuote:(WebView*)webview;

#endif


/**CALL ON MAIN*/
+ (EmailMessageInstance*)replyToMessageInstance:(EmailMessageInstance*)messageInstance;

/**CALL ON MAIN*/
+ (EmailMessageInstance*)replyAllToMessageInstance:(EmailMessageInstance*)messageInstance;

/**CALL ON MAIN*/
+ (EmailMessageInstance*)forwardOfMessageInstance:(EmailMessageInstance*)messageInstance;

/**CALL ON MAIN*/
+ (EmailMessageInstance*)replyToMessage:(EmailMessage*)message;

/**CALL ON MAIN*/
+ (EmailMessageInstance*)replyAllToMessage:(EmailMessage*)message;

/**CALL ON MAIN*/
+ (EmailMessageInstance*)forwardOfMessage:(EmailMessage*)message;


/**CALL ON MAIN*/
+ (EmailMessageInstance*)freshComposedMessageInstanceWithSenderRecipient:(Recipient*)recipient;

#if TARGET_OS_IPHONE

+ (NSString*)prepareHTMLContentForDisplay:(NSString*)htmlBodyContent makeEditable:(BOOL)editable;

+ (NSString*)getsavableHTMLFromTextView:(UITextView*)textView;

+ (NSString*)getSavableHTMLFromWebView:(UIWebView*)webView;

#endif

@end
