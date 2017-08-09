const wx = weex.requireModule('wx-ble');

/**
 * open the bluetooth adapter. you should first call this function. 
 * (For iOS)this will automatically trigger open bluetooth request on iOS.
 * @return {Promise}   promise a new promise that will resolve if bluetooth adapter opens successfully.
 * if open bluetooth succeeds, promise will resolve with a string of "success"
 */
 export function openBluetoothAdapter(){
  var promise = new Promise(function(resolve, reject){
    wx.openBluetoothAdapter(function(res){
      console.log("qazwsx" + res);
      resolve("success");
    })
  });
  return promise;
}

/**
 * start to discover BLE device.
 * @param  {Array}    services only scan for devices that broadcast(don't means contains) any of the listed services. Null means no limit.
 * @param  {function} filter   add filter to the device based on properties of device, including deviceID and name. 
 * The parameter "device" is a dictionary:
 * device = {
 *  'deviceID': (String) UUID(iOS) or Mac(Android) of the bluetooth device
 *  'name': (String) name of the device.
 * }
 * @return {Promise}  promise  a promise that will resolve with a device dictionary if a device satisfying requirements is found.
 * @discuss with limitations of Javascript Promise, only the first device will be returned, following device will be ignored.
 */
 export function discoverDevice(services = [], filter = function(device){return true}){
  console.log("qazwsx" + "discoverDevice");
  var promise = new Promise(function(resolve, reject){
    wx.startBluetoothDevicesDiscoveryWithServices(services,function(device){
      console.log("qazwsx" + "startBluetoothDevicesDiscoveryWithServices");
      if (filter(device)) {
        resolve(device);
      }
    });
  });
  return promise;
}

/**
 * connect to a specific device.
 * @param  {Dictionary}  device   The description of the device.
 * @param  {Boolean} stopScan stop scanning new devices.
 * @return {Promise}   a promise that return information of connected device if connection succeeds.
 * device = {
 *  'deviceID': (String) UUID(iOS) or Mac(Android) of the bluetooth device
 *  'name': (String) name of the device.
 * }
 */
 export function connectToDevice(device, stopScan=true){
  //connect to device.
  var deviceID = device['deviceID'];
  var deviceName = device['name'];
  var promise = new Promise(function(resolve, reject){
    wx.createBLEConnectionWithDeviceID(deviceID, function(res){
      if (stopScan) {
        wx.stopBluetoothDeviceDiscovery()
      }
      console.log("qazwsx --- " + "connectToDevice" + res['device']);
      resolve(res['device']);
    });
  });
  return promise;
}

/**
 * disconver services of a connected device.
 * @param  {Dictionary} device information of the device.
 * device = {
 *  'deviceID': (String) UUID(iOS) or Mac(Android) of the bluetooth device
 *  'name': (String) name of the device.
 * }
 * @param  {function} filter Only return services that satisfies requirements.
 * service = {
 *  'UUID': (String) UUID of the service.
 *  'isPrimary': (BOOL) whether this service is primary.
 * }
 * @return {Promise}   promise A promise that returns a list of discovered services satisfying requirements.
 * resultDict = {
 *   service,
 *   service,
 *   ...
 * }
 */
 export function discoverServices(device, filter=function(service){return true}){
  //discover service
  var deviceID = device.deviceID;
  var promise = new Promise(function(resolve, reject){
    wx.getBLEDeviceServicesWithDeviceID(deviceID, function(services){
      var resultServices = [];
      console.log("qazwsx" + "discoverDevice service" + services);
      for (var i = 0; i < services.length; i++) {
       var service = services[i];
       console.log("qazwsx" + "discoverDevice service for" + service['UUID']);
       if (filter(service)) {
        resultServices.push(service);
      }
    }
    var result = {"deviceID": deviceID,
    "services": resultServices};
    console.log("qazwsx" + "discoverDevice result = " + deviceID + "----"+resultServices);
    resolve(result);
  });
  });
  return promise;
}

/**
 * discover characteristics of a specific service.
 * @param  {String} deviceID  deviceID of the device.
 * @param  {String} serviceID a serviceID of the device.
 * @return {Promise}  A promise that will resolve with a dictionary containing characteristics of the service.
 * resultDict = {
 *   deviceID,
 *   serviceID
 *   characteristics = {
 *     [
 *       'UUID': (String) UUID of the characteristic
 *       'properties': (Dictionary) properties of the characteristic
 *       propertyDict = {
 *           'read': (BOOL) whether the characteristic is readable
 *           'write': (BOOL) whether the characteristic is writable
 *           'notify': (BOOL) whether the characteristic is notifiable
 *           'indicate': (BOOL) whether the characteristic is indicatable
 *      }
 *     ]
 *   }
 * }
 */
 export function discoverCharacteristics(deviceID, serviceID){
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

/**
 * write to a characteristic. the characteristic must be writable
 * @param  {String} deviceID         deviceID of the device.
 * @param  {String} serviceID        serviceID that the characteristic belongs to.
 * @param  {String} characteristicID characteristicID that we want to write to.
 * @param  {String} value            the value that we want to write to characteristic. 
 * Since only strings can be transferred, the format of String will be converted to Data based on ASCII code. 
 * For example, if you want to write the value {00000101 01000001}, the value should be "5A"
 * note: value must only contains characters from "0" to "9" and from "A" to "F"(must be upper case); length of value must be even
 */
 export function writeToCharacteristic(deviceID, serviceID, characteristicID, value){
  var writePromise = new Promise(function(resolve, reject){
    wx.writeBLECharacteristicValueWithDeviceID(deviceID, serviceID, characteristicID, value, function(res){
      resolve(res);
    })
  });
}

/**
 * listen to value changes of a characteristic. the characteristic must be notifiable/indicatable
 * @param  {String}   deviceID         deviceID of the device.
 * @param  {String}   serviceID        serviceID that the characteristic belongs to.
 * @param  {String}   characteristicID characteristicID that we want to listen to.
 * @param  {Function} callback         when new value of the characteristic received, callback will be triggered.
 * @return {Promise}  promise          a promise that will not ever resolve.
 */
 export function listenToValueChangeOfCharacteristic(deviceID, serviceID, characteristicID, callback=function(data){}){
  var readPromise = new Promise(function(resolve, reject){
    wx.notifyBLECharacteristicValueChangeWithDeviceID(deviceID, serviceID, characteristicID,true, function(res){
      var value = res['value'];
      callback(value);
    })
  });
  return readPromise;
}

export function onDeviceDisconnected(callback){
  wx.onBLEConnectionStateChange(function(res){
    callback();
  });
}

export function getDeviceConnectState(callback){
 var statePromise = new Promise(function(resolve, reject){
  wx.getBleDeviceConnetState(function(res){
    var value = res['state'];
    callback(value);
    })
  });
 return statePromise;
}