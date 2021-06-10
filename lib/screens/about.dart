import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "About Trackr",
                style: TextStyle(fontSize: 24),
              ),
            ),
            Text("Version 1.0.0"),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Center(
                  child: Text(
                    "The Trackr mobile application provides a basic " +
                        "functionality for recording and monitoring your cycling activity." +
                        "The app lets the user record the start and end timestamp of the ride, " +
                        "its duration, the current speed as well as the distance covered." +
                        "The application uses the accelerometer of the eSense earbuds for " +
                        "recording the speed. The user can set a speed limit in the settings menu " +
                        "and if he exceeds it, a signal warning is being played on the earbuds.",
                    style: TextStyle(fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            Text("Copyright (c) 2020, Martin Zahariev, KIT"),
            Text("zahariev@tutanota.com")
          ],
        ),
      ),
    );
  }
}
