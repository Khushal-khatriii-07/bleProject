// import 'package:bleproject/Controller/bleController.dart';
import 'package:bleproject/Controller/bleController.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
// import 'package:get/get.dart';

class BleScanner extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _BleScanner();
}

class _BleScanner extends State<StatefulWidget>{
  late Stream<List<ScanResult>> scanResults;

  @override
  void initState() {
    super.initState();
    startScan();
    scanResults = FlutterBluePlus.scanResults;
  }

  Future<void> startScan() async{
    // listen to scan results
// Note: `onScanResults` only returns live scan results, i.e. during scanning. Use
//  `scanResults` if you want live scan results *or* the results from a previous scan.
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

// Wait for Bluetooth enabled & permission granted
// In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;

// Start scanning w/ timeout
// Optional: use `stopScan()` as an alternative to timeout
    await FlutterBluePlus.startScan(// *or* any of the specified names
        timeout: Duration(seconds:15));

// wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth Scanner'),
      ),
      body: StreamBuilder<List<ScanResult>>(
        stream: scanResults,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final results = snapshot.data!;
            return ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                final deviceName = result.device.name.toString();
                final deviceId = result.device.id.toString();
                final rssi = result.rssi.toString();
                print('device name: ${result.device.name}');

                return Card(
                  child: ListTile(
                    title: Text(deviceName),
                    subtitle: Text(deviceId),
                    trailing: Text('RSSI: $rssi'),
                    onTap: ()=>Get.put(BleController()).ConnectToDevice(result.device),
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.refresh),
        onPressed: () {
          startScan();
        },
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}