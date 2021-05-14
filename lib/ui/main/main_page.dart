import 'package:flutter/material.dart';
import 'package:plante/ui/main/feed/feed_page.dart';
import 'package:plante/ui/main/map/map_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final _selectedPage = 0;
  final _pageOptions = [
    FeedPage(),
    MapPage(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pageOptions[_selectedPage],
      /*bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: context.strings.main_page_bottom_btn_feed,
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.map),
              label: context.strings.main_page_bottom_btn_map,
          ),
        ],
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.green[900],
        currentIndex: _selectedPage,
        onTap: (index) {
          setState(() {
            _selectedPage = index;
          });
        },
      )*/
    );
  }
}
