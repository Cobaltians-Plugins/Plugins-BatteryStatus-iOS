#import <Cobalt/CobaltAbstractPlugin.h>
#import "BatteryChangeReceiver.h"

@interface CobaltBatteryStatusPlugin: CobaltAbstractPlugin {
    BatteryChangeReceiver * _batteryChangeReceiver;
    NSHashTable * _listeningControllers;
}

- (instancetype) init;
- (void) onBatteryStateChanged: (NSString *) state;

@end
