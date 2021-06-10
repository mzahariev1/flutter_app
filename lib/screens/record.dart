import 'dart:async';
import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:app/connection_status.dart';
import 'package:app/recording_status.dart';
import 'package:app/report_entry.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordScreen extends StatefulWidget {
  final ConnectionStatus _connectionStatus;
  final List<int> _accel;

  RecordScreen(this._connectionStatus, this._accel);

  @override
  _RecordScreenState createState() => _RecordScreenState();
}

const int ACCEL_CONVERT_RATIO = 209;

class _RecordScreenState extends State<RecordScreen> {
  RecordingStatus _recordingStatus = RecordingStatus.NotStarted;

  DateTime _start;
  DateTime _end;

  Duration _timePassed;
  String _displayDuration = "0:00:00";
  double _distance = 0;
  String _displayDistance = "0 m";
  double _currentSpeed = 0;
  String _displayCurrentSpeed = "0 km/h";
  int _speedLimit = 30;
  double _averageSpeed = 0;
  double _maxSpeed = 0;

  int _passedMicroseconds = 0;

  Stopwatch _swatch = new Stopwatch();
  Timer _timer;
  List<String> _reportsStrings;
  List<int> _prevAccel;
  Color _warningOrNormal;

  @override
  void initState() {
    _read();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _read() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speedLimit = prefs.getInt("speedLimit") ?? 30;
      _reportsStrings = prefs.getStringList('reports') ?? [];
    });
  }

  void _save() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('reports', _reportsStrings);
  }

  void _endActivity(bool save) {
    stopStopwatch();
    if (save) {
      _reportsStrings.add(jsonEncode(ReportEntry(_start, _end, _displayDuration,
              _distance, _averageSpeed, _maxSpeed)
          .toJson()));
      _save();
    }
    _timer.cancel();
    _resetToStart();
  }

  void _resetToStart() {
    setState(() {
      _recordingStatus = RecordingStatus.NotStarted;
      _displayDuration = "0:00:00";
      _distance = 0;
      _displayDistance = "0 m";
      _currentSpeed = 0;
      _displayCurrentSpeed = "0 km/h";
      _averageSpeed = 0;
      _maxSpeed = 0;
      _passedMicroseconds = 0;
    });
  }

  void startTimer() {
    _start = DateTime.now();
    if (_recordingStatus != RecordingStatus.Paused) {
      _timer = Timer(Duration(milliseconds: 250), keepCycling);
    } else {
      _timer.cancel();
    }
  }

  void startStopwatch() {
    _swatch.start();
    startTimer();
  }

  void pauseStopwatch() {
    switch (_recordingStatus) {
      case RecordingStatus.Paused:
        _recordingStatus = RecordingStatus.Recording;
        break;
      case RecordingStatus.Recording:
        _recordingStatus = RecordingStatus.Paused;
        break;
      case RecordingStatus.NotStarted:
      case RecordingStatus.Finished:
        break;
    }
    if (_recordingStatus != RecordingStatus.Paused) {
      startStopwatch();
    } else {
      _passedMicroseconds += _swatch.elapsedMicroseconds;
      _swatch.stop();
      _swatch.reset();
    }
  }

  void stopStopwatch() {
    _end = DateTime.now();
    _swatch.stop();
  }

  void keepCycling() {
    if (_swatch.isRunning && _recordingStatus != RecordingStatus.Paused) {
      startTimer();
    }
    if (!this.mounted || !_swatch.isRunning) return;

    setState(() {
      _timePassed = Duration(
          microseconds: _passedMicroseconds + _swatch.elapsedMicroseconds);

      _displayDuration = _timePassed.inHours.toString().padLeft(1, '0') +
          ':' +
          (_timePassed.inMinutes % 60).toString().padLeft(2, '0') +
          ':' +
          (_timePassed.inSeconds % 60).toString().padLeft(2, '0');

      List<int> accel = widget._accel;

      if (_prevAccel != null) {
        int diff0 = accel[0] - _prevAccel[0];
        int diff1 = accel[1] - _prevAccel[1];
        int diff2 = accel[2] - _prevAccel[2];
        double avg = ((diff0 + diff1 + diff2) / 3) / ACCEL_CONVERT_RATIO;
        if (avg >= 0) {
          _currentSpeed = avg;
        }
        _displayCurrentSpeed =
            (_currentSpeed * 3.6).toStringAsFixed(1).replaceAll('.', ',') +
                " km/h";
      }
      if (_currentSpeed > _maxSpeed) _maxSpeed = _currentSpeed;
      if ((_currentSpeed >= _speedLimit)) {
        _warningOrNormal = Theme.of(context).primaryColor;
      } else {
        _warningOrNormal = Colors.black;
      }
      _distance += _currentSpeed * 0.25;
      if (_distance < 1000)
        _displayDistance =
            _distance.toStringAsFixed(1).replaceAll('.', ',') + ' m';
      else
        _displayDistance =
            (_distance / 1000).toStringAsFixed(2).replaceAll('.', ',') + ' km';
      _averageSpeed = (_distance / _timePassed.inSeconds) * 3.6;
      _prevAccel = accel;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_recordingStatus == RecordingStatus.NotStarted) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(
                Icons.timer,
                size: 200.0,
                color: Theme.of(context).primaryColor,
              ),
              ButtonTheme(
                buttonColor: Theme.of(context).accentColor,
                height: 48,
                minWidth: 166,
                child: RaisedButton(
                  onPressed:
                      (widget._connectionStatus != ConnectionStatus.Connected)
                          ? null
                          : () {
                              setState(() {
                                pauseStopwatch();
                                _recordingStatus = RecordingStatus.Recording;
                              });
                            },
                  textColor: Colors.white,
                  child: const Text('START'),
                ),
              )
            ],
          ),
        ),
      );
    } else if ((_recordingStatus == RecordingStatus.Recording ||
            _recordingStatus == RecordingStatus.Paused) &&
        widget._connectionStatus == ConnectionStatus.Connected) {
      return Scaffold(
        body: Column(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'TIME',
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(
                          _displayDuration,
                          style: TextStyle(fontSize: 56),
                        )
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColor,
                  ),
                  Padding(
                    padding: EdgeInsets.all(38),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'CURRENT SPEED:',
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(
                          _displayCurrentSpeed,
                          style: TextStyle(
                            fontSize: 68,
                            fontWeight: FontWeight.bold,
                            color: _warningOrNormal,
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(
                    color: Theme.of(context).primaryColor,
                  ),
                  Padding(
                    padding: EdgeInsets.all(30),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'DISTANCE',
                          style: TextStyle(fontSize: 20),
                        ),
                        Text(
                          _displayDistance,
                          style: TextStyle(fontSize: 56),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            Divider(
              color: Theme.of(context).primaryColor,
            ),
            Column(
              children: <Widget>[
                ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    ButtonTheme(
                      buttonColor: Theme.of(context).primaryColor,
                      height: 48,
                      minWidth: 166,
                      child: RaisedButton(
                        onPressed: () {
                          setState(() {
                            stopStopwatch();
                            _recordingStatus = RecordingStatus.Finished;
                          });
                        },
                        child: const Text(
                          'STOP',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    ButtonTheme(
                      buttonColor: (_recordingStatus == RecordingStatus.Paused)
                          ? Colors.white
                          : Theme.of(context).accentColor,
                      height: 48,
                      minWidth: 166,
                      child: RaisedButton(
                        onPressed: () {
                          setState(() {
                            pauseStopwatch();
                          });
                        },
                        child: (_recordingStatus == RecordingStatus.Paused)
                            ? Text(
                                "RESUME",
                                style: TextStyle(
                                    color: Theme.of(context).accentColor),
                              )
                            : Text(
                                'PAUSE',
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_recordingStatus == RecordingStatus.Finished) {
      return Scaffold(
        body: Card(
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Report",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Start time:",
                              style: TextStyle(
                                  fontSize: 20, fontStyle: FontStyle.italic),
                            ),
                            Text(
                              _formatDateTime(_start),
                              style: TextStyle(fontSize: 22),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "End time:",
                              style: TextStyle(
                                  fontSize: 20, fontStyle: FontStyle.italic),
                            ),
                            Text(
                              _formatDateTime(_end),
                              style: TextStyle(fontSize: 22),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Duration: (without pauses)",
                              style: TextStyle(
                                  fontSize: 20, fontStyle: FontStyle.italic),
                            ),
                            Text(
                              _displayDuration,
                              style: TextStyle(fontSize: 22),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Distance covered:",
                              style: TextStyle(
                                  fontSize: 20, fontStyle: FontStyle.italic),
                            ),
                            Text(
                              _displayDistance,
                              style: TextStyle(fontSize: 22),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Average speed:",
                              style: TextStyle(
                                  fontSize: 20, fontStyle: FontStyle.italic),
                            ),
                            Text(
                              _averageSpeed.toStringAsFixed(2) + "km/h",
                              style: TextStyle(fontSize: 22),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              "Maximum speed:",
                              style: TextStyle(
                                  fontSize: 20, fontStyle: FontStyle.italic),
                            ),
                            Text(
                              _maxSpeed.toStringAsFixed(2) + "km/h",
                              style: TextStyle(fontSize: 22),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(),
              Column(
                children: <Widget>[
                  ButtonBar(
                    alignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      ButtonTheme(
                        buttonColor: Theme.of(context).primaryColor,
                        height: 48,
                        minWidth: 166,
                        child: RaisedButton(
                          onPressed: () => _endActivity(false),
                          child: Text(
                            'DISCARD',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      ButtonTheme(
                        buttonColor: Theme.of(context).accentColor,
                        height: 48,
                        minWidth: 166,
                        child: RaisedButton(
                          onPressed: () => _endActivity(true),
                          child: Text(
                            'SAVE',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('HH:mm, dd.MM.yy').format(dt);
  }
}
