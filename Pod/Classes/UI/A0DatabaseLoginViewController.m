//  A0DatabaseLoginViewController.m
//
// Copyright (c) 2014 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "A0DatabaseLoginViewController.h"
#import "A0ProgressButton.h"
#import "UIButton+A0SolidButton.h"
#import "A0DatabaseLoginCredentialValidator.h"
#import "A0Errors.h"
#import "A0APIClient.h"
#import "A0Theme.h"

#import <CoreGraphics/CoreGraphics.h>
#import <libextobjc/EXTScope.h>

static void showAlertErrorView(NSString *title, NSString *message) {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                          otherButtonTitles:nil];
    [alert show];
}

@interface A0DatabaseLoginViewController ()

@property (weak, nonatomic) IBOutlet UIView *credentialsBoxView;
@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray *icons;

- (IBAction)access:(id)sender;
- (IBAction)goToPasswordField:(id)sender;
- (IBAction)showSignUp:(id)sender;
- (IBAction)showForgotPassword:(id)sender;

@end

@implementation A0DatabaseLoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Login", nil);
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.credentialsBoxView.layer.borderWidth = 1.0f;
    self.credentialsBoxView.layer.borderColor = [[UIColor colorWithWhite:0.600 alpha:1.000] CGColor];
    self.credentialsBoxView.layer.cornerRadius = 3.0f;

    for (UIImageView *icon in self.icons) {
        icon.image = [icon.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }

    A0Theme *theme = [A0Theme sharedInstance];
    [theme configurePrimaryButton:self.accessButton];
    [theme configureSecondaryButton:self.signUpButton];
    [theme configureSecondaryButton:self.forgotPasswordButton];
    [theme configureTextField:self.userTextField];
    [theme configureTextField:self.passwordTextField];
}

- (void)access:(id)sender {
    [self.accessButton setInProgress:YES];
    NSError *error;
    [self.validator setUsername:self.userTextField.text password:self.passwordTextField.text];
    if ([self.validator validateCredential:&error]) {
        [self hideKeyboard];
        NSString *username = [self.userTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *password = self.passwordTextField.text;
        @weakify(self);
        A0APIClientAuthenticationSuccess success = ^(A0UserProfile *profile, A0Token *token){
            @strongify(self);
            [self.accessButton setInProgress:NO];
            if (self.onLoginBlock) {
                self.onLoginBlock(profile, token);
            }
        };
        A0APIClientError failure = ^(NSError *error) {
            [self.accessButton setInProgress:NO];
            showAlertErrorView(NSLocalizedString(@"There was an error logging in", nil), [A0Errors localizedStringForLoginError:error]);
        };
        [[A0APIClient sharedClient] loginWithUsername:username password:password success:success failure:failure];
    } else {
        [self.accessButton setInProgress:NO];
        showAlertErrorView(error.localizedDescription, error.localizedFailureReason);
    }
    [self updateUIWithError:error];
}

- (void)goToPasswordField:(id)sender {
    [self.passwordTextField becomeFirstResponder];
}

- (void)showSignUp:(id)sender {
    if (self.onShowSignUp) {
        self.onShowSignUp();
    }
}

- (void)showForgotPassword:(id)sender {
    if (self.onShowForgotPassword) {
        self.onShowForgotPassword();
    }
}

#pragma mark - A0KeyboardEnabledView

- (CGRect)rectToKeepVisibleInView:(UIView *)view {
    CGRect rect = [view convertRect:self.accessButton.frame fromView:self.accessButton.superview];
    return rect;
}

- (void)hideKeyboard {
    [self.userTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}

#pragma mark - Utility methods

- (void)updateUIWithError:(NSError *)error {
    self.userTextField.textColor = [UIColor blackColor];
    self.passwordTextField.textColor = [UIColor blackColor];
    if (error) {
        switch (error.code) {
            case A0ErrorCodeInvalidCredentials:
                self.userTextField.textColor = [UIColor redColor];
                self.passwordTextField.textColor = [UIColor redColor];
                break;
            case A0ErrorCodeInvalidPassword:
                self.passwordTextField.textColor = [UIColor redColor];
                break;
            case A0ErrorCodeInvalidUsername:
                self.userTextField.textColor = [UIColor redColor];
                break;
        }
    }
}

@end