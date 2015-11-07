//
//  CPBTransition.m
//  StateSignals
//
//  Created by Anders Frank on 07/11/15.
//  Copyright © 2015 Conceptual Plumbing. All rights reserved.
//

#import "CPBTransition.h"

@implementation CPBTransition

- (instancetype)initWithFromState:(NSString *)fromState toState:(NSString *)toState event:(NSString *)event context:(id)context
{
    self = [super init];
    if (self) {
        _fromState = [fromState copy];
        _toState = [toState copy];
        _event = [event copy];
        _context = context;
    }
    return self;
}

- (NSString *)description {
   return [NSString stringWithFormat:@"%@ fromState: %@ toState: %@ event: %@ context: %@", self.class, self.fromState, self.toState, self.event, self.context];
}

@end
