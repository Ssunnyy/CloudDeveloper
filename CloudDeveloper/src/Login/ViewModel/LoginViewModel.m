//
//  LoginViewModel.m
//  CloudDeveloper
//
//  Created by _Finder丶Tiwk on 16/4/7.
//  Copyright © 2016年 _Finder丶Tiwk. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewModel.h"

static NSString *const kRememberAccountKey = @"kRememberAccountKey";
static NSString *const kRememberPasswordKey = @"kRememberPasswordKey";

@interface LoginViewModel ()

@property (nonatomic,strong) RACSignal *accountValidSignal;
@property (nonatomic,strong) RACSignal *passwordValidSignal;

@end

@implementation LoginViewModel

- (instancetype)init{
    self = [super init];
    if (self) {
        [self historyAccount];
    }
    return self;
}

- (void)historyAccount{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.account = [defaults valueForKey:kRememberAccountKey]?:@"";
    self.password = [defaults valueForKey:kRememberPasswordKey]?:@"";
}


@end

#pragma mark - ReactiveCocoa

@implementation LoginViewModel (ReactiveCocoa)

- (RACSignal *)accountValidSignal{
    if (!_accountValidSignal) {
        _accountValidSignal = [RACObserve(self, account) map:^id(NSString *text) {
            NSUInteger length = text.length;
            return @(length >=5 && length <8);
        }];
    }
    return _accountValidSignal;
}

- (RACSignal *)passwordValidSignal{
    if (!_passwordValidSignal) {
        _passwordValidSignal = [RACObserve(self, password) map:^id(NSString *text) {
            NSUInteger length = text.length;
            return @(length >=6 && length <8);
        }];
    }
    return _passwordValidSignal;
}


- (RACCommand *)loginCommand{
    if (!_loginCommand) {
        RACSignal *validSignal = [RACSignal merge:@[self.accountValidSignal,self.passwordValidSignal]];
        @weakify(self)
        _loginCommand = [[RACCommand alloc] initWithEnabled:validSignal signalBlock:^RACSignal *(id input) {
            @strongify(self)
            return [self loginLogic];
        }];
        
        [_loginCommand.executing subscribeNext:^(id x) {
            BOOL transcation = [x boolValue];
            if (transcation) {
                [SVProgressHUD showWithStatus:@"登录中..."];
            }else{
                [SVProgressHUD dismissWithDelay:1.2];
            }
        }];
        
        [_loginCommand.errors subscribeNext:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"message"]];
        }];
        
        [_loginCommand.executionSignals.flatten subscribeNext:^(id x) {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"HomeViewController" bundle:nil];
            UIViewController *homeViewController = [storyBoard instantiateInitialViewController];
            [[UIApplication sharedApplication].keyWindow setRootViewController:homeViewController];
        }];
    }
    return _loginCommand;
}

- (RACSignal *)loginLogic{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[RACScheduler scheduler] schedule:^{
            EMError *error = [[EMClient sharedClient] loginWithUsername:self.account password:self.password];
            [[RACScheduler mainThreadScheduler] schedule:^{
                if (error) {
                    [subscriber sendError:[NSError errorWithDomain:@"com.fanhua.www" code:-1 userInfo:@{@"message":error.errorDescription}]];
                }else{
                    XFirend *user         = [XFirend firendWithAccount:self.account];
                    XGlobalConfig *config = [XGlobalConfig shareXGlobalConfig];
                    config.loginUser      = user;
                    [self remember];
                    [subscriber sendNext:@{@"code":@"0",@"message":@""}];
                    [subscriber sendCompleted];
                }
            }];
        }];
        return nil;
    }];
}

- (void)remember{
    if (self.rememberAccount) {
        NSLog(@"记住用户名密码");
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setValue:self.account forKey:kRememberAccountKey];
        [defaults setValue:self.password forKey:kRememberPasswordKey];
        [defaults synchronize];
    }
}

@end