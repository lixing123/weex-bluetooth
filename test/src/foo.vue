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
        const wx = weex.requireModule('wx-ble');
        var that = this;
        wx.openBluetoothAdapter(function(res){
          // success
          var services = []
          wx.startBluetoothDevicesDiscoveryWithServices(services,function(res){
            var deviceID   = res['peripheral']['deviceID']
            var deviceName = res['peripheral']['name']
            var index = deviceName.indexOf("LHFH1GMA");
            if (index != -1){
              that.target = "found peripheral " + deviceName + ", connecting..."
              wx.createBLEConnectionWithDeviceID(deviceID, function(res){
                that.target = "connect to ble " + deviceName +" succeed"
                wx.stopBluetoothDeviceDiscovery(function(res){

                })
                wx.getBLEDeviceServicesWithDeviceID(deviceID, function(res){
                  that.target = res
                  for(var i=0;i<res.length;i++){
                    var serviceID = res[i]
                    that.target = that.target + serviceID
                    if (serviceID=="FFF0") {
                      that.target = that.target + ",," + serviceID
                      wx.getBLEDeviceCharacteristicsWithDeviceID(deviceID, serviceID, function(res){
                        that.target = res['characteristics']
                        var chars = res['characteristics']
                        for (var i = 0; i < chars.length; i++) {
                          var characteristicID = chars[i]
                          if (characteristicID=="FFF2") {//write characteristic
                            var value = "5A5A01000B0300010001C5";
                            wx.writeBLECharacteristicValueWithDeviceID(deviceID, serviceID, characteristicID, value, function(res){
                            })
                          }
                          if (characteristicID=="FFF1") {//nofity characteristic
                            wx.onBLECharacteristicValueChange(function(res){
                              var value = res['value']
                              var fhrString  = value.substring(73,81)

                              var tocoString = value.substring(88,96)
                              var toco = 0
                              for (var i = 0; i < tocoString.length; i++) {
                                var char = tocoString[i]
                                if (char=='1') {
                                  toco = toco + Math.pow(2,7-i)
                                }
                              }
                              that.target = "toco:" + toco
                              // that.target = "toco" + tocoString
                            })
                            wx.notifyBLECharacteristicValueChangeWithDeviceID(deviceID, serviceID, characteristicID, true, function(res){
                              that.target = res
                            })
                          }
                        }
                      })
                    }
                  }
                });
              })
            }
          },)
        })
      }
    },

    created: function() {
      var that = this;
      var globalEvent = require('@weex-module/globalEvent');
      globalEvent.addEventListener('foundFhr', function(dict){
        var fhr = dict['fhr'];
        var toco = dict['toco'];
        that.target = "fhr:" + fhr + " toco:" + toco;
      });

    },
  }
</script>
