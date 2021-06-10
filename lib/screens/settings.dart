import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _speedLimit = 30;
  TextEditingController _controller = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _read() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speedLimit = prefs.getInt("speedLimit") ?? 30;
      _controller.text = prefs.getInt("speedLimit").toString() ?? 30;
    });
  }

  _save() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setInt("speedLimit", _speedLimit);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Set speed limit (in km/h):",
                          style: TextStyle(fontSize: 20),
                        ),
                        Row(
                          children: <Widget>[
                            Text("5"),
                            Expanded(
                              child: Slider(
                                min: 5,
                                max: 50,
                                value: _speedLimit.toDouble(),
                                onChanged: (value) {
                                  _speedLimit = value.toInt();
                                  _save();
                                },
                              ),
                            ),
                            Text("50")
                          ],
                        ),
                        Text(
                          _speedLimit.toString() + " km/h",
                          style: TextStyle(fontSize: 20),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
