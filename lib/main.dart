import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 1), () {
      initBluetooth();
    });
    // WidgetsBinding.instance?.addPostFrameCallback((_) => initBluetooth());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text(tips),
                ),
              ],
            ),
            Divider(),
            StreamBuilder<List<BluetoothDevice>>(
              stream: bluetoothPrint.scanResults,
              initialData: [],
              builder: (c, snapshot) => (snapshot.data != null)
                  ? Column(
                      children: snapshot.data!
                          .map((d) => ListTile(
                                title: Text(d.name ?? ''),
                                subtitle: Text(d.address ?? ''),
                                onTap: () async {
                                  setState(() {
                                    _device = d;
                                  });
                                },
                                trailing: _device != null && _device!.address == d.address
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : null,
                              ))
                          .toList(),
                    )
                  : Container(),
            ),
            Divider(),
            Container(
              padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      OutlinedButton(
                        child: Text('connect'),
                        onPressed: _connected
                            ? null
                            : () async {
                                if (_device != null && _device!.address != null) {
                                  await bluetoothPrint.connect(_device!);
                                } else {
                                  setState(() {
                                    tips = 'please select device';
                                  });
                                  print('please select device');
                                }
                              },
                      ),
                      SizedBox(width: 10.0),
                      OutlinedButton(
                        child: Text('disconnect'),
                        onPressed: _connected
                            ? () async {
                                await bluetoothPrint.disconnect();
                              }
                            : null,
                      ),
                    ],
                  ),
                  OutlinedButton(
                    child: Text('print receipt(esc)'),
                    onPressed: _connected
                        ? () async {
                            Map<String, dynamic> config = Map();
                            List<LineText> list = [];
                            list.add(LineText(
                                type: LineText.TYPE_TEXT,
                                content: 'A Title',
                                weight: 1,
                                align: LineText.ALIGN_CENTER,
                                linefeed: 1));
                            list.add(LineText(
                                type: LineText.TYPE_TEXT,
                                content: 'this is conent left',
                                weight: 0,
                                align: LineText.ALIGN_LEFT,
                                linefeed: 1));
                            list.add(LineText(
                                type: LineText.TYPE_TEXT,
                                content: 'this is conent right',
                                align: LineText.ALIGN_RIGHT,
                                linefeed: 1));
                            list.add(LineText(linefeed: 1));

                            // ByteData data =
                            //     await rootBundle.load("assets/bluetooth_print.png");
                            // List<int> imageBytes =
                            //     data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                            // String base64Image = base64Encode(imageBytes);
                            // list.add(LineText(
                            //     type: LineText.TYPE_IMAGE,
                            //     content: base64Image,
                            //     align: LineText.ALIGN_CENTER,
                            //     linefeed: 1));

                            await bluetoothPrint.printReceipt(config, list);
                          }
                        : null,
                  ),
                  OutlinedButton(
                    child: Text('print label(tsc)'),
                    onPressed: _connected
                        ? () async {
                            Map<String, dynamic> config = Map();
                            config['width'] = 40; // 标签宽度，单位mm
                            config['height'] = 70; // 标签高度，单位mm
                            config['gap'] = 2; // 标签间隔，单位mm

                            // x、y坐标位置，单位dpi，1mm=8dpi
                            List<LineText> list = [];
                            list.add(LineText(
                                type: LineText.TYPE_TEXT, x: 10, y: 10, content: 'A Title'));
                            list.add(LineText(
                                type: LineText.TYPE_TEXT,
                                x: 10,
                                y: 40,
                                content: 'this is content'));
                            list.add(LineText(
                                type: LineText.TYPE_QRCODE, x: 10, y: 70, content: 'qrcode i\n'));
                            list.add(LineText(
                                type: LineText.TYPE_BARCODE, x: 10, y: 190, content: 'qrcode i\n'));

                            List<LineText> list1 = [];
                            ByteData data = await rootBundle.load("assets/images/guide3.png");
                            List<int> imageBytes =
                                data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
                            String base64Image = base64Encode(imageBytes);
                            list1.add(LineText(
                              type: LineText.TYPE_IMAGE,
                              x: 10,
                              y: 10,
                              content: base64Image,
                            ));

                            await bluetoothPrint.printLabel(config, list);
                            await bluetoothPrint.printLabel(config, list1);
                          }
                        : null,
                  ),
                  OutlinedButton(
                    child: Text('print selftest'),
                    onPressed: _connected
                        ? () async {
                            await bluetoothPrint.printTest();
                          }
                        : null,
                  )
                ],
              ),
            )
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   child: Icon(Icons.ac_unit),
      //   onPressed: () {
      //     initBluetooth();
      //   },
      // ),
      floatingActionButton: StreamBuilder<bool>(
        stream: bluetoothPrint.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data ?? false) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => bluetoothPrint.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => bluetoothPrint.startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }

  Future<void> initBluetooth() async {
    bluetoothPrint.startScan(timeout: Duration(seconds: 4));

    bool isConnected = await bluetoothPrint.isConnected ?? false;

    bluetoothPrint.state.listen((state) {
      print('cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            tips = 'connect success';
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }
}
