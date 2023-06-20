#import "WakelockPlusPlugin.h"
#import "messages.g.h"
#import "UIApplication+idleTimerLock.h"

@interface WakelockPlusPlugin () <FLTWakelockPlusApi>

@property (nonatomic, assign) BOOL enable;

@end

@implementation WakelockPlusPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  WakelockPlusPlugin* instance = [[WakelockPlusPlugin alloc] init];
  FLTWakelockPlusApiSetup(registrar.messenger, instance);
}

- (void)toggleMsg:(FLTToggleMessage*)input error:(FlutterError**)error {
  BOOL enable = [input.enable boolValue];
  if (!enable) {
    [[UIApplication sharedApplication] lock_idleTimerlockEnable:enable];//should disable first
    [self setIdleTimerDisabled:enable];
  } else {
    [self setIdleTimerDisabled:enable];
    [[UIApplication sharedApplication] lock_idleTimerlockEnable:enable];
  }
  self.enable = enable;
}

- (void)setIdleTimerDisabled:(BOOL)enable {
  BOOL enabled = [[UIApplication sharedApplication] isIdleTimerDisabled];
  if (enable!= enabled) {
    [[UIApplication sharedApplication] setIdleTimerDisabled:enable];
  }
}


- (FLTIsEnabledMessage*)isEnabledWithError:(FlutterError* __autoreleasing *)error {
  NSNumber *enabled = [NSNumber numberWithBool:[[UIApplication sharedApplication] isIdleTimerDisabled]];
  FLTIsEnabledMessage* result = [[FLTIsEnabledMessage alloc] init];
  result.enabled = enabled;
  return result;
}

- (void)setEnable:(BOOL)enable {
  _enable = enable;
}

@end
