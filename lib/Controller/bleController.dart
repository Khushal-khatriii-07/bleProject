import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:convert/convert.dart';

class BleController extends GetxController{
 BluetoothCharacteristic? currentCharacteristic;
  Future scanDevices()async{
    var subscription = FlutterBluePlus.onScanResults.listen((results) {
      if (results.isNotEmpty) {
        ScanResult r = results.last; // the most recently found device
        print('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
      }
    },
      onError: (e) => print(e),
    );

// cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);
    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;

    await FlutterBluePlus.startScan(timeout: Duration(seconds:15));

// wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;


  }
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> ConnectToDevice(BluetoothDevice device)async {
    print(device);
    await device?.connect(timeout: Duration(seconds: 30));
    device?.state.listen((isConnected) {
      if(isConnected == BluetoothDeviceState.connecting){
        print('device connecting to: ${device.name}');
      }else if(isConnected == BluetoothConnectionState.connected){
        print('device is connected: ${device.name}');
      }else{
        print('device is disconnected');
      }
    });

    List<BluetoothService> services = await device.discoverServices();
    for (var i=0; i<services.length; i++){
      print("services: ${services[i].uuid}");
      print("services: ${services[i].characteristics}");
      if(services[i].uuid.toString().toLowerCase() == "1800"){
        final lsOfChar = services[i].characteristics;
        for(var i =0; i<lsOfChar.length; i++){
          if(lsOfChar[i].uuid.toString().toLowerCase()=="2a01"){
             currentCharacteristic = lsOfChar[i];
          }
        }
      }
    }
    if(currentCharacteristic == null){
      print('Not found');
    }else{
      final List<int> raw = await currentCharacteristic!.read();
      final value = hex.encode(raw);
      print('readed successfully: ${value}');
    }
  }
}