import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:network_tools/network_tools.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:vernet/main.dart';

class HostScanPage extends StatefulWidget {
  const HostScanPage({Key? key}) : super(key: key);

  @override
  _HostScanPageState createState() => _HostScanPageState();
}

class _HostScanPageState extends State<HostScanPage>
    with TickerProviderStateMixin {
  Set<ActiveHost> _devices = {};
  double _progress = 0;
  StreamSubscription<ActiveHost>? _streamSubscription;

  void _getDevices() async {
    _devices.clear();
    final String? ip = await (NetworkInfo().getWifiIP());
    if (ip != null && ip.isNotEmpty) {
      final String subnet = ip.substring(0, ip.lastIndexOf('.'));
      //TODO: Add in settings for maxnetworksize
      final stream = HostScanner.discover(subnet,
          maxHost: appSettings.maxNetworkSize, progressCallback: (progress) {
        print('Progress : $progress');
        if (this.mounted) {
          setState(() {
            _progress = progress;
          });
        }
      });

      _streamSubscription = stream.listen((ActiveHost device) {
        print('Found device: ${device.ip}');
        setState(() {
          _devices.add(device);
        });
      }, onDone: () {
        print('Scan completed');
        if (this.mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getDevices();
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan for Devices'),
        actions: [
          HostScanner.isScanning
              ? Container(
                  margin: EdgeInsets.only(right: 20.0),
                  child: new CircularPercentIndicator(
                    radius: 20.0,
                    lineWidth: 2.5,
                    percent: _progress / 100,
                    backgroundColor: Colors.grey,
                    progressColor: Colors.white,
                  ),
                )
              : IconButton(
                  onPressed: _getDevices,
                  icon: Icon(Icons.refresh),
                ),
        ],
      ),
      body: Center(
        child: _devices.isEmpty
            ? CircularProgressIndicator.adaptive()
            : Column(
                children: [
                  Expanded(
                      child: ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      ActiveHost device =
                          SplayTreeSet.from(_devices).toList()[index];

                      return ListTile(
                        title: Text(device.make),
                        subtitle: Text(device.ip),
                      );
                    },
                  ))
                ],
              ),
      ),
    );
  }
}
