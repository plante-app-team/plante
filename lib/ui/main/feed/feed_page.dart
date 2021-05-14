import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:plante/base/log.dart';
import 'package:plante/model/user_params_controller.dart';
import 'package:plante/ui/scan/barcode_scan_page.dart';

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
          onPressed: () {
            Log.i('Scan clicked');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BarcodeScanPage()),
            );
          },
          child: const Text('Scan!')),
      const ElevatedButton(
          onPressed: Log.startLogsSending, child: Text('Send logs')),
      ElevatedButton(
          onPressed: () async {
            final controller = GetIt.I.get<UserParamsController>();
            final params = await controller.getUserParams();
            await controller.setUserParams(params!.rebuild((e) => e
              ..name = ''
              ..eatsHoney = null
              ..eatsEggs = null
              ..eatsMilk = null));
            exit(0);
          },
          child: const Text('Erase my name and exit')),
    ]));
  }
}
