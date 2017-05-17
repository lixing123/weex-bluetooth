//
//  BluetoothModule.m
//  testWeex
//
//  Created by 李 行 on 28/04/2017.
//  Copyright © 2017 lixing123.com. All rights reserved.
//

#import "BluetoothModule.h"
#import <CoreBluetooth/CoreBluetooth.h>

@interface BluetoothModule ()<CBCentralManagerDelegate,CBPeripheralDelegate>

@property(nonatomic, strong)CBCentralManager *manager;
@property(nonatomic, strong)CBPeripheral *fhrDevice;
@property(nonatomic, strong)CBCharacteristic *notifyCharacteristic;
@property(nonatomic, strong)CBCharacteristic *writeCharacteristic;

@end

@implementation BluetoothModule

@synthesize weexInstance;

WX_EXPORT_METHOD(@selector(helloWithCallback:))
//WX_EXPORT_METHOD_SYNC(@selector(hello))//暂不可用

- (void)helloWithCallback:(WXModuleCallback)callback {
    NSLog(@"hello");
    callback(@"hello module");
    [self start];
}

//- (NSString *)hello {
//    NSLog(@"hello sync");
//    return @"hello sync";
//}

- (void)start {
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBManagerStatePoweredOn) {
        [self.manager scanForPeripheralsWithServices:nil
                                             options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@NO}];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *, id> *)advertisementData RSSI:(NSNumber *)RSSI{
    NSString *name = peripheral.name;
    if ([name containsString:@"LHFH1GMA"]) {
        NSLog(@"is fhr");
        self.fhrDevice = peripheral;
        [self.manager connectPeripheral:peripheral
                                options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral{
    [self.fhrDevice setDelegate:self];
    [self.fhrDevice discoverServices:nil];
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(nullable NSError *)error{
    
}

#pragma mark CBPeripheralDelegate


- (void)peripheralDidUpdateName:(CBPeripheral *)peripheral {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didModifyServices:(NSArray<CBService *> *)invalidatedServices {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(nullable NSError *)error {
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(nullable NSError *)error{
    for (CBService *service in self.fhrDevice.services) {
        NSLog(@"servie uuid:%@",service.UUID.UUIDString);
        if ([service.UUID.UUIDString containsString:@"FFF0"]) {
            [self.fhrDevice discoverCharacteristics:nil
                                         forService:service];
        }
        
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverIncludedServicesForService:(CBService *)service error:(nullable NSError *)error{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(nullable NSError *)error{
    for (CBCharacteristic *characteristic in service.characteristics) {
        if ([characteristic.UUID.UUIDString containsString:@"FFF1"]) {
            NSLog(@"found notify characteristic:%@",characteristic.UUID.UUIDString);
            self.notifyCharacteristic = characteristic;
            [self.fhrDevice setNotifyValue:YES forCharacteristic:self.notifyCharacteristic];
        }
        if ([characteristic.UUID.UUIDString containsString:@"FFF2"]) {
            NSLog(@"found write characteristic:%@",characteristic.UUID.UUIDString);
            self.writeCharacteristic = characteristic;
            
            //向write characteristic里写东西，开始notify
            //NSData *data = [NSData dataWithBytes:<#(nullable const void *)#> length:<#(NSUInteger)#>];
            // var arr : [UInt8] = [0x5a,0x5a,0x01,0x00,0x0B,0x03,0x00,0x01,0x00,0x01]
            // arr.append(UInt8(UInt32(totalNum)%256))
            unsigned char command[11] = {0x5A, 0x5A, 0x01, 0x00, 0x0B, 0x03, 0x00, 0x01, 0x00, 0x01, 0xC5};
            NSData* data = [[NSData alloc] initWithBytes:&command length:11];
            [self.fhrDevice writeValue:data forCharacteristic:self.writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
        }
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    NSData *data = characteristic.value;
    unsigned char values[13];
    [data getBytes:values length:13];
    int fhr = values[9];
    int toco = values[11];
    [self.weexInstance fireGlobalEvent:@"foundFhr" params:@{@"fhr":@(fhr),@"toco":@(toco)}];
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic error:(nullable NSError *)error{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    
}

- (void)peripheral:(CBPeripheral *)peripheral didWriteValueForDescriptor:(CBDescriptor *)descriptor error:(nullable NSError *)error{
    
}

@end
