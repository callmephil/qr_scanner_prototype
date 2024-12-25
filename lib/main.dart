// ignore_for_file: prefer-match-file-name

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:simple_barcode_scanner/simple_barcode_scanner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'QR Demo'),
    );
  }
}

// ignore: prefer-single-widget-per-file
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Isolate _backgroundIsolate;
  late SendPort _backgroundSendPort;
  StreamSubscription<String>? _barcodeStreamSubscription;
  final List<String> _lastScannedBarcode = [];

  final List<String> _scannedBarcodes = [];

  @override
  void initState() {
    super.initState();
    initBackgroundIsolate();
  }

  @override
  void dispose() {
    _barcodeStreamSubscription?.cancel();
    _backgroundIsolate.kill(priority: Isolate.immediate);
    super.dispose();
  }

  Future<void> initBackgroundIsolate() async {
    final receivePort = ReceivePort();
    _backgroundIsolate =
        await Isolate.spawn(backgroundTask, receivePort.sendPort);

    // Retrieve the send port to communicate with the isolate
    _backgroundSendPort = await receivePort.first;
  }

  static void backgroundTask(SendPort sendPort) async {
    // Listen for data from the main isolate
    final port = ReceivePort();
    sendPort.send(port.sendPort);

    await for (final message in port) {
      if (message is Map<String, dynamic>) {
        final String url = message['url'];
        final SendPort replyTo = message['sendPort'];

        try {
          final response = await http.post(Uri.parse(url));
          if (response.statusCode == 200) {
            final responseData = jsonDecode(response.body);
            replyTo.send({'uuid': responseData['uuid']});
          } else {
            replyTo.send({'error': 'Failed to POST: ${response.statusCode}'});
          }
        } catch (e) {
          replyTo.send({'error': 'Error occurred during POST: $e'});
        }
      }
    }
  }

  void sendRequestToBackground(String url) {
    final responsePort = ReceivePort();

    _backgroundSendPort.send({'url': url, 'sendPort': responsePort.sendPort});

    // reason: we don't know the type of the response
    // ignore: avoid-dynamic
    StreamSubscription<dynamic>? responseSubscription;
    responseSubscription = responsePort.listen((message) {
      if (message is! Map<String, dynamic>) return;
      if (message.containsKey('error')) {
        debugPrint(message['error']);
        return;
      }
      if (!message.containsKey('uuid')) {
        debugPrint('No UUID found in response');
        return;
      }

      final String uuid = message['uuid'];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('POST request successful: $uuid')),
      );
      setState(() {
        _scannedBarcodes.add(uuid);
      });

      responseSubscription?.cancel();
    });
  }

  void handleEvent(String event) {
    if (_lastScannedBarcode.contains(event)) return;
    _lastScannedBarcode.add(event);
    sendRequestToBackground(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_scannedBarcodes.isEmpty)
              const Text('Use the button to scan a QR code'),
            if (_scannedBarcodes.isNotEmpty) const Text('Scanned barcodes:'),
            if (_scannedBarcodes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _scannedBarcodes.length,
                  itemBuilder: (_, index) {
                    return ListTile(title: Text(_scannedBarcodes[index]));
                  },
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _barcodeStreamSubscription?.cancel();
          _barcodeStreamSubscription = SimpleBarcodeScanner.streamBarcode(
            context,
            scanType: ScanType.qr,
            scanFormat: ScanFormat.ONLY_QR_CODE,
            barcodeAppBar: const BarcodeAppBar(
              enableBackButton: true,
              backButtonIcon: Icon(Icons.arrow_back_ios),
            ),
            isShowFlashIcon: true,
            delayMillis: 500,
          ).listen(handleEvent);
        },
        tooltip: 'Scan QR code',
        child: const Icon(Icons.qr_code_2_outlined),
      ),
    );
  }
}
