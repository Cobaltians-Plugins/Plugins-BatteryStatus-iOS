#import "BatteryChangeReceiver.h"

// Check iOS version
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v) ([[[UIDevice currentDevice] systemVersion] compare: v options: NSNumericSearch] != NSOrderedAscending)

@implementation BatteryChangeReceiver

- (instancetype) init {
    self = [super init];

    [[UIDevice currentDevice] setBatteryMonitoringEnabled: YES];

    return self;
}

- (instancetype) initWithDelegate: (id) delegate {
    self = [self init];

    [self setDelegate: delegate];

    return self;
}

- (void) setDelegate: (id) delegate {
    NSAssert([delegate respondsToSelector: @selector(onBatteryStateChanged:)], @"BatteryChangeReceiver setDelegate: delegate does not contain onBatteryStateChanged method");

    _delegate = delegate;
}

- (NSString *) getLevel {
    NSString * level = @"-1";

    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    if (batteryLevel >= 0.0) {
        static NSNumberFormatter * numberFormatter = nil;

        if (numberFormatter == nil) {
            numberFormatter = [[NSNumberFormatter alloc] init];
            [numberFormatter setNumberStyle: NSNumberFormatterNoStyle];
            [numberFormatter setMaximumFractionDigits: 1];
        }

        level = [numberFormatter stringFromNumber: [NSNumber numberWithFloat: batteryLevel * 100]];
    }

    return level;
}

- (NSString *) getState {
    static NSArray * batteryStates = nil;

    if (batteryStates == nil) {
        batteryStates = @[@"unknown", @"discharging", @"charging", @"full"];
    }

    NSString * state = batteryStates[0];

    NSProcessInfo * processInfo = [NSProcessInfo processInfo];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0") && [processInfo isLowPowerModeEnabled]) {
        state = @"low";
    }
    else {
        UIDeviceBatteryState currentState = [UIDevice currentDevice].batteryState;
        state = batteryStates[currentState - UIDeviceBatteryStateUnknown];
    }

    return state;
}

- (void) onBatteryStateChanged: (NSNotification *) notification {
    [_delegate onBatteryStateChanged: [self getState]];
}

- (void) startNotifier {
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(onBatteryStateChanged:)
                                                 name: UIDeviceBatteryStateDidChangeNotification
                                               object: nil];

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(onBatteryStateChanged:)
                                                     name: NSProcessInfoPowerStateDidChangeNotification
                                                   object: nil];
    }
}

- (void) stopNotifier {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) dealloc {
    [self stopNotifier];
}

@end
