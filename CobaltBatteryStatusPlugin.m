#import "CobaltBatteryStatusPlugin.h"

@implementation CobaltBatteryStatusPlugin

- (instancetype) init {
    if (self = [super init]) {
        _batteryChangeReceiver = [[BatteryChangeReceiver alloc] initWithDelegate: self];
        _listeningControllers = [NSHashTable hashTableWithOptions: NSPointerFunctionsWeakMemory];
    }

    return self;
}

- (void) onMessageFromCobaltController: (CobaltViewController *) viewController
                               andData: (NSDictionary *) data {
    [self onMessageWithCobaltController: viewController
                                andData: data];
}

- (void) onMessageFromWebLayerWithCobaltController: (CobaltViewController *) viewController
                                           andData: (NSDictionary *) data {
    [self onMessageWithCobaltController: viewController
                                andData: data];
}

- (void) onMessageWithCobaltController: (CobaltViewController *) viewController
                               andData: (NSDictionary *) data {
    NSString * callback = [data objectForKey: kJSCallback];
    NSString * action = [data objectForKey: kJSAction];

    if (action != nil) {
        if ([action isEqualToString: @"getLevel"]) {
            NSDictionary * level = @{@"level": [self getLevel]};

            [viewController sendCallback: callback
                                withData: level];
        }
        else if ([action isEqualToString: @"getState"]) {
            NSDictionary * state = @{@"state": [self getState]};

            [viewController sendCallback: callback
                                withData: state];
        }
        else if ([action isEqualToString: @"startStateMonitoring"]) {
            [self startStateMonitoring: viewController];
        }
        else if ([action isEqualToString: @"stopStateMonitoring"]) {
            [self stopStateMonitoring: viewController];
        }
        else {
            NSLog(@"CobaltBatteryStatusPlugin onMessageWithCobaltController:andData: unknown action %@", action);
        }
    }
    else {
        NSLog(@"CobaltBatteryStatusPlugin onMessageWithCobaltController:andData: action is nil");
    }
}

- (NSString *) getLevel {
    return [_batteryChangeReceiver getLevel];
}

- (NSString *) getState {
    return [_batteryChangeReceiver getState];
}

- (void) onBatteryStateChanged: (NSString *) state {
    if ([_listeningControllers anyObject] != nil) {
        NSDictionary * message = @{
            kJSType: kJSTypePlugin,
            kJSPluginName: @"batteryStatus",
            kJSAction: @"onStateChanged",
            kJSData: @{@"state": state}
        };

        for (CobaltViewController * viewController in _listeningControllers) {
            if (viewController != nil) {
                [viewController sendMessage: message];
            }
        }
    }
    else {
        [_batteryChangeReceiver stopNotifier];
    }
}

- (void) startStateMonitoring: (CobaltViewController *) viewController {
    if (![_listeningControllers containsObject: viewController]) {
        if ([_listeningControllers anyObject] == nil) {
            [_batteryChangeReceiver startNotifier];
        }

        [_listeningControllers addObject: viewController];
    }
}

- (void) stopStateMonitoring: (CobaltViewController *) viewController {
    if ([_listeningControllers containsObject: viewController]) {
        [_listeningControllers removeObject: viewController];

        if ([_listeningControllers anyObject] == nil) {
            [_batteryChangeReceiver stopNotifier];
        }
    }
}

@end
