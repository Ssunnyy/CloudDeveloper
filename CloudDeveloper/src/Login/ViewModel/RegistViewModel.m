//
//  RegistViewModel.m
//  CloudDeveloper
//
//  Created by _Finder丶Tiwk on 16/4/8.
//  Copyright © 2016年 _Finder丶Tiwk. All rights reserved.
//

#import "RegistViewModel.h"

@implementation RegistViewModel

@end

#pragma mark - ReactiveCocoa

@implementation RegistViewModel (ReactiveCocoa)

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

- (RACSignal *)confirmPasswordValidSignal{
    if (!_confirmPasswordValidSignal) {
        _confirmPasswordValidSignal = [RACObserve(self, confirmPassword) map:^id(NSString *text) {
            NSUInteger length = text.length;
            return @(length >=6 && length <8);
        }];
    }
    return _confirmPasswordValidSignal;
}


- (RACCommand *)registCommand{
    if (!_registCommand) {
        RACSignal *validSignal = [RACSignal merge:@[self.accountValidSignal,self.passwordValidSignal]];
        @weakify(self)
        _registCommand = [[RACCommand alloc] initWithEnabled:validSignal signalBlock:^RACSignal *(id input) {
            @strongify(self)
            return [self registLogic];
        }];

        [_registCommand.executing subscribeNext:^(id x) {
            if ([x boolValue]) {
                [SVProgressHUD showWithStatus:@"Registing..."];
            }else{
                [SVProgressHUD dismissWithDelay:1.2];
            }
        }];

        [_registCommand.errors subscribeNext:^(NSError *error) {
            [SVProgressHUD showErrorWithStatus:error.userInfo[@"message"]];
            
        }];
        
//        [_registCommand.executionSignals doNext:^(id x) {
//            NSString *successMessage = [NSString stringWithFormat:@"恭喜您，注册成功\n账号:%@\n密码:%@",self.account,self.password];
//            [SVProgressHUD showWithStatus:successMessage];
//        }];
    }
    return _registCommand;
}

- (RACSignal *)registLogic{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [[RACScheduler scheduler] schedule:^{
            EMError *error = [[EMClient sharedClient] registerWithUsername:self.account password:self.password];
            [[RACScheduler mainThreadScheduler] schedule:^{
                if (error) {
                    [subscriber sendError:[NSError errorWithDomain:@"com.fanhua.www" code:-1 userInfo:@{@"message":error.errorDescription}]];
                }else{
                    [subscriber sendNext:@{@"code":@"0",@"message":@""}];
                    [subscriber sendCompleted];
                }
            }];
        }];
        return nil;
    }];
}


@end


