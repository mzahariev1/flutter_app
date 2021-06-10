import 'package:app/screens/history.dart';
import 'package:app/screens/record.dart';
import 'package:app/screens/report.dart';
import 'package:flutter/material.dart';

import './router_constants.dart';
import './screens/main.dart';

import './screens/about.dart';
import './screens/settings.dart';


Route<dynamic> generateRoute(RouteSettings settings) {

  switch (settings.name) {
    case HomeScreenRoute:
      return MaterialPageRoute(builder: (context) => HomeScreen());
    case HistoryScreenRoute:
      return MaterialPageRoute(builder: (context) => HistoryScreen());
    case SettingsScreenRoute:
      return MaterialPageRoute(builder: (context) => SettingsScreen());
    case AboutScreenRoute:
      return MaterialPageRoute(builder: (context) => AboutScreen());
    case ReportScreenRoute:
      return MaterialPageRoute(builder: (context) => ReportScreen(settings.arguments));
    default:
      ///return MaterialPageRoute(builder: (context) => ErrorView(name: settings.name));

  }

}