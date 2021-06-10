import 'dart:convert';

import 'package:app/report_entry.dart';
import 'package:app/router_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _reportsStrings = [];
  List<ReportEntry> _reportEntries = [];

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
    if (!this.mounted) return;

    setState(() {
      _reportsStrings = prefs.getStringList('reports') ?? [];

      _reportsStrings.forEach((element) {
        _reportEntries.add(ReportEntry.fromJson(jsonDecode(element)));
      });
      _reportEntries.sort((a, b) => b.start.compareTo(a.start));
    });
  }

  void _resetHistory() async {
    setState(() {
      _reportEntries = [];
    });
    _saveHistory();
  }

  void _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setStringList('reports',
          _reportEntries.map((e) => jsonEncode(e.toJson())).toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_reportEntries.length == 0) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Icon(
                Icons.close,
                size: 200.0,
                color: Theme.of(context).primaryColor,
              ),
              Text(
                "History is empty!",
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .primaryTextTheme
                    .subhead
                    .copyWith(color: Theme.of(context).accentColor),
              )
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListView.builder(
              itemCount: _reportEntries.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text("Report No." + index.toString()),
                  onTap: () => Navigator.pushNamed(context, ReportScreenRoute,
                      arguments: _reportEntries[index]),
                  onLongPress: () => showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: Text("Delete history entry?"),
                            actions: <Widget>[
                              FlatButton(
                                child: Text("Yes"),
                                onPressed: () => setState(() {
                                  _reportEntries.remove(_reportEntries[index]);
                                  _saveHistory();
                                }),
                              )
                            ],
                          )),
                );
              },
            ),
            Divider(),
            ButtonTheme(
              buttonColor: Theme.of(context).primaryColor,
              height: 48,
              minWidth: 166,
              child: RaisedButton(
                onPressed: () => _resetHistory(),
                textColor: Colors.white,
                child: const Text('CLEAR HISTORY'),
              ),
            )
          ],
        ),
      );
    }
  }
}
