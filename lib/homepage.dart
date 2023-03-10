// Copyright 2020 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

// import 'package:flutter_blue/flutter_blue.dart';
import 'package:platform_design/bluetooth/bluetooth-bonded-devices.dart';
import 'package:platform_design/bluetooth/bluetooth-connect-serial.dart';
import 'package:platform_design/main.dart';

import 'bluetooth/bluetooth-connect.dart';
import 'song_detail_tab.dart';
import 'utils.dart';
import 'widgets.dart';
// import 'bluetooth/bluetooth-off-screen.dart';
import 'dart:async';

// final FlutterBlue flutterBlue = FlutterBlue.instance;
// enum BluetoothState { disabled, enabled, connected, disconnected, loading }
// final List<BluetoothDevice> devicesList = <BluetoothDevice>[];

class OptionTab extends StatefulWidget {
  static const title = 'Home';
  static const androidIcon = Icon(Icons.home);
  static const iosIcon = Icon(CupertinoIcons.home);

  const OptionTab({super.key, this.androidDrawer});

  final Widget? androidDrawer;

  @override
  State<OptionTab> createState() => _OptionTabState();
}

class _OptionTabState extends State<OptionTab> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String bluetoothAddress = "...";
  String bluetoothName = "...";

  static const _itemsLength = 1;

  final _androidRefreshKey = GlobalKey<RefreshIndicatorState>();
  bool isScanning = false;
  late List<MaterialColor> colors;
  late List<String> songNames;

  @override
  void initState() {
    _setData();
    super.initState();

    isScanning = widget.start;

    if (isScanning) {
      isScanning();
    }
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if ((await FlutterBluetoothSerial.instance.isEnabled) ?? false) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // print(FlutterBluetoothSerial.instance.getBondedDevices());
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          bluetoothAddress = address!;
        });
      });
    });

    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((devices) => {devices.map((device) => print(device.address))});

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        bluetoothName = name!;
      });
    });

    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // // Discoverable mode is disabled when Bluetooth gets disabled
        // _discoverableTimeoutTimer = null;
        // _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    // _collectingTask?.dispose();
    // _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  void _setData() {
    colors = getRandomColors(_itemsLength);
    songNames = getRandomNames(_itemsLength);
  }

  Future<void> _refreshData() {
    return Future.delayed(
      // This is just an arbitrary delay that simulates some network activity.
      const Duration(seconds: 2),
      () => setState(() => _setData()),
    );
  }

  Widget _listBuilder(BuildContext context, int index) {
    if (index >= _itemsLength) return Container();

    // Show a slightly different color palette. Show poppy-ier colors on iOS
    // due to lighter contrasting bars and tone it down on Android.
    final color = defaultTargetPlatform == TargetPlatform.iOS
        ? colors[index]
        : colors[index].shade400;

    return SafeArea(
      top: false,
      bottom: false,
      child: Hero(
        tag: index,
        child: HeroAnimatingSongCard(
          song: songNames[index],
          color: color,
          heroAnimation: const AlwaysStoppedAnimation(0),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (context) => SongDetailTab(
                id: index,
                song: songNames[index],
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _togglePlatform() {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
    } else {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    }

    // This rebuilds the application. This should obviously never be
    // done in a real app but it's done here since this app
    // unrealistically toggles the current platform for demonstration
    // purposes.
    WidgetsBinding.instance.reassembleApplication();
  }

  // ===========================================================================
  // Non-shared code below because:
  // - Android and iOS have different scaffolds
  // - There are different items in the app bar / nav bar
  // - Android has a hamburger drawer, iOS has bottom tabs
  // - The iOS nav bar is scrollable, Android is not
  // - Pull-to-refresh works differently, and Android has a button to trigger it too
  //
  // And these are all design time choices that doesn't have a single 'right'
  // answer.
  // ===========================================================================

  Widget _buildAndroid(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(OptionTab.title),
        /*actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async =>
                await _androidRefreshKey.currentState!.show(),
          ),
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _togglePlatform,
          ),
        ],*/
      ),
      drawer: widget.androidDrawer,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${bluetoothAddress}: ${bluetoothName}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 10), // Column Padding
            ElevatedButton.icon(
                icon: const Icon(
                  // <-- Icon
                  Icons.device_hub_outlined,
                  size: 24.0,
                ),
                onPressed: () {
                  // Navigator.pop(context);
                  Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DiscoveryPage()));
                },
                label: const Text('Connect to Glasses')),
            ElevatedButton.icon(
                icon: const Icon(
                  // <-- Icon
                  Icons.device_hub_outlined,
                  size: 24.0,
                ),
                onPressed: () {
                  // Navigator.pop(context);
                  Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BluetoothConnect()));
                },
                label: const Text('Connect to Bluetooth')),
            ElevatedButton.icon(
                icon: const Icon(
                  // <-- Icon
                  Icons.device_hub_outlined,
                  size: 24.0,
                ),
                onPressed: () {
                  // Navigator.pop(context);
                  Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SelectBondedDevicePage()));
                },
                label: const Text('Show Bonded Devices')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(
          Icons.bluetooth_connected_sharp,
          color: Colors.white,
          size: 29,
        ),
        backgroundColor: Colors.black,
        tooltip: 'Capture Picture',
        elevation: 5,
        splashColor: Colors.grey,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation
          .centerFloat, /*RefreshIndicator(
        key: _androidRefreshKey,
        onRefresh: _refreshData,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: _itemsLength,
          itemBuilder: _listBuilder,
        ),
      ),*/
    );
  }

  Widget _buildIos(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar(
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _togglePlatform,
            child: const Icon(CupertinoIcons.shuffle),
          ),
        ),
        CupertinoSliverRefreshControl(
          onRefresh: _refreshData,
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                _listBuilder,
                childCount: _itemsLength,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(context) {
    return PlatformWidget(
      androidBuilder: _buildAndroid,
      iosBuilder: _buildIos,
    );
  }
}

bool checkBluetoothStatus() {
  return true;
}
