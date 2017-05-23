import {openBluetoothAdapter,discoverDevice,connectToDevice,discoverServices,discoverCharacteristics,writeToCharacteristic,listenToValueChangeOfCharacteristic} from './weex-bluetooth.js';

export function startFetal(callback) {
  //open bluetooth
  openBluetoothAdapter()
  .then(data => {//scan for BLE devices
    var services = [];
    return discoverDevice(services,function(device){//scan filter
      var deviceName = device['name'];
      var index = deviceName.indexOf("you-ble-name");
      if (index != -1){//the device is what we want.
        return true;
      }else{
        return false;
      }
    });
  })
  .then(device => {//connect to BLE device
    return connectToDevice(device);
  }).then(device => {//discover service of BLE device
    return discoverServices(device);
  }).then(data => {//discover characteristic of a service
    var deviceID = data['deviceID'];
    var services = data['services'];
    for (var index in services){
      var serviceID = services[index]['UUID'];
      if (serviceID=="FFF0") {
        return discoverCharacteristics([deviceID, serviceID];
      }
    }
  }).then(data => {
    var deviceID = data[0];
    var serviceID = data[1];
    var characteristics = data[2];
    for (var i = 0; i < characteristics.length; i++) {
      var characteristicID = characteristics[i]['UUID'];
      if (characteristicID=="your-characteristic-UUID") {//listen to value change of characteristic
        listenToValueChangeOfCharacteristic(deviceID, serviceID, characteristicID,function(data){
          console.log(data);
        });
      }
    }
  });
}


