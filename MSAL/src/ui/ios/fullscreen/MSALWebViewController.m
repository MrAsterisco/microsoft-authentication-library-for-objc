//
//  MSALWebViewController.m
//  MSAL (iOS Framework)
//
//  Created by Alessio Moiso on 24/01/2018.
//  Copyright © 2018 Microsoft. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <UIKit/UIKit.h>

#import "MSALWebViewController.h"
#import "MSALFullscreenWebView.h"

@interface MSALWebViewController () <WKUIDelegate, WKNavigationDelegate, UIScrollViewDelegate>

@end

@implementation MSALWebViewController
{
	NSURL *_url;
	UIView *_containerView;
	WKWebView *_webView;
}

- (instancetype)initWithURL:(NSURL *)url {
	if (self = [super init]) {
		self->_url = url;
	}
	return self;
}

- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:CGRectZero];
	self.view.backgroundColor = [UIColor clearColor];

	_containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
	_containerView.translatesAutoresizingMaskIntoConstraints = NO;
	_containerView.hidden = YES;

	NSSet *websiteDataTypes = [NSSet setWithArray:@[WKWebsiteDataTypeCookies, WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache]];
	[[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:[NSDate dateWithTimeIntervalSince1970: 0] completionHandler:^{ }];

	WKWebViewConfiguration* configuration = [WKWebViewConfiguration new];
	_webView = [[MSALFullscreenWebView alloc] initWithFrame:CGRectZero configuration: configuration];
	_webView.scrollView.delegate = self;
	_webView.navigationDelegate = self;
	_webView.allowsLinkPreview = false;
	_webView.allowsBackForwardNavigationGestures = NO;
	_webView.translatesAutoresizingMaskIntoConstraints = NO;
	_webView.scrollView.alwaysBounceVertical = NO;
	_webView.scrollView.bounces = NO;

	[_containerView addSubview:_webView];
	[self.view addSubview:_containerView];

	[[_containerView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:1] setActive:YES];
	[[_containerView.heightAnchor constraintEqualToAnchor:self.view.heightAnchor multiplier:1] setActive:YES];
	[[_containerView.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor] setActive:YES];
	[[_containerView.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor] setActive:YES];

	if (@available(iOS 11.0, *)) {
		[[_webView.safeAreaLayoutGuide.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor] setActive:YES];
		[[_webView.safeAreaLayoutGuide.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor] setActive:YES];
		[[_webView.safeAreaLayoutGuide.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor] setActive:YES];
		[[_webView.safeAreaLayoutGuide.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor] setActive:YES];
	} else {
		[[_webView.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
		[[_webView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor] setActive:YES];
		[[_webView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] setActive:YES];
		[[_webView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
	}
}

- (void)navigate {
	[_webView loadRequest:[NSURLRequest requestWithURL:self->_url]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self navigate];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return self.statusBarStyle;
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	(void)scrollView;
	return nil;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
	(void)webView;
	(void)navigation;

	CATransition *animation = [CATransition animation];
	[animation setDuration:0.4];
	[animation setType:kCATransitionPush];
	[animation setSubtype:kCATransitionFromTop];
	[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

	[_containerView.layer addAnimation:animation forKey:nil];
	_containerView.hidden = YES;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
	(void)webView;
	(void)navigation;

	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		CATransition *animation = [CATransition animation];
		[animation setDuration:0.6];
		[animation setType:kCATransitionPush];
		[animation setSubtype:kCATransitionFromTop];
		[animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

		[_containerView.layer addAnimation:animation forKey:nil];
		_containerView.hidden = NO;
	});
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	(void)webView;
	NSLog(@"%@", navigationAction.request.URL);

	NSURL *url = navigationAction.request.URL;
	NSString *scheme = url.scheme;
	if ([scheme containsString:@"msal"]) {
		if ([UIApplication.sharedApplication canOpenURL:url]) {
			if ([url.absoluteString containsString:@"access_denied"]) {
				if ([self.delegate respondsToSelector:@selector(webViewControllerDidFinish:withError:)]) {
					[self.delegate webViewControllerDidFinish:self withError:[NSError errorWithDomain:MSALErrorDomain code:MSALErrorUserCanceled userInfo:nil]];
				}
			}
			else if ([url.absoluteString containsString:@"reset"]) {
				if ([self.delegate respondsToSelector:@selector(webViewControllerDidReceiveReset:)]) {
					[self.delegate webViewControllerDidReceiveReset:self];
				}
			}
			else {
				[UIApplication.sharedApplication openURL:url];
			}
		}
		else {
			if ([self.delegate respondsToSelector:@selector(webViewControllerDidFinish:withError:)]) {
				[self.delegate webViewControllerDidFinish:self withError:[NSError errorWithDomain:MSALErrorDomain code:MSALErrorWrongClientId userInfo:nil]];
			}
		}

		decisionHandler(WKNavigationActionPolicyCancel);
		return;
	}

	decisionHandler(WKNavigationActionPolicyAllow);
}

@end
