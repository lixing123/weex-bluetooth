<template>
  <div class="wrapper" @click="update">
    <image :src="logoUrl" class="logo"></image>
    <text class="title">{{target}}</text>
  </div>
</template>

<style>
  .wrapper { align-items: center; margin-top: 120px; }
  .title { font-size: 48px; }
  .logo { width: 360px; height: 82px; }
</style>

<script>
  // export default {
  //   data: {
      
  //   },
  //   methods: {
      
  //   }
  // }

  module.exports = {
    data:{
      logoUrl: 'https://alibaba.github.io/weex/img/weex_logo_blue@3x.png',
      target: 'World'
    },
    methods: {
      update: function (e) {
        //open bluetooth
        const wx = weex.requireModule('wx-ble');
        var that = this;
        var deviceID = '';
        var promise = new Promise(function(resolve, reject){
          wx.openBluetoothAdapter(function(res){
            resolve("succeed");
          })
        });
        promise.then(function(data){
          //start discovering ble devices.
          var tmpPromise = new Promise(function(resolve, reject){
            var services = [];
            wx.startBluetoothDevicesDiscoveryWithServices(services,function(res){
              var deviceID = res['identifier'];
              var deviceName = res['name'];
              var index = deviceName.indexOf("LHFH1GMA");
              if (index != -1){//the device is what we want.
                that.target = "found peripheral " + deviceName + ", connecting...";
                resolve(res);
              }
            });
          });
          return tmpPromise;
        })
        .then(device => {
          //connect to device.
          that.target = "connecting";
          var tmpPromise = new Promise(function(resolve, reject){
            var deviceID = device['deviceID'];
            var deviceName = device['name'];
            wx.createBLEConnectionWithDeviceID(deviceID, function(res){
              that.target = "connect to ble " + deviceName +" succeed"
              wx.stopBluetoothDeviceDiscovery()
              resolve(res);
            });
          });
          return tmpPromise;
        }).then(function(data){
          //discover service
          var tmpPromise = new Promise(function(resolve, reject){
            var deviceID = data.device.deviceID;
            wx.getBLEDeviceServicesWithDeviceID(deviceID, function(res){
              for (var i = 0; i < res.length; i++) {
                var serviceID = res[i]['UUID'];
                that.target = that.target + serviceID;
                if (serviceID=="FFF0") {
                  resolve([deviceID,serviceID]);
                }
              }
            });
          });
          return tmpPromise;
        }).then(function(data){
          that.target = "discovering characteristics...";
          var tmpPromise = new Promise(function(resolve, reject){
            var deviceID = data[0];
            var serviceID = data[1];
            wx.getBLEDeviceCharacteristicsWithDeviceID(deviceID, serviceID, function(res){
              var characteristics = [];
              for (var i = 0; i < res.length; i++) {
                var characteristicID = res[i]['UUID'];
                characteristics.push(characteristicID);
              }
              resolve([deviceID, serviceID, characteristics]);
            });
          });
          return tmpPromise;
        }).then(function(data){
          var deviceID = data[0];
          var serviceID = data[1];
          var characteristics = data[2];
          console.log("characteristics:" + characteristics);
          for (var i = 0; i < characteristics.length; i++) {
            var characteristicID = characteristics[i];
            console.log("characteristic:" + characteristicID);
            if (characteristicID=="FFF2") {//write characteristic
              var value = "5A5A01000B0300010001C5";
              var writePromise = new Promise(function(resolve, reject){
                wx.writeBLECharacteristicValueWithDeviceID(deviceID, serviceID, characteristicID, value, function(res){
                  resolve(res);
                })
              });
            }else if (characteristicID=="FFF1") {//nofity characteristic
              var readPromise = new Promise(function(resolve, reject){
                wx.notifyBLECharacteristicValueChangeWithDeviceID(deviceID, serviceID, characteristicID,true, function(res){
                  var value = res['value'];
                  var fhrString  = value.substring(73,81);
                  
                  var tocoString = value.substring(88,96);
                  console.log("toco string:" + tocoString);
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
              readPromise.then(function(data){
                console.log("tocos:" + data);
                that.target = "toco:" + data;
              });
            }
          }
        });

        // promise(200);
        

        // wx.openBluetoothAdapter(function(res){
        //   // success
        //   var services = []
        //   wx.startBluetoothDevicesDiscoveryWithServices(services,function(res){
        //     var deviceID   = res['peripheral']['deviceID']
        //     var deviceName = res['peripheral']['name']
        //     var index = deviceName.indexOf("LHFH1GMA");
        //     if (index != -1){
        //       that.target = "found peripheral " + deviceName + ", connecting..."
        //       wx.createBLEConnectionWithDeviceID(deviceID, function(res){
        //         that.target = "connect to ble " + deviceName +" succeed"
        //         wx.stopBluetoothDeviceDiscovery(function(res){

        //         })
        //         wx.getBLEDeviceServicesWithDeviceID(deviceID, function(res){
        //           that.target = res
        //           for(var i=0;i<res.length;i++){
        //             var serviceID = res[i]
        //             that.target = that.target + serviceID
        //             if (serviceID=="FFF0") {
        //               that.target = that.target + ",," + serviceID
        //               wx.getBLEDeviceCharacteristicsWithDeviceID(deviceID, serviceID, function(res){
        //                 that.target = res['characteristics']
        //                 var chars = res['characteristics']
        //                 for (var i = 0; i < chars.length; i++) {
        //                   var characteristicID = chars[i]
        //                   if (characteristicID=="FFF2") {//write characteristic
        //                     var value = "5A5A01000B0300010001C5";
        //                     wx.writeBLECharacteristicValueWithDeviceID(deviceID, serviceID, characteristicID, value, function(res){
        //                     })
        //                   }
        //                   if (characteristicID=="FFF1") {//nofity characteristic
        //                     wx.notifyBLECharacteristicValueChangeWithDeviceID(deviceID, serviceID, characteristicID, true, function(res){
        //                       var value = res['value']
        //                       var fhrString  = value.substring(73,81)

        //                       var tocoString = value.substring(88,96)
        //                       var toco = 0
        //                       for (var i = 0; i < tocoString.length; i++) {
        //                         var char = tocoString[i]
        //                         if (char=='1') {
        //                           toco = toco + Math.pow(2,7-i)
        //                         }
        //                       }
        //                       that.target = "toco:" + toco
        //                       // that.target = "toco" + tocoString
        //                     })
        //                   }
        //                 }
        //               })
        //             }
        //           }
        //         });
        //       })
        //     }
        //   },)
        // })
      },
    }
  }
</script>
