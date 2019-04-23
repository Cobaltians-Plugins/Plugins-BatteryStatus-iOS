#import "CobaltBatteryStatusPlugin.h"
#import <Cobalt/PubSub.h>

@implementation CobaltBatteryStatusPlugin

- (instancetype) init {
    if (self = [super init]) {
        _batteryChangeReceiver = [[BatteryChangeReceiver alloc] initWithDelegate: self];
        _listeningControllers = [NSHashTable hashTableWithOptions: NSPointerFunctionsWeakMemory];
    }

    return self;
}
- (void)onMessageFromWebView:(WebViewType)webView
          inCobaltController:(nonnull CobaltViewController *)viewController
                  withAction:(nonnull NSString *)action
                        data:(nullable NSDictionary *)data
          andCallbackChannel:(nullable NSString *)callbackChannel{

    if ([action isEqualToString: @"getLevel"]) {
        NSDictionary * level = @{@"level": [self getLevel]};

        [[PubSub sharedInstance] publishMessage:level
                                      toChannel:callbackChannel];
    }
    else if ([action isEqualToString: @"getState"]) {
        NSDictionary * state = @{@"state": [self getState]};

        [[PubSub sharedInstance] publishMessage:state
                                      toChannel:callbackChannel];
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
            kJSPluginName: @"CobaltBatteryStatusPlugin",
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
