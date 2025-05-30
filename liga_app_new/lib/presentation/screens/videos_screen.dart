import 'package:flutter/material.dart';

class VideosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Videos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade900,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Text('Contenido de Videos', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
