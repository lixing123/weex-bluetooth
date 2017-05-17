const wx = weex.requireModule('wx-ble');

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