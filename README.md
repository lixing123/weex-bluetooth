# weex-bluetooth
An extremely easy-use bluetooth library for weex developers. with only a few lines of code, you will be able to connect to a bluetooth device and read from/write to it!

Both iOS and Android are supported.(Android version will be coming soon)

For Chinese version of README click HERE.

## Quick Example
``` javascript
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

```

## Features
Easy-understadable APIs to use.

Full Documents and comments;

Fast response to issues. If you have any questions, feel free to post it!

Friendly to Javascript Promise.

## Installation
1\ Install Weex environment.

2\ For iOS version, install Xcode at Mac OS X. For Android version Android programming environment should be installed.

3\

## How to Use

## Future Plan
1\ Support for Android.

## About Author
xing li, an iOS developer from Nanjing, China. You can access me by shangwangwanwan[@]gmail.com. And here is my tech blog.
Here is the QR code of QQ group chat(For Chinese developers):

![](qqgroup_qrcode.png)

Here is my wechat QR code:

![](wechat_qrcode.jpg)

## Licence
This project is licenced under the terms of Apache licence.
