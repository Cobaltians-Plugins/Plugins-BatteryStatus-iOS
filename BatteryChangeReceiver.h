#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface BatteryChangeReceiver: NSObject {
    id _delegate;
}

- (instancetype) init;
- (instancetype) initWithDelegate: (id) delegate;
- (void) setDelegate: (id) delegate;

- (NSString *) getLevel;
- (NSString *) getState;

- (void) startNotifier;
- (void) stopNotifier;

@end
