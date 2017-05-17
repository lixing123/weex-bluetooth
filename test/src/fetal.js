const wx = weex.requireModule('wx-ble');

export default{
  device:{
    deviceID: '',
    name: ''
  }
}

export function startFetal(callback) {
  //open bluetooth
  openBluetoothAdapter()
  .then(data => {//scan for BLE devices
    var services = [];
    return discoverDevice(services,function(device){//scan filter
      var deviceName = device['name'];
      var index = deviceName.indexOf("LHFH1GMA");
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
    return discoverServices(device,function(service){
      return (service['UUID']=="FFF0");
    });
  }).then(data => {//discover characteristic of a service
    var deviceID = data['deviceID'];
    var services = data['services'];
    var serviceID = services[0]['UUID']
    for (var index in services){
      var serviceID = services[index]['UUID'];
      return discoverCharacteristics([deviceID, serviceID]);
    }
  }).then(data => {
    var deviceID = data[0];
    var serviceID = data[1];
    var characteristics = data[2];
    for (var i = 0; i < characteristics.length; i++) {
      var characteristicID = characteristics[i]['UUID'];
      if (characteristicID=="FFF2") {//write characteristic
        var value = "5A5A01000B0300010001C5";
        writeToCharacteristic(deviceID, serviceID, characteristicID, value);
      }else if (characteristicID=="FFF1") {//listen to value change of characteristic
        listenToValueChangeOfCharacteristic(deviceID, serviceID, characteristicID,function(data){
          var fhrString  = data.substring(73,81);
          var fhr = 0;
          for (var i = 0; i < fhrString.length; i++) {
            var char = fhrString[i];
            if (char=='1') {
              fhr = fhr + Math.pow(2,7-i);
            }
          }

          var tocoString = data.substring(88,96);
          var toco = 0;
          for (var i = 0; i < tocoString.length; i++) {
            var char = tocoString[i];
            if (char=='1') {
              toco = toco + Math.pow(2,7-i);
            }
          }
          callback([fhr, toco]);
        });
      }
    }
  });
}

export function openBluetoothAdapter(){
  var promise = new Promise(function(resolve, reject){
    wx.openBluetoothAdapter(function(res){
      resolve("succeed");
    })
  });
  return promise;
}

export function discoverDevice(services = [], filter = function(device){return true}){
  var promise = new Promise(function(resolve, reject){
    wx.startBluetoothDevicesDiscoveryWithServices(services,function(device){
      if (filter(device)) {
        resolve(device);
      }
    });
  });
  return promise;
}

export function connectToDevice(device, stopScan=true){
  //connect to device.
  var deviceID = device['deviceID'];
  var deviceName = device['name'];
  var promise = new Promise(function(resolve, reject){
    wx.createBLEConnectionWithDeviceID(deviceID, function(res){
      if (stopScan) {
        wx.stopBluetoothDeviceDiscovery()
      }
      resolve(res['device']);
    });
  });
  return promise;
}

export function discoverServices(device, filter=function(service){return true}){
  //discover service
  var deviceID = device.deviceID;
  var promise = new Promise(function(resolve, reject){
    wx.getBLEDeviceServicesWithDeviceID(deviceID, function(services){
      var resultServices = [];
      for (var i = 0; i < services.length; i++) {
        var service = services[i];
        if (filter(service)) {
          resultServices.push(service);
        }
      }
      var result = {"deviceID": deviceID,
                    "services": resultServices};
      resolve(result);
    });
  });
  return promise;
}

export function discoverCharacteristics(data){
  var deviceID = data[0];
  var serviceID = data[1];
  var promise = new Promise(function(resolve, reject){
    wx.getBLEDeviceCharacteristicsWithDeviceID(deviceID, serviceID, function(res){
      var characteristics = [];
      for (var i = 0; i < res.length; i++) {
        var characteristic = res[i];
        characteristics.push(characteristic);
      }
      resolve([deviceID, serviceID, characteristics]);
    });
  });
  return promise;
}

export function writeToCharacteristic(deviceID, serviceID, characteristicID, value){
  var writePromise = new Promise(function(resolve, reject){
    wx.writeBLECharacteristicValueWithDeviceID(deviceID, serviceID, characteristicID, value, function(res){
      resolve(res);
    })
  });
}

export function listenToValueChangeOfCharacteristic(deviceID, serviceID, characteristicID, callback=function(data){}){
  var readPromise = new Promise(function(resolve, reject){
    wx.notifyBLECharacteristicValueChangeWithDeviceID(deviceID, serviceID, characteristicID,true, function(res){
      var value = res['value'];
      callback(value);
    })
  });
  return readPromise;
}
