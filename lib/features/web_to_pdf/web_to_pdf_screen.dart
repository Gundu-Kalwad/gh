import 'package:flutter/material.dart';

class WebToPdfScreen extends StatelessWidget {
  const WebToPdfScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Web to PDF'),
      ),
      body: const Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }
}