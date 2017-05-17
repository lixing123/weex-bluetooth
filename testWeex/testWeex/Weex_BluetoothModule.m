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
@property(nonatomic, strong)WXModuleCallback onReadBLECharacteristicValueCallback;
@property(nonatomic, strong)WXModuleKeepAliveCallback onBLEConnectionStateChangeCallback;

@end

@implementation Weex_BluetoothModule

@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(openBluetoothAdapter:))
WX_EXPORT_METHOD(@selector(closeBluetoothAdapter:))
WX_EXPORT_METHOD(@selector(getBluetoothAdapterState:))
WX_EXPORT_METHOD(@selector(onBluetoothAdapterStateChange:))
WX_EXPORT_METHOD(@selector(startBluetoothDevicesDiscoveryWithServices:callback:))
WX_EXPORT_METHOD(@selector(stopBluetoothDeviceDiscovery))
WX_EXPORT_METHOD(@selector(getBluetoothDevicesWithServices:callback:))
WX_EXPORT_METHOD(@selector(getConnectedBluetoothDevicesWithServices:callback:))
WX_EXPORT_METHOD(@selector(createBLEConnectionWithDeviceID:callback:))
WX_EXPORT_METHOD(@selector(closeBLEConnectionWithDeviceID:callback:))
WX_EXPORT_METHOD(@selector(getBLEDeviceServicesWithDeviceID:callback:))
WX_EXPORT_METHOD(@selector(getBLEDeviceCharacteristicsWithDeviceID:serviceID:callback:))
WX_EXPORT_METHOD(@selector(readBLECharacteristicValueWithDeviceID:serviceID:characteristicID:callback:))
WX_EXPORT_METHOD(@selector(writeBLECharacteristicValueWithDeviceID:serviceID:characteristicID:value:callback:))
WX_EXPORT_METHOD(@selector(notifyBLECharacteristicValueChangeWithDeviceID:servieID:characteristicID:state:callback:))
WX_EXPORT_METHOD(@selector(onBLEConnectionStateChange:))

- (id)init {
    self = [super init];
    
    self.devicesArray = [[NSMutableArray alloc] init];
    
    return self;
}

/**
 Initialize the bluetooth adapter.

 @param callback When open bluetooth adapter has a result, this callback will be triggered with a dictionary.
 resultDict = {
    'result': (String)  will be "succeed" or "fail".
    'errCode': (Int) 0 if succeed.
 }
 @see RESULT_STRING,ERROR_CODE_STRING
 
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

 @param callback When close action finishes, this callback will be triggered with a dictionary.
 resultDict = {
    'result': (String)  will be "succeed" or "fail".
    'errCode': (Int) 0 if succeed.
 }
 @see RESULT_STRING,ERROR_CODE_STRING
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

 @param callback callback to Weex with adapter state results dictionaray.
 resultDict = {
    'result': (String) will be "succeed" or "fail"
    'errCode': (Int) 0 if succeed.
    'adapterState' = {
        'discovering': (BOOL) whether the adapter is discovering devices.
        'available': (BOOL) the availability of the adapter
    }
 }
 @see RESULT_STRING,ERROR_CODE_STRING
 */
- (void)getBluetoothAdapterState:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    
    NSDictionary *adapterStateDict = [self bluetoothAdapterStateDictionary];
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED,
                                 @"adapterState":adapterStateDict};
    callback(resultDict);
}

/**
 When the state of the adapter changes, such as avability or state of discovery, this will be triggered.

 @param callback When bluetooth state changes, this callback will be triggered with a dictionary.
 resultDict = {
    'result': (String) will be "succeed" or "fail"
    'errCode': (Int) 0 if succeed.
    'adapterState' = {
        'discovering': (BOOL) whether the adapter is discovering devices.
        'available': (BOOL) the availability of the adapter
    }
 }
 @see RESULT_STRING,ERROR_CODE_STRING
 */
- (void)onBluetoothAdapterStateChange:(WXModuleKeepAliveCallback)callback {
    self.onBluetoothStateChangeCallback = callback;
}

/**
 Start to scan bluetooth devices.

 @param servicesArray Only scan devices that are advertising any of the specific services. NULL if scan all devices.
 @param callback When new device is discovered, this callback will be triggered with a dictionary of peripheral information.
 resultDict = {
    'deviceID': (String) UUID of the bluetooth device
    'name': (String) name of the device.
 }
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
- (void)stopBluetoothDeviceDiscovery {
    LXLog(@"%s",__func__);
    
    [self.central stopScan];
}

/**
 Get all discovered devices, including devices connected to the manager.

 @param servicesArray If not null, only devices with one of the specific services will be returned.
 @param callback Callback to weex with an array of devices.
 resultArray = {
    [
        'deviceID': (String) identifier of the device.
        'name': (String) name of the device.
    ]
    ...
 }
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
        [resultDeviceIDArray addObject:[self deviceInfomationWithPeripheral:peripheral]];
    }
    
    callback(resultDeviceIDArray);
}

/**
 Get connected devices.

 @param servicesArray If no null, only devices with specific services will be returned.
 @param callback <#callback description#>
 */
//TODO: implement this function
- (void)getConnectedBluetoothDevicesWithServices:(NSArray *)servicesArray callback:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
}

/**
 try connecting to a BLE device.

 @param deviceID The ID of the BLE device.
 @param callback When device connected, this callback will be triggered with a dictionary of result
 resultDict = {
    'result': (String)  will be "succeed" or "fail".
    'errCode': (Int) 0 if succeed.
    'device': (Dictionary) information of connected device.
    deviceDict = {
        'deviceID': (String) identifier of the device.
        'name': (String) name of the device.
    }
 }
 */
- (void)createBLEConnectionWithDeviceID:(NSString *)deviceID callback:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    CBPeripheral *peripheral;
    for (CBPeripheral *tempPeripheral in self.devicesArray) {
        if ([tempPeripheral.identifier.UUIDString isEqualToString:deviceID]) {
            peripheral = tempPeripheral;
        }
    }
    
    if (peripheral) {
        self.onDeviceConnectedCallback = callback;
        [self.central connectPeripheral:peripheral options:nil];
    }
}

/**
 Try disconnecting with connected device

 @param deviceID The ID of the BLE device.
 @param callback When close connection finishes, callback will be triggered with a dictionary of result.
 resultDict = {
    'result': (String)  will be "succeed" or "fail".
    'errCode': (Int) 0 if succeed.
    'device': (Dictionary) information of connected device.
    deviceDict = {
        'deviceID': (String) identifier of the device.
        'name': (String) name of the device.
    }
 }
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
 @param callback When services got, this callback will be triggered with an array of service information.
 resultDict = {
    [
        'UUID': (String) UUID of the service.
        'isPrimary': (BOOL)whether this service is primary.
    ]
    ...
 }
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
 @param callback When characteristics found, this callback will be triggered with an array of characteristic information.
 resultDict = {
    [
        'UUID': (String) UUID of the characteristic
        'properties': (Dictionary) properties of the characteristic
        propertyDict = {
            'read': (BOOL) whether the characteristic is readable
            'write': (BOOL) whether the characteristic is writable
            'notify': (BOOL) whether the characteristic is notifiable
            'indicate': (BOOL) whether the characteristic is indicatable
        }
        ...
    ]
 }
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
 @param callback When new value received, this callback will be triggered, with a dictionary of information.
 resultDict = {
    'UUID': (String) UUID of the characteristic
    'value': (String) value of the characteristic. Note the string consists of 0s and 1s. For example, '0101101001011010' means '5A5A' in hex.
 }
 @discussion The characteristic must be readable.
 */
- (void)readBLECharacteristicValueWithDeviceID:(NSString *)deviceID serviceID:(NSString *)serviceID characteristicID:(NSString *)characteristicID callback:(WXModuleCallback)callback {
    LXLog(@"%s",__func__);
    
    //TODO: similar code blocks need to be refactored.
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
    
    self.onReadBLECharacteristicValueCallback = callback;
    [self.connectedDevice readValueForCharacteristic:characteristic];
}

/**
 Write value to a characteristic

 @param deviceID The ID of the BLE device.
 @param serviceID The service ID to which the characteristic belongs.
 @param characteristicID The characteristic ID from which you want to read.
 @param value The value that you want write to the characteristic.
 @param callback callback description
 @discussion 
    This characteristic must be writable.
    Since only strings can be transferred, the format of String will be converted to NSData based on ASCII code. For example, the string "5A" will be converted to NSData with content {00000101 01000001};
    value must only contains characters from "0" to "9" and from "A" to "F"(must be upper case); length of value must be even
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
    
    [self.connectedDevice writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED};
    callback(resultDict);
}

/**
 Start listen to the characteristic. When new values arrives, the onBLECharacteristicValuChange: funtion will be called.

 @param deviceID The ID of the BLE device.
 @param serviceID The service ID to which the characteristic belongs.
 @param characteristicID The characteristic ID from which you want to read.
 @param state Whether start or stop listen to the characteristic.
 @param callback When new value received, this callback will be triggered, with a dictionary of information.
 resultDict = {
    'UUID': (String) UUID of the characteristic
    'value': (String) value of the characteristic. Note the string consists of 0s and 1s. For example, '0101101001011010' means '5A5A' in hex.
 }
 */
- (void)notifyBLECharacteristicValueChangeWithDeviceID:(NSString *)deviceID servieID:(NSString *)serviceID characteristicID:(NSString *)characteristicID state:(BOOL)state callback:(WXModuleKeepAliveCallback)callback{
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
    self.onBLECharacteristicValueChangeCallback = callback;
    [self.connectedDevice setNotifyValue:state forCharacteristic:characteristic];
}

/**
 Set bluetooth connection state change callback.

 @param callback When the state of BLE connection changes, such as disconnected, this callback will be triggered.
 resultDict = {
    'deviceID': (String) identifier of the device.
    'name': (String) name of the device.
 }
 */
- (void)onBLEConnectionStateChange:(WXModuleKeepAliveCallback)callback {
    LXLog(@"%s",__func__);
    
    self.onBLEConnectionStateChangeCallback = callback;
}

#pragma mark - Tool functions

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
 Form a dictionary of the state of bluetooth adapter.

 @return A dictionary, consists whether adapter is discovering, and its availability.
 
 */
- (NSDictionary *)bluetoothAdapterStateDictionary {
    BOOL discovering = self.central.isScanning;
    BOOL available = (self.central.state == CBManagerStatePoweredOn);
    NSDictionary *resultDict = @{BluetoothAdapterStateDiscovering:@(discovering),
                                 BluetoothAdapterStateAvailable:@(available)};
    return resultDict;
}

- (NSDictionary *)deviceInfomationWithPeripheral:(CBPeripheral *)peripheral {
    NSString *nameString = (peripheral.name==NULL)?@"":peripheral.name;
    NSDictionary *resultDict = @{@"deviceID":peripheral.identifier.UUIDString,
                                 @"name":nameString};
    return resultDict;
}

- (NSDictionary *)serviceDictWithService:(CBService *)service {
    NSDictionary *resultDict = @{@"UUID":service.UUID.UUIDString,
                                 @"isPrimary":@(service.isPrimary)};
    return resultDict;
}

- (NSDictionary *)characteristicDictWithCharacteristic:(CBCharacteristic *)characteristic {
    CBCharacteristicProperties properties = characteristic.properties;
    BOOL readable = properties & CBCharacteristicPropertyRead;
    BOOL writable = properties & CBCharacteristicPropertyWrite;
    BOOL notifiable = properties & CBCharacteristicPropertyNotify;
    BOOL indicatable = properties & CBCharacteristicPropertyIndicate;
    NSDictionary *propertyDict = @{@"read":@(readable),
                                   @"write":@(writable),
                                   @"notify":@(notifiable),
                                   @"indicate":@(indicatable)};
    NSDictionary *resultDict = @{@"UUID":characteristic.UUID.UUIDString,
                                 @"properties":propertyDict};
    return resultDict;
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
    
    NSDictionary *resultDict = [self bluetoothAdapterStateDictionary];
    self.onBluetoothStateChangeCallback(resultDict, YES);
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    LXLog(@"%s",__func__);
    
    if (![self.devicesArray containsObject:peripheral]) {
        [self.devicesArray addObject:peripheral];
    }
    
    if (!self.onFoundBLEDeviceCallback) {
        return;
    }
    
    NSString *name = peripheral.name;
    if (name==NULL) {
        name = @"";
    }
    NSDictionary *peripheralDict = [self deviceInfomationWithPeripheral:peripheral];
    
    self.onFoundBLEDeviceCallback(peripheralDict, YES);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    LXLog(@"%s",__func__);
    
    self.connectedDevice = peripheral;
    self.connectedDevice.delegate = self;
    
    if (self.onDeviceConnectedCallback) {
        NSDictionary *deviceDict = [self deviceInfomationWithPeripheral:peripheral];
        NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                     ERROR_CODE_STRING: ERROR_CODE_SUCCEED,
                                     @"device":deviceDict};
        self.onDeviceConnectedCallback(resultDict, NO);
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
    
    if (self.onDeviceConnectedCallback) {
        NSDictionary *deviceDict = [self deviceInfomationWithPeripheral:peripheral];
        NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_FAILED,
                                     ERROR_CODE_STRING: ERROR_CODE_UNKNOWN,
                                     @"peripheral:":deviceDict};
        self.onDeviceConnectedCallback(resultDict, NO);
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
    
    NSDictionary *deviceDict = [self deviceInfomationWithPeripheral:peripheral];
    NSDictionary *resultDict = @{RESULT_STRING: RESULT_STRING_SUCCEED,
                                 ERROR_CODE_STRING: ERROR_CODE_SUCCEED,
                                 @"device":deviceDict};
    if (self.onBLEConnectionStateChangeCallback) {
        self.onBLEConnectionStateChangeCallback(deviceDict, YES);
    }
    if (self.onDeviceDisconnnectedCallback) {
        self.onDeviceDisconnnectedCallback(resultDict, NO);
    }
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
    NSMutableArray<NSDictionary *> *serviceArray = [[NSMutableArray alloc] init];
    for (CBService *service in services) {
        NSDictionary *serviceDict = [self serviceDictWithService:service];
        [serviceArray addObject:serviceDict];
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
        NSDictionary *characteristicDict = [self characteristicDictWithCharacteristic:characteristic];
        [characteristics addObject:characteristicDict];
    }
    self.onFoundCharacteristicsCallback(characteristics, YES);
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    LXLog(@"%s",__func__);
    
    NSData *value = characteristic.value;
    NSString *valueString = [self dataToString:value];
    NSDictionary *resultDict = @{@"UUID":characteristic.UUID.UUIDString,
                                 @"value":valueString};
    
    if (self.onReadBLECharacteristicValueCallback) {
        self.onReadBLECharacteristicValueCallback(resultDict);
    }
    
    if (self.onBLECharacteristicValueChangeCallback) {
        self.onBLECharacteristicValueChangeCallback(resultDict, YES);
    }
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
