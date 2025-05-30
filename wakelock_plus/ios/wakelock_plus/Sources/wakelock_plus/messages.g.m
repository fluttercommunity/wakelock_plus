// Autogenerated from Pigeon (v25.3.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#import "./include/wakelock_plus/messages.g.h"

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

#if !__has_feature(objc_arc)
#error File requires ARC to be enabled.
#endif

static NSArray<id> *wrapResult(id result, FlutterError *error) {
  if (error) {
    return @[
      error.code ?: [NSNull null], error.message ?: [NSNull null], error.details ?: [NSNull null]
    ];
  }
  return @[ result ?: [NSNull null] ];
}

static id GetNullableObjectAtIndex(NSArray<id> *array, NSInteger key) {
  id result = array[key];
  return (result == [NSNull null]) ? nil : result;
}

@interface WAKELOCKPLUSToggleMessage ()
+ (WAKELOCKPLUSToggleMessage *)fromList:(NSArray<id> *)list;
+ (nullable WAKELOCKPLUSToggleMessage *)nullableFromList:(NSArray<id> *)list;
- (NSArray<id> *)toList;
@end

@interface WAKELOCKPLUSIsEnabledMessage ()
+ (WAKELOCKPLUSIsEnabledMessage *)fromList:(NSArray<id> *)list;
+ (nullable WAKELOCKPLUSIsEnabledMessage *)nullableFromList:(NSArray<id> *)list;
- (NSArray<id> *)toList;
@end

@implementation WAKELOCKPLUSToggleMessage
+ (instancetype)makeWithEnable:(nullable NSNumber *)enable {
  WAKELOCKPLUSToggleMessage* pigeonResult = [[WAKELOCKPLUSToggleMessage alloc] init];
  pigeonResult.enable = enable;
  return pigeonResult;
}
+ (WAKELOCKPLUSToggleMessage *)fromList:(NSArray<id> *)list {
  WAKELOCKPLUSToggleMessage *pigeonResult = [[WAKELOCKPLUSToggleMessage alloc] init];
  pigeonResult.enable = GetNullableObjectAtIndex(list, 0);
  return pigeonResult;
}
+ (nullable WAKELOCKPLUSToggleMessage *)nullableFromList:(NSArray<id> *)list {
  return (list) ? [WAKELOCKPLUSToggleMessage fromList:list] : nil;
}
- (NSArray<id> *)toList {
  return @[
    self.enable ?: [NSNull null],
  ];
}
@end

@implementation WAKELOCKPLUSIsEnabledMessage
+ (instancetype)makeWithEnabled:(nullable NSNumber *)enabled {
  WAKELOCKPLUSIsEnabledMessage* pigeonResult = [[WAKELOCKPLUSIsEnabledMessage alloc] init];
  pigeonResult.enabled = enabled;
  return pigeonResult;
}
+ (WAKELOCKPLUSIsEnabledMessage *)fromList:(NSArray<id> *)list {
  WAKELOCKPLUSIsEnabledMessage *pigeonResult = [[WAKELOCKPLUSIsEnabledMessage alloc] init];
  pigeonResult.enabled = GetNullableObjectAtIndex(list, 0);
  return pigeonResult;
}
+ (nullable WAKELOCKPLUSIsEnabledMessage *)nullableFromList:(NSArray<id> *)list {
  return (list) ? [WAKELOCKPLUSIsEnabledMessage fromList:list] : nil;
}
- (NSArray<id> *)toList {
  return @[
    self.enabled ?: [NSNull null],
  ];
}
@end

@interface WAKELOCKPLUSMessagesPigeonCodecReader : FlutterStandardReader
@end
@implementation WAKELOCKPLUSMessagesPigeonCodecReader
- (nullable id)readValueOfType:(UInt8)type {
  switch (type) {
    case 129: 
      return [WAKELOCKPLUSToggleMessage fromList:[self readValue]];
    case 130: 
      return [WAKELOCKPLUSIsEnabledMessage fromList:[self readValue]];
    default:
      return [super readValueOfType:type];
  }
}
@end

@interface WAKELOCKPLUSMessagesPigeonCodecWriter : FlutterStandardWriter
@end
@implementation WAKELOCKPLUSMessagesPigeonCodecWriter
- (void)writeValue:(id)value {
  if ([value isKindOfClass:[WAKELOCKPLUSToggleMessage class]]) {
    [self writeByte:129];
    [self writeValue:[value toList]];
  } else if ([value isKindOfClass:[WAKELOCKPLUSIsEnabledMessage class]]) {
    [self writeByte:130];
    [self writeValue:[value toList]];
  } else {
    [super writeValue:value];
  }
}
@end

@interface WAKELOCKPLUSMessagesPigeonCodecReaderWriter : FlutterStandardReaderWriter
@end
@implementation WAKELOCKPLUSMessagesPigeonCodecReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
  return [[WAKELOCKPLUSMessagesPigeonCodecWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
  return [[WAKELOCKPLUSMessagesPigeonCodecReader alloc] initWithData:data];
}
@end

NSObject<FlutterMessageCodec> *WAKELOCKPLUSGetMessagesCodec(void) {
  static FlutterStandardMessageCodec *sSharedObject = nil;
  static dispatch_once_t sPred = 0;
  dispatch_once(&sPred, ^{
    WAKELOCKPLUSMessagesPigeonCodecReaderWriter *readerWriter = [[WAKELOCKPLUSMessagesPigeonCodecReaderWriter alloc] init];
    sSharedObject = [FlutterStandardMessageCodec codecWithReaderWriter:readerWriter];
  });
  return sSharedObject;
}
void SetUpWAKELOCKPLUSWakelockPlusApi(id<FlutterBinaryMessenger> binaryMessenger, NSObject<WAKELOCKPLUSWakelockPlusApi> *api) {
  SetUpWAKELOCKPLUSWakelockPlusApiWithSuffix(binaryMessenger, api, @"");
}

void SetUpWAKELOCKPLUSWakelockPlusApiWithSuffix(id<FlutterBinaryMessenger> binaryMessenger, NSObject<WAKELOCKPLUSWakelockPlusApi> *api, NSString *messageChannelSuffix) {
  messageChannelSuffix = messageChannelSuffix.length > 0 ? [NSString stringWithFormat: @".%@", messageChannelSuffix] : @"";
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:WAKELOCKPLUSGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(toggleMsg:error:)], @"WAKELOCKPLUSWakelockPlusApi api (%@) doesn't respond to @selector(toggleMsg:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray<id> *args = message;
        WAKELOCKPLUSToggleMessage *arg_msg = GetNullableObjectAtIndex(args, 0);
        FlutterError *error;
        [api toggleMsg:arg_msg error:&error];
        callback(wrapResult(nil, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.isEnabled", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:WAKELOCKPLUSGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(isEnabledWithError:)], @"WAKELOCKPLUSWakelockPlusApi api (%@) doesn't respond to @selector(isEnabledWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        WAKELOCKPLUSIsEnabledMessage *output = [api isEnabledWithError:&error];
        callback(wrapResult(output, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
}
