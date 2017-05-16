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
  .then(data => {
    var services = [];
    return discoverDevice(services);
  })
  .then(device => {
    var deviceName = device['name'];
    var index = deviceName.indexOf("LHFH1GMA");
    if (index != -1){//the device is what we want.
      return connectToDevice(device);
    }
  }).then(device => {
    return discoverService(device);
  }).then(data => {
    return discoverCharacteristic(data);
  }).then(data => {
    var deviceID = data[0];
    var serviceID = data[1];
    var characteristics = data[2];
    for (var i = 0; i < characteristics.length; i++) {
      var characteristicID = characteristics[i];
      if (characteristicID=="FFF2") {//write characteristic
        var value = "5A5A01000B0300010001C5";
        writeToCharacteristic(deviceID, serviceID, characteristicID, value);
      }else if (characteristicID=="FFF1") {//nofity characteristic
        readFromCharacteristic(deviceID, serviceID, characteristicID)
        .then(data => {
          callback(data);
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

export function discoverDevice(services){
  var promise = new Promise(function(resolve, reject){
      wx.startBluetoothDevicesDiscoveryWithServices(services,function(res){
        resolve(res);
      });
    });
    return promise;
}

export function connectToDevice(device){
  //connect to device.
  var deviceID = device['deviceID'];
  var deviceName = device['name'];
  var promise = new Promise(function(resolve, reject){
    wx.createBLEConnectionWithDeviceID(deviceID, function(res){
      wx.stopBluetoothDeviceDiscovery()
      resolve(res['device']);
    });
  });
  return promise;
}

export function discoverService(device){
  //discover service
  var deviceID = device.deviceID;
  var promise = new Promise(function(resolve, reject){
    wx.getBLEDeviceServicesWithDeviceID(deviceID, function(res){
      for (var i = 0; i < res.length; i++) {
        var serviceID = res[i]['UUID'];
        if (serviceID=="FFF0") {
          resolve([deviceID,serviceID]);
        }
      }
    });
  });
  return promise;
}

export function discoverCharacteristic(data){
  var deviceID = data[0];
  var serviceID = data[1];
  var promise = new Promise(function(resolve, reject){
    wx.getBLEDeviceCharacteristicsWithDeviceID(deviceID, serviceID, function(res){
      var characteristics = [];
      for (var i = 0; i < res.length; i++) {
        var characteristicID = res[i]['UUID'];
        characteristics.push(characteristicID);
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

export function readFromCharacteristic(deviceID, serviceID, characteristicID){
  var readPromise = new Promise(function(resolve, reject){
    wx.notifyBLECharacteristicValueChangeWithDeviceID(deviceID, serviceID, characteristicID,true, function(res){
      var value = res['value'];
      var fhrString  = value.substring(73,81);
      
      var tocoString = value.substring(88,96);
      var toco = 0;
      for (var i = 0; i < tocoString.length; i++) {
        var char = tocoString[i];
        if (char=='1') {
          toco = toco + Math.pow(2,7-i);
        }
      }
      resolve(toco);
    })
  });
  return readPromise;
}
