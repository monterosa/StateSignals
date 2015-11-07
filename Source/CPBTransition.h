//
//  CPBTransition.h
//  StateSignals
//
//  Created by Anders Frank on 07/11/15.
//  Copyright © 2015 Conceptual Plumbing. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPBTransition : NSObject

@property (nonatomic, readonly) NSString *fromState;
@property (nonatomic, readonly) NSString *toState;
@property (nonatomic, readonly) NSString *event;
@property (nonatomic, readonly) id context;

- (instancetype)initWithFromState:(NSString *)fromState toState:(NSString *)toState event:(NSString *)event context:(id)context;

@end
