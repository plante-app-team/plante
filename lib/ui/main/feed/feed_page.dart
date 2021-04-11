import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/base/log.dart';
import 'package:untitled_vegan_app/ui/main/qr_scan_page.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        ElevatedButton(
            child: Text('Scan!'),
            onPressed: () {
              Log.i("Scan clicked");
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QrScanPage()),
              );
            }),
        ElevatedButton(
            child: Text('Send logs'),
            onPressed: () {
              Log.startLogsSending();
            }),
      ])
    );
  }
}
