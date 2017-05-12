//
//  Weex-BluetoothModule.m
//  testWeex
//
//  Created by 李 行 on 08/05/2017.
//  Copyright © 2017 lixing123.com. All rights reserved.
//

#import "Weex_BluetoothModule.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface Weex_BluetoothModule ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic, strong)CBCentralManager *central;
@property(nonatomic, strong)NSMutableArray<CBPeripheral *>* devicesArray;
@property(nonatomic, strong)CBPeripheral *connectedDevice;
@property(nonatomic, strong)WXModuleKeepAliveCallback onOpenBluetoothAdapterFinishCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onBluetoothStateChangeCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onFoundBLEDeviceCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onDeviceConnectedCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onDeviceDisconnnectedCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onFoundServicesCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onFoundCharacteristicsCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onBLECharacteristicValueChangeCallback;

@end

#pragma mark TODO defines adapter state object.
#pragma mark TODO defines device object.
#pragma mark TODO defines service object.
#pragma mark TODO defines characteristic object.

@implementation Weex_BluetoothModule

@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(openBluetoothAdapter:))
WX_EXPORT_METHOD(@selector(closeBluetoothAdapter:))
WX_EXPORT_METHOD(@selector(getBluetoothAdapterState:))
WX_EXPORT_METHOD(@selector(onBluetoothAdapterStateChange:))
WX_EXPORT_METHOD(@selector(startBluetoothDevicesDiscoveryWithServices:callback:))
WX_EXPORT_METHOD(@selector(stopBluetoothDeviceDiscovery:))
WX_EXPORT_METHOD(@selector(getBluetoothDevicesWithServices:callback:))
WX_EXPORT_METHOD(@selector(getConnectedBluetoothDevicesWithServices:callback:))
WX_EXPORT_METHOD(@selector(onBluetoothDeviceFound:))
WX_EXPORT_METHOD(@selector(createBLEConnectionWithDeviceID:callback:))
WX_EXPORT_METHOD(@selector(closeBLEConnectionWithDeviceID:callback:))
WX_EXPORT_METHOD(@selector(getBLEDeviceServicesWithDeviceID:callback:))
WX_EXPORT_METHOD(@selector(getBLEDeviceCharacteristicsWithDeviceID:serviceID:callback:))
WX_EXPORT_METHOD(@selector(readBLECharacteristicValueWithDeviceID:serviceID:characteristicID:callback:))
WX_EXPORT_METHOD(@selector(writeBLECharacteristicValueWithDeviceID:serviceID:characteristicID:value:callback:))
WX_EXPORT_METHOD(@selector(notifyBLECharacteristicValueChangeWithDeviceID:servieID:characteristicID:state:callback:))
WX_EXPORT_METHOD(@selector(onBLECharacteristicValueChange:))
WX_EXPORT_METHOD(@selector(onBLEConnectionStateChange:))

- (id)init {
    self = [super init];
    
    self.devicesArray = [[NSMutableArray alloc] init];
    
    return self;
}

/**
 Initialize the bluetooth adapter.

 @param callback Callback to return weex result when completed; contains dictionary. Detailed as documents described.
*/
- (void)openBluetoothAdapter:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    if (!self.central) {
        self.central = [[CBCentralManager alloc] initWithDelegate:self queue:NULL];
    }
    
    self.onOpenBluetoothAdapterFinishCallback = callback;
}


/**
 Close the bluetooth adapter; this will disconnect all connections and release all resources.

 @param callback Callback to return weex result when completed; contains dictionary. Detailed as documents described.
 */
- (void)closeBluetoothAdapter:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    self.central.delegate = nil;
    self.central = nil;
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED};
    callback(resultDict);
}

/**
 Get the state of current adapter, whether is available, and whether is discovering devices.

 @param callback Callback to return weex result when completed; contains dictionary. Detailed as documents described.
 */
- (void)getBluetoothAdapterState:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    
    BOOL discovering = self.central.isScanning;
    BOOL available = (self.central.state == CBManagerStatePoweredOn);
    NSDictionary *adapterStateDict = @{@"discovering":@(discovering),
                                   @"available":@(available)};
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED,
                                 @"adapterState":adapterStateDict};
    callback(resultDict);
}

/**
 When the state of the adapter changes, such as avability or state of discovery, this will be triggered.

 @param callback Callback to return weex result when completed; contains dictionary. Detailed as documents described.
 */
- (void)onBluetoothAdapterStateChange:(WXModuleKeepAliveCallback)callback {
    self.onBluetoothStateChangeCallback = callback;
}

/**
 Start to scan bluetooth devices.

 @param servicesArray Only scan devices that are advertising any of the specific services. NULL if scan all devices.
 @param callback Callback to return weex result when completed; contains dictionary. Detailed as documents described.
 */
- (void)startBluetoothDevicesDiscoveryWithServices:(NSArray *)servicesArray callback:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    NSMutableArray *uuidArray = [[NSMutableArray alloc] init];
    for (NSString *serviceString in servicesArray) {
        [uuidArray addObject:[CBUUID UUIDWithString:serviceString]];
    }
    [self.central scanForPeripheralsWithServices:uuidArray options:nil];
    
    self.onFoundBLEDeviceCallback = callback;
}

/**
 stop scanning bluetooth devices
 */
- (void)stopBluetoothDeviceDiscovery:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    
    [self.central stopScan];
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED};
    callback(resultDict);
}

/**
 Get all discovered devices, including devices connected to the manager.

 @param servicesArray If not null, only devices with one of the specific services will be returned.
 @param callback <#callback description#>
 */
- (void)getBluetoothDevicesWithServices:(NSArray<NSString *> *)servicesArray callback:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    
    NSMutableArray<NSUUID *> *uuidArray = [[NSMutableArray alloc] init];
    for (NSString *uuidString in servicesArray) {
        //TODO: this will cause app crash
        [uuidArray addObject:[[NSUUID alloc] initWithUUIDString:uuidString]];
    }
    NSArray *peripheralsArray = [self.central retrievePeripheralsWithIdentifiers:uuidArray];
    NSMutableArray *resultDeviceIDArray = [[NSMutableArray alloc] init];
    for (CBPeripheral *peripheral in peripheralsArray) {
        NSString *identifier = peripheral.identifier.UUIDString;
        [resultDeviceIDArray addObject:identifier];
    }
    
    callback(resultDeviceIDArray);
}

/**
 Get connected devices.

 @param servicesArray If no null, only devices with specific services will be returned.
 @param callback <#callback description#>
 */
- (void)getConnectedBluetoothDevicesWithServices:(NSArray *)servicesArray callback:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
}

/**
 When new device found, this will trigered.
 
 @param callback <#callback description#>
 */
//TODO: this may be useless
- (void)onBluetoothDeviceFound:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
}

/**
 try connecting to a BLE device.

 @param deviceID The ID of the BLE device.
 @param callback <#callback description#>
 */
- (void)createBLEConnectionWithDeviceID:(NSString *)deviceID callback:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    CBPeripheral *peripheral;
    for (CBPeripheral *tempPeripheral in self.devicesArray) {
        if ([tempPeripheral.identifier.UUIDString isEqualToString:deviceID]) {
            peripheral = tempPeripheral;
        }
    }
    
    self.onDeviceConnectedCallback = callback;
    [self.central connectPeripheral:peripheral options:nil];
}

/**
 Try disconnecting with connected device

 @param deviceID The ID of the BLE device.
 @param callback <#callback description#>
 */
- (void)closeBLEConnectionWithDeviceID:(NSString *)deviceID callback:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    CBPeripheral *peripheral;
    for (CBPeripheral *tempDevice in self.devicesArray) {
        if ([tempDevice.identifier.UUIDString isEqualToString:deviceID]) {
            peripheral = tempDevice;
        }
    }
    
    self.onDeviceDisconnnectedCallback = callback;
    [self.central cancelPeripheralConnection:peripheral];
}

/**
 Get services of a BLE device.

 @param deviceID The ID of the BLE device.
 @param callback <#callback description#>
 */
- (void)getBLEDeviceServicesWithDeviceID:(NSString *)deviceID callback:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    if ([self.connectedDevice.identifier.UUIDString isEqualToString:deviceID]) {
        self.onFoundServicesCallback = callback;
        [self.connectedDevice discoverServices:nil];
    }
}

/**
 Get the characteristics of a service of a BLE device.

 @param deviceID The ID of the BLE device.
 @param serviceID The service ID  you want to find characteristics of.
 @param callback <#callback description#>
 */
- (void)getBLEDeviceCharacteristicsWithDeviceID:(NSString *)deviceID serviceID:(NSString *)serviceID callback:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    if ([self.connectedDevice.identifier.UUIDString isEqualToString:deviceID]) {
        //find corresponding service
        CBService *service;
        for (CBService *tmpService in self.connectedDevice.services) {
            if ([tmpService.UUID.UUIDString isEqualToString:serviceID]) {
                service = tmpService;
            }
        }
        
        if (service) {
            //TODO: onFoundCharacteristicsCallback shall be called based on corresponding service
            self.onFoundCharacteristicsCallback = callback;
            [self.connectedDevice discoverCharacteristics:nil forService:service];
        }
    }
}

/**
 Read value of a characteristic

 @param deviceID The ID of the BLE device.
 @param serviceID The service ID to which the characteristic belongs.
 @param characteristicID The characteristic ID from which you want to read.
 @param callback <#callback description#>
 @discussion Note that this characteristic should be readable.
 */
- (void)readBLECharacteristicValueWithDeviceID:(NSString *)deviceID serviceID:(NSString *)serviceID characteristicID:(NSString *)characteristicID callback:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
}

/**
 Write value to a characteristic

 @param deviceID The ID of the BLE device.
 @param serviceID The service ID to which the characteristic belongs.
 @param characteristicID The characteristic ID from which you want to read.
 @param value The value that you want write to the characteristic.
 @param callback callback description
 @discussion 
    Note that this characteristic should be writable.
    Since only strings can be transferred, the format of String will be converted to NSData based on ASCII code. For example, the string "5A" will be converted to NSData with content {00000101 01000001};
    value must only contains characters from "0" to "9" and from "A" to "F"(upper case); length of value must be even
 @seealso ...
 */
- (void)writeBLECharacteristicValueWithDeviceID:(NSString *)deviceID serviceID:(NSString *)serviceID characteristicID:(NSString *)characteristicID value:(NSString *)value callback:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    
    NSData *data = [self stringToData:value];
    
    if (![self.connectedDevice.identifier.UUIDString isEqualToString:deviceID]) {
        return;
    }
    
    //find corresponding CBService
    CBService *service;
    for (CBService *tmpService in self.connectedDevice.services) {
        if ([tmpService.UUID.UUIDString isEqualToString:serviceID]) {
            service = tmpService;
        }
    }
    if (!service) {
        return;
    }
    
    //find corresponding CBCharacteristic
    CBCharacteristic *characteristic;
    for (CBCharacteristic *tmpCharacteristic in service.characteristics) {
        if ([tmpCharacteristic.UUID.UUIDString isEqualToString:characteristicID]) {
            characteristic = tmpCharacteristic;
        }
    }
    if (!characteristic) {
        return;
    }
    
    [self.connectedDevice writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithoutResponse];
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED};
    callback(resultDict);
}

- (NSData *)stringToData:(NSString *)string {
    NSMutableData *data = [[NSMutableData alloc] init];
    for (int i=0; i<string.length; i=i+2) {
        char character1 = [string characterAtIndex:i];
        int value1 = 0;
        if (character1 >= '0' && character1 <= '9') {
            value1 = character1 - 48;
        }else if (character1 >= 'A' && character1 <= 'F') {
            value1 = character1 - 55;
        }
        
        char character2 = [string characterAtIndex:i+1];
        int value2 = 0;
        if (character2 >= '0' && character2 <= '9') {
            value2 = character2 - 48;
        }else if (character2 >= 'A' && character2 <= 'F') {
            value2 = character2 - 55;
        }
        
        Byte tmpByte[1] = {value1*16 + value2};
        [data appendBytes:tmpByte length:1];
    }
    return data;
}

- (NSString *)dataToString:(NSData *)data {
    NSMutableString *result = [[NSMutableString alloc] init];
    int length = (int)data.length;
    for (int i=0; i<length; i++) {
        Byte tmpByte[1];
        NSMutableString *tmpString = [NSMutableString stringWithString:@"00000000"];
        NSRange range;
        range.location = i;
        range.length = 1;
        [data getBytes:tmpByte range:range];
        int dataNumber = tmpByte[0];
        for (int j=7; j>=0; j--) {
            NSRange tmpRange;
            tmpRange.location = j;
            tmpRange.length = 1;
            if ((dataNumber%2)==0) {
                [tmpString replaceCharactersInRange:tmpRange withString:@"0"];
            }else{
                [tmpString replaceCharactersInRange:tmpRange withString:@"1"];
            }
            dataNumber = floor(dataNumber/2);
        }
        [result appendString:tmpString];
    }
    return result;
}

/**
 Start listen to the characteristic. When new values arrives, the onBLECharacteristicValuChange: funtion will be called.

 @param deviceID The ID of the BLE device.
 @param serviceID The service ID to which the characteristic belongs.
 @param characteristicID The characteristic ID from which you want to read.
 @param state Whether start or stop listen to the characteristic.
 @param callback <#callback description#>
 */
- (void)notifyBLECharacteristicValueChangeWithDeviceID:(NSString *)deviceID servieID:(NSString *)serviceID characteristicID:(NSString *)characteristicID state:(BOOL)state callback:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    
    if (![self.connectedDevice.identifier.UUIDString isEqualToString:deviceID]) {
        return;
    }
    
    //find corresponding CBService
    CBService *service;
    for (CBService *tmpService in self.connectedDevice.services) {
        if ([tmpService.UUID.UUIDString isEqualToString:serviceID]) {
            service = tmpService;
        }
    }
    if (!service) {
        return;
    }
    
    //find corresponding CBCharacteristic
    CBCharacteristic *characteristic;
    for (CBCharacteristic *tmpCharacteristic in service.characteristics) {
        if ([tmpCharacteristic.UUID.UUIDString isEqualToString:characteristicID]) {
            characteristic = tmpCharacteristic;
        }
    }
    if (!characteristic) {
        return;
    }
    
    //TODO: characteristic must be notifiable/indicatible
    [self.connectedDevice setNotifyValue:state forCharacteristic:characteristic];
}

/**
 When new value of a characteristic arrives, this function will be called.

 @param callback <#callback description#>
 */
//TODO: this function may be unioned to the notifyBLECharacteristicValueChangeWithDeviceID:servieID:characteristicID:state:callback: function
- (void)onBLECharacteristicValueChange:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    self.onBLECharacteristicValueChangeCallback = callback;
}

/**
 When the state of BLE connection changes, such as disconnected, this function will be triggered.

 @param callback <#callback description#>
 */
- (void)onBLEConnectionStateChange:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    LXLog(@"%s",__func__);
    
    if (self.onOpenBluetoothAdapterFinishCallback && (self.central.state==CBManagerStatePoweredOn)) {
        NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                     ERROR_CODE_STRING: ERROR_CODE_SUCCEED};
        self.onOpenBluetoothAdapterFinishCallback(resultDict, NO);
    }
    
    if (!self.onBluetoothStateChangeCallback) {
        return;
    }
    
    BOOL discovering = self.central.isScanning;
    BOOL available = (self.central.state == CBManagerStatePoweredOn);
    NSDictionary *adapterStateDict = @{@"discovering":@(discovering),
                                       @"available":@(available)};
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED,
                                 @"adapterState":adapterStateDict};
    self.onBluetoothStateChangeCallback(resultDict, YES);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    LXLog(@"%s",__func__);
    LXLog(@"advertisement: %@",advertisementData);
    LXLog(@"RSSI: %@",RSSI);
    
    if (![self.devicesArray containsObject:peripheral]) {
        [self.devicesArray addObject:peripheral];
    }
    
    if (!self.onFoundBLEDeviceCallback) {
        return;
    }
    
    NSString *name = peripheral.name;
    LXLog(@"device name:%@",name);
    if (name==NULL) {
        name = @"";
    }
    NSDictionary *peripheralDict = @{@"deviceID":peripheral.identifier.UUIDString,
                                     @"name":name,
                                     @"RSSI":RSSI,
                                     @"advertisData":advertisementData};
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED,
                                 @"peripheral":peripheralDict};
    self.onFoundBLEDeviceCallback(resultDict, YES);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    LXLog(@"%s",__func__);
    
    self.connectedDevice = peripheral;
    self.connectedDevice.delegate = self;
    
    if (self.onDeviceConnectedCallback) {
        NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                     ERROR_CODE_STRING: ERROR_CODE_SUCCEED};
        self.onDeviceConnectedCallback(resultDict, NO);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED};
    self.onDeviceDisconnnectedCallback(resultDict, NO);
}

#pragma mark CBPeripheralDelegate


- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    LXLog(@"%s",__func__);
    
    NSArray<CBService *> *services = self.connectedDevice.services;
    NSMutableArray *serviceArray = [[NSMutableArray alloc] init];
    for (CBService *service in services) {
        NSString *serviceUUID = service.UUID.UUIDString;
        [serviceArray addObject:serviceUUID];
    }
    self.onFoundServicesCallback(serviceArray, YES);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
    
    NSMutableArray *characteristics = [[NSMutableArray alloc] init];
    for (CBCharacteristic *characteristic in service.characteristics) {
        NSString *characteristicUUID = characteristic.UUID.UUIDString;
        [characteristics addObject:characteristicUUID];
        //TODO: properties like readability/writability/notifibility should be returned.
    }
    NSDictionary *resultDict = @{@"serviceID":service.UUID.UUIDString,
                                 @"characteristics":characteristics};
    self.onFoundCharacteristicsCallback(resultDict, YES);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
    
    NSData *value = characteristic.value;
    NSString *valueString = [self dataToString:value];
    NSDictionary *resultDict = @{@"deviceID":self.connectedDevice.identifier.UUIDString,
                                 @"serviceID":characteristic.service.UUID.UUIDString,
                                 @"characteristicID":characteristic.UUID.UUIDString,
                                 @"value":valueString};
    
    self.onBLECharacteristicValueChangeCallback(resultDict, YES);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
}

@end
