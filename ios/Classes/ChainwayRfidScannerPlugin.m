#import "ChainwayRfidScannerPlugin.h"
#import "Vendor/RFIDBlutoothManager.h"

typedef NS_ENUM(NSInteger, ChainwayStreamKind) {
  ChainwayStreamKindInventory,
  ChainwayStreamKindDiscovery,
};

@class ChainwayRfidScannerPlugin;

@interface ChainwayStreamHandler : NSObject <FlutterStreamHandler>

- (instancetype)initWithPlugin:(ChainwayRfidScannerPlugin *)plugin
                           kind:(ChainwayStreamKind)kind;

@end

@interface ChainwayRfidScannerPlugin () <FatScaleBluetoothManager>

@property(nonatomic, strong) RFIDBlutoothManager *reader;
@property(nonatomic, strong) NSMutableDictionary<NSString *, BLEModel *> *devices;
@property(nonatomic, strong)
    NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, id> *> *tags;
@property(nonatomic, copy, nullable) FlutterEventSink inventorySink;
@property(nonatomic, copy, nullable) FlutterEventSink discoverySink;
@property(nonatomic, copy, nullable) FlutterResult pendingConnectResult;
@property(nonatomic, copy, nullable) FlutterResult pendingDisconnectResult;
@property(nonatomic, copy, nullable) FlutterResult pendingSetPowerResult;
@property(nonatomic, copy, nullable) FlutterResult pendingGetPowerResult;
@property(nonatomic, copy) NSString *connectionState;
@property(nonatomic, copy) NSString *scanMode;
@property(nonatomic, assign) BOOL inventoryEmissionScheduled;
@property(nonatomic, assign) NSInteger connectionGeneration;
@property(nonatomic, strong) ChainwayStreamHandler *inventoryStreamHandler;
@property(nonatomic, strong) ChainwayStreamHandler *discoveryStreamHandler;

- (FlutterError *_Nullable)listenToStream:(ChainwayStreamKind)kind
                                eventSink:(FlutterEventSink)events;
- (FlutterError *_Nullable)cancelStream:(ChainwayStreamKind)kind;

@end

@implementation ChainwayStreamHandler {
  __weak ChainwayRfidScannerPlugin *_plugin;
  ChainwayStreamKind _kind;
}

- (instancetype)initWithPlugin:(ChainwayRfidScannerPlugin *)plugin
                           kind:(ChainwayStreamKind)kind {
  self = [super init];
  if (self) {
    _plugin = plugin;
    _kind = kind;
  }
  return self;
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
  return [_plugin listenToStream:_kind eventSink:events];
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  return [_plugin cancelStream:_kind];
}

@end

@implementation ChainwayRfidScannerPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"chainway_rfid_scanner"
            binaryMessenger:[registrar messenger]];
  ChainwayRfidScannerPlugin *instance = [[ChainwayRfidScannerPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];

  instance.inventoryStreamHandler = [[ChainwayStreamHandler alloc]
      initWithPlugin:instance
                kind:ChainwayStreamKindInventory];
  FlutterEventChannel *inventoryChannel = [FlutterEventChannel
      eventChannelWithName:@"performChainwayInventory"
           binaryMessenger:[registrar messenger]];
  [inventoryChannel setStreamHandler:instance.inventoryStreamHandler];

  instance.discoveryStreamHandler = [[ChainwayStreamHandler alloc]
      initWithPlugin:instance
                kind:ChainwayStreamKindDiscovery];
  FlutterEventChannel *discoveryChannel = [FlutterEventChannel
      eventChannelWithName:@"discoverChainwayReaders"
           binaryMessenger:[registrar messenger]];
  [discoveryChannel setStreamHandler:instance.discoveryStreamHandler];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _devices = [NSMutableDictionary dictionary];
    _tags = [NSMutableDictionary dictionary];
    _connectionState = @"Disconnected";
    _scanMode = @"auto";
    [self ensureReader];
  }
  return self;
}

- (void)ensureReader {
  if (self.reader == nil) {
    self.reader = [RFIDBlutoothManager shareManager];
  }
  [self.reader setFatScaleBluetoothDelegate:self];
}

- (FlutterError *_Nullable)listenToStream:(ChainwayStreamKind)kind
                                eventSink:(FlutterEventSink)events {
  [self ensureReader];
  if (kind == ChainwayStreamKindInventory) {
    self.inventorySink = events;
    [self emitInventory];
  } else {
    self.discoverySink = events;
    [self emitDevices];
    [self.reader startBleScan];
  }
  return nil;
}

- (FlutterError *_Nullable)cancelStream:(ChainwayStreamKind)kind {
  if (kind == ChainwayStreamKindInventory) {
    self.inventorySink = nil;
  } else {
    self.discoverySink = nil;
    [self.reader stopBleScan];
  }
  return nil;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getPlatformVersion" isEqualToString:call.method]) {
    result([@"iOS " stringByAppendingString:[[UIDevice currentDevice] systemVersion]]);
  } else if ([@"initReader" isEqualToString:call.method]) {
    [self ensureReader];
    result(@"Reader initialized");
  } else if ([@"startDiscovery" isEqualToString:call.method]) {
    [self ensureReader];
    [self.reader startBleScan];
    result(@YES);
  } else if ([@"stopDiscovery" isEqualToString:call.method]) {
    [self.reader stopBleScan];
    result(@YES);
  } else if ([@"connect" isEqualToString:call.method]) {
    [self connectWithCall:call result:result];
  } else if ([@"disconnect" isEqualToString:call.method]) {
    [self disconnectWithResult:result];
  } else if ([@"getConnectState" isEqualToString:call.method]) {
    if (self.reader.connectDevice) {
      self.connectionState = @"Connected";
    }
    result(self.connectionState);
  } else if ([@"startInventory" isEqualToString:call.method]) {
    if (![self requireConnection:result]) {
      return;
    }
    [self.tags removeAllObjects];
    [self emitInventory];
    [self.reader startInventory];
    result(@YES);
  } else if ([@"stopInventory" isEqualToString:call.method]) {
    if (![self requireConnection:result]) {
      return;
    }
    [self.reader stopInventory];
    result(@YES);
  } else if ([@"clearInventory" isEqualToString:call.method]) {
    [self.tags removeAllObjects];
    [self emitInventory];
    result(@"ListItem cleared");
  } else if ([@"setScanMode" isEqualToString:call.method]) {
    NSDictionary *arguments = [call.arguments isKindOfClass:[NSDictionary class]]
                                  ? call.arguments
                                  : @{};
    NSString *mode = arguments[@"scanMode"];
    if (![mode isEqualToString:@"auto"] && ![mode isEqualToString:@"single"]) {
      result(@NO);
      return;
    }
    self.scanMode = mode;
    result(@YES);
  } else if ([@"setScanPower" isEqualToString:call.method]) {
    [self setPowerWithCall:call result:result];
  } else if ([@"getScanPower" isEqualToString:call.method]) {
    [self getPowerWithResult:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)connectWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  NSDictionary *arguments = [call.arguments isKindOfClass:[NSDictionary class]]
                                ? call.arguments
                                : @{};
  NSString *deviceID = arguments[@"address"];
  if (![deviceID isKindOfClass:[NSString class]] || deviceID.length == 0) {
    result([FlutterError errorWithCode:@"invalid_device_id"
                               message:@"A discovered R2 device id is required."
                               details:nil]);
    return;
  }
  if (self.pendingConnectResult != nil) {
    result([FlutterError errorWithCode:@"connection_in_progress"
                               message:@"A reader connection is already in progress."
                               details:nil]);
    return;
  }

  BLEModel *device = self.devices[deviceID];
  if (device == nil) {
    for (BLEModel *candidate in self.devices.allValues) {
      if ([candidate.addressStr isEqualToString:deviceID] ||
          [candidate.nameStr isEqualToString:deviceID]) {
        device = candidate;
        break;
      }
    }
  }
  if (device == nil) {
    result([FlutterError errorWithCode:@"reader_not_found"
                               message:@"Discover the R2 before connecting."
                               details:deviceID]);
    return;
  }

  [self.reader stopBleScan];
  self.connectionState = @"Connecting";
  self.pendingConnectResult = result;
  NSInteger generation = ++self.connectionGeneration;
  [self.reader connectPeripheral:device.peripheral macAddress:device.addressStr];

  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil || generation != strongSelf.connectionGeneration ||
        strongSelf.pendingConnectResult == nil) {
      return;
    }
    FlutterResult pending = strongSelf.pendingConnectResult;
    strongSelf.pendingConnectResult = nil;
    strongSelf.connectionState = @"Disconnected";
    [strongSelf.reader cancelConnectBLE];
    pending(@NO);
  });
}

- (void)disconnectWithResult:(FlutterResult)result {
  if (self.pendingDisconnectResult != nil) {
    result([FlutterError errorWithCode:@"disconnect_in_progress"
                               message:@"A disconnect is already in progress."
                               details:nil]);
    return;
  }
  self.connectionGeneration++;
  if (self.pendingConnectResult != nil) {
    FlutterResult pendingConnect = self.pendingConnectResult;
    self.pendingConnectResult = nil;
    pendingConnect(@NO);
  }
  if (!self.reader.connectDevice) {
    self.connectionState = @"Disconnected";
    result(@YES);
    return;
  }

  if (self.reader.isgetLab) {
    [self.reader stopInventory];
  }
  self.pendingDisconnectResult = result;
  [self.reader cancelConnectBLE];

  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil || strongSelf.pendingDisconnectResult == nil) {
      return;
    }
    FlutterResult pending = strongSelf.pendingDisconnectResult;
    strongSelf.pendingDisconnectResult = nil;
    BOOL disconnected = !strongSelf.reader.connectDevice;
    if (disconnected) {
      strongSelf.connectionState = @"Disconnected";
    }
    pending(disconnected ? @YES : @NO);
  });
}

- (void)setPowerWithCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if (![self requireConnection:result]) {
    return;
  }
  NSDictionary *arguments = [call.arguments isKindOfClass:[NSDictionary class]]
                                ? call.arguments
                                : @{};
  NSNumber *power = arguments[@"scanPower"];
  if (![power isKindOfClass:[NSNumber class]] ||
      power.integerValue < 1 || power.integerValue > 30) {
    result([FlutterError errorWithCode:@"invalid_power"
                               message:@"R2 scan power must be between 1 and 30 dBm."
                               details:power]);
    return;
  }
  if (self.pendingSetPowerResult != nil) {
    result([FlutterError errorWithCode:@"power_request_in_progress"
                               message:@"Another set-power request is in progress."
                               details:nil]);
    return;
  }
  self.pendingSetPowerResult = result;
  NSString *value = power.stringValue;
  [self.reader setLaunchPowerWithstatus:@"1"
                                antenna:@"1"
                                readStr:value
                               writeStr:value];
  [self schedulePowerTimeoutForSetter:YES];
}

- (void)getPowerWithResult:(FlutterResult)result {
  if (![self requireConnection:result]) {
    return;
  }
  if (self.pendingGetPowerResult != nil) {
    result([FlutterError errorWithCode:@"power_request_in_progress"
                               message:@"Another get-power request is in progress."
                               details:nil]);
    return;
  }
  self.pendingGetPowerResult = result;
  [self.reader getLaunchPower];
  [self schedulePowerTimeoutForSetter:NO];
}

- (void)schedulePowerTimeoutForSetter:(BOOL)isSetter {
  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    FlutterResult pending =
        isSetter ? strongSelf.pendingSetPowerResult
                 : strongSelf.pendingGetPowerResult;
    if (pending == nil) {
      return;
    }
    if (isSetter) {
      strongSelf.pendingSetPowerResult = nil;
    } else {
      strongSelf.pendingGetPowerResult = nil;
    }
    pending([FlutterError errorWithCode:@"reader_timeout"
                                message:@"The R2 did not answer the power request."
                                details:nil]);
  });
}

- (BOOL)requireConnection:(FlutterResult)result {
  if (self.reader.connectDevice) {
    return YES;
  }
  result([FlutterError errorWithCode:@"not_connected"
                             message:@"Connect to an R2 reader first."
                             details:nil]);
  return NO;
}

- (void)emitDevices {
  if (self.discoverySink == nil) {
    return;
  }
  NSArray<BLEModel *> *models = [self.devices.allValues
      sortedArrayUsingComparator:^NSComparisonResult(BLEModel *left,
                                                     BLEModel *right) {
    NSComparisonResult nameResult =
        [left.nameStr compare:right.nameStr options:NSCaseInsensitiveSearch];
    if (nameResult != NSOrderedSame) {
      return nameResult;
    }
    return [left.peripheral.identifier.UUIDString
        compare:right.peripheral.identifier.UUIDString];
  }];
  NSMutableArray<NSDictionary<NSString *, id> *> *payload =
      [NSMutableArray arrayWithCapacity:models.count];
  for (BLEModel *model in models) {
    [payload addObject:@{
      @"id" : model.peripheral.identifier.UUIDString ?: @"",
      @"name" : model.nameStr ?: @"Unknown R2",
      @"address" : model.addressStr ?: @"",
      @"rssi" : @([model.rssStr integerValue]),
    }];
  }
  self.discoverySink(payload);
}

- (void)scheduleInventoryEmission {
  if (self.inventoryEmissionScheduled) {
    return;
  }
  self.inventoryEmissionScheduled = YES;
  __weak typeof(self) weakSelf = self;
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                 dispatch_get_main_queue(), ^{
    typeof(self) strongSelf = weakSelf;
    if (strongSelf == nil) {
      return;
    }
    strongSelf.inventoryEmissionScheduled = NO;
    [strongSelf emitInventory];
  });
}

- (void)emitInventory {
  if (self.inventorySink == nil) {
    return;
  }
  NSArray<NSDictionary<NSString *, id> *> *values = [self.tags.allValues
      sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *left,
                                                     NSDictionary *right) {
    return [left[@"epc"] compare:right[@"epc"]];
  }];
  NSMutableArray<NSDictionary<NSString *, id> *> *payload =
      [NSMutableArray arrayWithCapacity:values.count];
  for (NSDictionary<NSString *, id> *tag in values) {
    [payload addObject:[tag copy]];
  }
  self.inventorySink(payload);
}

#pragma mark - Chainway SDK delegates

- (void)receiveDataWithBLEmodel:(BLEModel *)model result:(NSString *)result {
  if (model != nil && [result isEqualToString:@"0"]) {
    NSString *identifier = model.peripheral.identifier.UUIDString;
    if (identifier.length > 0) {
      self.devices[identifier] = model;
    }
  }
  [self emitDevices];
}

- (void)connectPeripheralSuccess:(NSString *)nameStr {
  self.connectionState = @"Connected";
  self.connectionGeneration++;
  if (self.pendingConnectResult != nil) {
    FlutterResult pending = self.pendingConnectResult;
    self.pendingConnectResult = nil;
    pending(@YES);
  }
}

- (void)disConnectPeripheral {
  self.connectionState = @"Disconnected";
  self.connectionGeneration++;
  if (self.pendingConnectResult != nil) {
    FlutterResult pendingConnect = self.pendingConnectResult;
    self.pendingConnectResult = nil;
    pendingConnect(@NO);
  }
  if (self.pendingDisconnectResult != nil) {
    FlutterResult pendingDisconnect = self.pendingDisconnectResult;
    self.pendingDisconnectResult = nil;
    pendingDisconnect(@YES);
  }
}

- (void)connectBluetoothFailWithMessage:(NSString *)msg {
  self.connectionState = @"Undetected";
  if (self.pendingConnectResult != nil) {
    FlutterResult pending = self.pendingConnectResult;
    self.pendingConnectResult = nil;
    self.connectionGeneration++;
    pending(@NO);
  }
  if (self.discoverySink != nil) {
    self.discoverySink(
        [FlutterError errorWithCode:@"bluetooth_unavailable"
                            message:msg ?: @"Bluetooth is unavailable."
                            details:nil]);
  }
}

- (void)connectBluetoothTimeout {
  if (self.pendingConnectResult != nil) {
    FlutterResult pending = self.pendingConnectResult;
    self.pendingConnectResult = nil;
    self.connectionState = @"Disconnected";
    self.connectionGeneration++;
    pending(@NO);
  }
}

- (void)rfidTagInfoCallback:(UHFTagInfo *)tag {
  if (tag.epc.length == 0) {
    return;
  }
  NSString *key =
      [NSString stringWithFormat:@"%@|%@", tag.epc, tag.tid ?: @""];
  NSMutableDictionary<NSString *, id> *existing = self.tags[key];
  NSInteger readCount = [existing[@"readCount"] integerValue] + 1;
  if (existing == nil) {
    existing = [NSMutableDictionary dictionary];
    self.tags[key] = existing;
    readCount = 1;
  }
  existing[@"epc"] = tag.epc;
  existing[@"tid"] = tag.tid ?: @"";
  existing[@"user"] = tag.user ?: @"";
  existing[@"pc"] = tag.pc ?: @"";
  existing[@"rssi"] = @([tag.rssi integerValue]);
  existing[@"readCount"] = @(readCount);
  existing[@"info"] = tag.rssi ?: @"";
  existing[@"dupCount"] = [NSString stringWithFormat:@"%ld", (long)readCount];
  [self scheduleInventoryEmission];
}

- (void)rfidConfigCallback:(NSString *)data function:(int)function {
  if (function == 0x11 && self.pendingSetPowerResult != nil) {
    FlutterResult pending = self.pendingSetPowerResult;
    self.pendingSetPowerResult = nil;
    pending(data.integerValue == 1 ? @YES : @NO);
    return;
  }
  if (function == 0x13 && self.pendingGetPowerResult != nil) {
    FlutterResult pending = self.pendingGetPowerResult;
    self.pendingGetPowerResult = nil;
    pending(@(data.integerValue));
    return;
  }
  if (function != 0xE6 || !self.reader.connectDevice) {
    return;
  }

  NSInteger keyCode = data.integerValue;
  if ([self.scanMode isEqualToString:@"single"]) {
    if (keyCode == 1 || keyCode == 2 || keyCode == 3) {
      [self.reader singleInventory];
    }
    return;
  }

  if (keyCode == 1 || keyCode == 2) {
    if (self.reader.isgetLab) {
      [self.reader stopInventory];
    } else {
      [self.tags removeAllObjects];
      [self emitInventory];
      [self.reader startInventory];
    }
  } else if (keyCode == 3) {
    if (!self.reader.isgetLab) {
      [self.tags removeAllObjects];
      [self emitInventory];
      [self.reader startInventory];
    }
  } else if (keyCode == 4 && self.reader.isgetLab) {
    [self.reader stopInventory];
  }
}

+ (void)detachFromEngineForRegistrar:
    (NSObject<FlutterPluginRegistrar> *)registrar {
  // Instance cleanup is driven by stream cancellation and explicit disconnect.
}

@end
