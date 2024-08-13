// Autogenerated from Pigeon (v21.2.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#import "messages.g.h"

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

@interface FLTToggleMessage ()
+ (FLTToggleMessage *)fromList:(NSArray<id> *)list;
+ (nullable FLTToggleMessage *)nullableFromList:(NSArray<id> *)list;
- (NSArray<id> *)toList;
@end

@interface FLTIsEnabledMessage ()
+ (FLTIsEnabledMessage *)fromList:(NSArray<id> *)list;
+ (nullable FLTIsEnabledMessage *)nullableFromList:(NSArray<id> *)list;
- (NSArray<id> *)toList;
@end

@implementation FLTToggleMessage
+ (instancetype)makeWithEnable:(nullable NSNumber *)enable {
  FLTToggleMessage* pigeonResult = [[FLTToggleMessage alloc] init];
  pigeonResult.enable = enable;
  return pigeonResult;
}
+ (FLTToggleMessage *)fromList:(NSArray<id> *)list {
  FLTToggleMessage *pigeonResult = [[FLTToggleMessage alloc] init];
  pigeonResult.enable = GetNullableObjectAtIndex(list, 0);
  return pigeonResult;
}
+ (nullable FLTToggleMessage *)nullableFromList:(NSArray<id> *)list {
  return (list) ? [FLTToggleMessage fromList:list] : nil;
}
- (NSArray<id> *)toList {
  return @[
    self.enable ?: [NSNull null],
  ];
}
@end

@implementation FLTIsEnabledMessage
+ (instancetype)makeWithEnabled:(nullable NSNumber *)enabled {
  FLTIsEnabledMessage* pigeonResult = [[FLTIsEnabledMessage alloc] init];
  pigeonResult.enabled = enabled;
  return pigeonResult;
}
+ (FLTIsEnabledMessage *)fromList:(NSArray<id> *)list {
  FLTIsEnabledMessage *pigeonResult = [[FLTIsEnabledMessage alloc] init];
  pigeonResult.enabled = GetNullableObjectAtIndex(list, 0);
  return pigeonResult;
}
+ (nullable FLTIsEnabledMessage *)nullableFromList:(NSArray<id> *)list {
  return (list) ? [FLTIsEnabledMessage fromList:list] : nil;
}
- (NSArray<id> *)toList {
  return @[
    self.enabled ?: [NSNull null],
  ];
}
@end

@interface FLTMessagesPigeonCodecReader : FlutterStandardReader
@end
@implementation FLTMessagesPigeonCodecReader
- (nullable id)readValueOfType:(UInt8)type {
  switch (type) {
    case 129: 
      return [FLTToggleMessage fromList:[self readValue]];
    case 130: 
      return [FLTIsEnabledMessage fromList:[self readValue]];
    default:
      return [super readValueOfType:type];
  }
}
@end

@interface FLTMessagesPigeonCodecWriter : FlutterStandardWriter
@end
@implementation FLTMessagesPigeonCodecWriter
- (void)writeValue:(id)value {
  if ([value isKindOfClass:[FLTToggleMessage class]]) {
    [self writeByte:129];
    [self writeValue:[value toList]];
  } else if ([value isKindOfClass:[FLTIsEnabledMessage class]]) {
    [self writeByte:130];
    [self writeValue:[value toList]];
  } else {
    [super writeValue:value];
  }
}
@end

@interface FLTMessagesPigeonCodecReaderWriter : FlutterStandardReaderWriter
@end
@implementation FLTMessagesPigeonCodecReaderWriter
- (FlutterStandardWriter *)writerWithData:(NSMutableData *)data {
  return [[FLTMessagesPigeonCodecWriter alloc] initWithData:data];
}
- (FlutterStandardReader *)readerWithData:(NSData *)data {
  return [[FLTMessagesPigeonCodecReader alloc] initWithData:data];
}
@end

NSObject<FlutterMessageCodec> *FLTGetMessagesCodec(void) {
  static FlutterStandardMessageCodec *sSharedObject = nil;
  static dispatch_once_t sPred = 0;
  dispatch_once(&sPred, ^{
    FLTMessagesPigeonCodecReaderWriter *readerWriter = [[FLTMessagesPigeonCodecReaderWriter alloc] init];
    sSharedObject = [FlutterStandardMessageCodec codecWithReaderWriter:readerWriter];
  });
  return sSharedObject;
}
void SetUpFLTWakelockPlusApi(id<FlutterBinaryMessenger> binaryMessenger, NSObject<FLTWakelockPlusApi> *api) {
  SetUpFLTWakelockPlusApiWithSuffix(binaryMessenger, api, @"");
}

void SetUpFLTWakelockPlusApiWithSuffix(id<FlutterBinaryMessenger> binaryMessenger, NSObject<FLTWakelockPlusApi> *api, NSString *messageChannelSuffix) {
  messageChannelSuffix = messageChannelSuffix.length > 0 ? [NSString stringWithFormat: @".%@", messageChannelSuffix] : @"";
  {
    FlutterBasicMessageChannel *channel =
      [[FlutterBasicMessageChannel alloc]
        initWithName:[NSString stringWithFormat:@"%@%@", @"dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle", messageChannelSuffix]
        binaryMessenger:binaryMessenger
        codec:FLTGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(toggleMsg:error:)], @"FLTWakelockPlusApi api (%@) doesn't respond to @selector(toggleMsg:error:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        NSArray<id> *args = message;
        FLTToggleMessage *arg_msg = GetNullableObjectAtIndex(args, 0);
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
        codec:FLTGetMessagesCodec()];
    if (api) {
      NSCAssert([api respondsToSelector:@selector(isEnabledWithError:)], @"FLTWakelockPlusApi api (%@) doesn't respond to @selector(isEnabledWithError:)", api);
      [channel setMessageHandler:^(id _Nullable message, FlutterReply callback) {
        FlutterError *error;
        FLTIsEnabledMessage *output = [api isEnabledWithError:&error];
        callback(wrapResult(output, error));
      }];
    } else {
      [channel setMessageHandler:nil];
    }
  }
}
