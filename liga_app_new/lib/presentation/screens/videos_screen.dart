import 'package:flutter/material.dart';

class VideosScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Videos'),
        backgroundColor: Colors.blueGrey.shade900,
      ),
      body: Center(
        child: Text('Contenido de Videos', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
