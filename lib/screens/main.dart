import 'package:app/router.dart';
import 'package:app/router_constants.dart';
import 'package:app/screens/history.dart';
import 'package:flutter/material.dart';
import 'package:esense_flutter/esense.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'dart:async';
import './settings.dart';
import './record.dart';
import '../connection_status.dart';

void main() => runApp(new MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        accentColor: Colors.deepPurple,
      ),
      title: "Tracker",
      initialRoute: HomeScreenRoute,
      onGenerateRoute: generateRoute,
    ));

const String DEFAULT_ESENSE_NAME = 'eSense-0569';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription _bleEventSubscription;
  StreamSubscription _connectionEventSubscription;
  StreamSubscription _eSenseEventSubscription;

  ConnectionStatus _connectionStatus = ConnectionStatus.BluetoothOn;
  int _selectedTabIndex = 0;

  List<int> _accel;

  @override
  void initState() {
    super.initState();
    _checkBLE();
  }

  @override
  void dispose() {
    _eSenseEventSubscription.cancel();
    _connectionEventSubscription.cancel();
    _bleEventSubscription.cancel();
    ESenseManager.disconnect();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _checkBLE() async {
    bool bleOn = await FlutterBlue.instance.isOn;
    if (!bleOn) _connectionStatus = ConnectionStatus.BluetoothOff;
    _listenToBLEEvents();
  }

  void _listenToBLEEvents() async {
    _bleEventSubscription = FlutterBlue.instance.state.listen((event) {
      if (event == BluetoothState.on) _listenToConnectionEvents();

      setState(() {
        switch (event) {
          case BluetoothState.on:
            _connectionStatus = ConnectionStatus.BluetoothOn;
            break;
          case BluetoothState.off:
            _connectionStatus = ConnectionStatus.BluetoothOff;
            break;
          default:
            break;
        }
      });
    });
  }

  void _listenToConnectionEvents() async {
    bool connected = false;

    _connectionEventSubscription =
        ESenseManager.connectionEvents.listen((event) async {
      if (event.type == ConnectionType.connected) _listenToSensorEvents();

      setState(() {
        if (_connectionStatus == ConnectionStatus.BluetoothOff) return;

        switch (event.type) {
          case ConnectionType.connected:
            _connectionStatus = ConnectionStatus.Connected;
            break;
          case ConnectionType.unknown:
            _connectionStatus = ConnectionStatus.Unknown;
            break;
          case ConnectionType.disconnected:
            _connectionStatus = ConnectionStatus.Disconnected;
            break;
          case ConnectionType.device_found:
            _connectionStatus = ConnectionStatus.DeviceFound;
            break;
          case ConnectionType.device_not_found:
            _connectionStatus = ConnectionStatus.DeviceNotFound;
            break;
          default:
            _connectionStatus = ConnectionStatus.None;
            break;
        }
      });
    });

    if (_connectionStatus == ConnectionStatus.BluetoothOff) return;

    await ESenseManager.connect(DEFAULT_ESENSE_NAME).then((value) {
      setState(() {
        _connectionStatus = connected
            ? ConnectionStatus.Connected
            : ConnectionStatus.Disconnected;
      });
    });
  }

  void _listenToSensorEvents() async {
    _eSenseEventSubscription = ESenseManager.sensorEvents.listen((event) {
      setState(() {
        _accel = event.accel;
      });
    });
    _getSensorData();
  }

  void _getSensorData() async{
    Timer.periodic(Duration(milliseconds: 50), (timer) async {
      if (_connectionStatus == ConnectionStatus.Connected && this.mounted && ESenseManager.connected)
        await ESenseManager.getAccelerometerOffset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trackr"),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.info_outline),
              onPressed: () {
                Navigator.pushNamed(context, AboutScreenRoute);
              })
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: <Widget>[
          _connectionStatusScreen(),
          RecordScreen(_connectionStatus, _accel),
          HistoryScreen(),
          SettingsScreen()
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).accentColor,
        currentIndex: _selectedTabIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            title: Text('Connect'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.adjust),
            title: Text('Record'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            title: Text('History'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ],
      ),
    );
  }

  Widget _connectionStatusScreen() {
    if (_connectionStatus == ConnectionStatus.BluetoothOff) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.bluetooth_disabled,
                size: 200.0,
                color: Theme.of(context).primaryColor,
              ),
              Text(
                "Bluetooth is disabled. \n Please enable Bluetooth now!",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .primaryTextTheme
                    .subhead
                    .copyWith(color: Theme.of(context).accentColor),
              ),
            ],
          ),
        ),
      );
    } else if (_connectionStatus == ConnectionStatus.Connected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(
                Icons.directions_bike,
                size: 200.0,
                color: Theme.of(context).primaryColor,
              ),
              Text(
                "Succesfully connected to: $DEFAULT_ESENSE_NAME \n Happy cycling! \n",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .primaryTextTheme
                    .subhead
                    .copyWith(color: Theme.of(context).accentColor),
              ),
              ButtonTheme(
                buttonColor: Theme.of(context).accentColor,
                height: 48,
                minWidth: 166,
                child: RaisedButton(
                  onPressed: () {
                    ESenseManager.disconnect();
                  },
                  textColor: Colors.white,
                  child: const Text('DISCONNECT'),
                ),
              )
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(
                Icons.bluetooth,
                size: 200.0,
                color: Theme.of(context).accentColor,
              ),
              Text(
                "Bluetooth is enabled. \n You can now connect to: $DEFAULT_ESENSE_NAME. \n",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .primaryTextTheme
                    .subhead
                    .copyWith(color: Theme.of(context).accentColor),
              ),
              ButtonTheme(
                buttonColor: Theme.of(context).primaryColor,
                height: 48,
                minWidth: 166,
                child: RaisedButton(
                  onPressed: () {
                    _listenToConnectionEvents();
                  },
                  textColor: Colors.white,
                  child: const Text('CONNECT'),
                ),
              )
            ],
          ),
        ),
      );
    }
  }

  Widget _recordingScreen(){

  }
}
