//
//  CPBSignalMachine.m
//  CPBStateSignals
//
//  Created by Erik Price on 2013-08-14.
//  Copyright (c) 2013 Erik Price. All rights reserved.
//

#import "CPBSignalMachine.h"

#import "CPBTransitionTable.h"

#import "CPBTransition.h"


NSString * const CPBStateSignalsErrorDomain = @"CPBStateSignalsDomain";
NSInteger const CPBStateSignalsErrorCodeNoTransitionRegistered = 1;

@interface CPBSignalMachine ()

@property (nonatomic, copy) NSString *currentState;
@property (nonatomic, strong) CPBTransitionTable *transitionTable;
@property (nonatomic, strong) RACSubject *subject;

@end


@implementation CPBSignalMachine

- (id)init
{
    NSLog(@"%@ is not a valid initializer; use -[CPBSignalMachine initWithTransitionTable:] instead", NSStringFromSelector(_cmd));
    return [super init];
}

- (id)initWithTransitionTable:(CPBTransitionTable *)table initialState:(NSString *)initialState
{
    if (self = [super init])
    {
        _transitionTable = [table copy];
        _currentState = [initialState copy];
        _subject = [RACSubject subject];
    }
    
    return self;
}

- (void)inputEvent:(NSString *)event
{
    [self inputEvent:event context:nil];
}

- (void)inputEvent:(NSString *)event context:(id)eventContext
{
    eventContext = eventContext ?: NSNull.null;
    
    NSString *fromState = self.currentState;
    NSString *toState = [self.transitionTable toStateForEvent:event from:fromState];
    if (toState)
    {
        // TODO: should we create a signal of current state and zip with it to create the tuple, rather than store it in an ivar?
        self.currentState = toState;
        [self.subject sendNext:RACTuplePack(fromState, toState, event, eventContext)];
    }
    else
    {
        [self.subject sendNext:RACTuplePack(fromState, NSNull.null, event, eventContext)];
    }
}

- (RACSignal *)allTransitions
{
    return [self.subject
    map:^id(RACTuple *tuple) {
        return [[CPBTransition alloc] initWithFromState:tuple.first toState:tuple.second event:tuple.third context:tuple.fourth];
    }];
}

- (RACSignal *)transitionsFrom:(NSString *)fromState
{
    return [[self.subject
    filter:^BOOL(RACTuple *transition) {
        
        return [fromState isEqualToString:transition.first];
        
    }]
    map:^id(RACTuple *tuple) {
        return [[CPBTransition alloc] initWithFromState:tuple.first toState:tuple.second event:tuple.third context:tuple.fourth];
    }];
}

- (RACSignal *)transitionsFrom:(NSString *)fromState to:(NSString *)toState
{
    return [[self.subject
    filter:^BOOL(RACTuple *transition) {
        
        return [fromState isEqualToString:transition.first] && [toState isEqualToString:transition.second];
        
    }]
    map:^id(RACTuple *tuple) {
        return [[CPBTransition alloc] initWithFromState:tuple.first toState:tuple.second event:tuple.third context:tuple.fourth];
    }];
}

- (RACSignal *)transitionsTo:(NSString *)toState
{
    return [[self.subject
    filter:^BOOL(RACTuple *transition) {
        
        return [toState isEqualToString:transition.second];
        
    }]
    map:^id(RACTuple *tuple) {
        return [[CPBTransition alloc] initWithFromState:tuple.first toState:tuple.second event:tuple.third context:tuple.fourth];
    }];
}

- (RACSignal *)transitionFaults
{
    return [[self.subject
    filter:^BOOL(RACTuple *transition) {
        
        return NSNull.null == transition.second;
        
    }]
    map:^id(RACTuple *tuple) {
    return [[CPBTransition alloc] initWithFromState:tuple.first toState:tuple.second event:tuple.third context:tuple.fourth];
    }];
}

- (NSString *)description
{
    NSMutableString *desc = [[NSMutableString alloc] initWithFormat:@"<%@: %p;", self.class, self];
    [desc appendFormat:@" currentState = %@;", self.currentState];
    [desc appendFormat:@" transitionTable = %@;", self.transitionTable];
    [desc appendString:@">"];
    
    return desc;
}

+ (RACSignal *)errorOnTransitionFault:(RACSignal *)source
{
    return [[[source
    materialize]
    map:^id(RACEvent *racEvent) {
                 
        if (RACEventTypeNext == racEvent.eventType)
        {
            CPBTransition *transition = racEvent.value;
            NSString *fromState = transition.fromState;
            id toState = transition.toState;
            NSString *event = transition.event;
            
            if (NSNull.null == toState)
            {
                NSDictionary *userInfo = @{
                        NSLocalizedDescriptionKey: [NSString stringWithFormat:NSLocalizedString(@"No transition registered for event '%@' from state '%@'", nil), event, fromState],
                        NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Input only events that have transitions registered. The registered transitions can be printed with -[CPBSignalMachine description]. (Or handle errors sent on this signal using operators like -[RACSignal catch:] or -[RACSignal catchTo:].)", nil)
                };
                
                NSError *error = [NSError errorWithDomain:CPBStateSignalsErrorDomain code:CPBStateSignalsErrorCodeNoTransitionRegistered userInfo:userInfo];
                return [RACEvent eventWithError:error];
            }
        }
        
        return racEvent;
         
    }] dematerialize];
}

@end
