import 'package:flutter/material.dart';
import 'package:untitled_vegan_app/ui/main/qr_scan_page.dart';

class FeedPage extends StatefulWidget {
  @override
  _FeedPageState createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        child: Text('Scan!'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => QrScanPage()),
          );
        },
      ),
    );
  }
}
