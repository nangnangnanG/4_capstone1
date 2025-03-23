import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'my_infomation_screen.dart';
import 'upload_screen.dart';
import 'search_screen.dart';
import 'event_screen.dart';

class MainTabPage extends StatefulWidget {
  const MainTabPage({super.key});

  @override
  State<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends State<MainTabPage> with SingleTickerProviderStateMixin {
  TabController? controller;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 5, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: <Widget>[
                HomeScreenPage(),
                SearchScreenPage(),
                UploadScreenPage(),
                EventScreenPage(),
                MyInformationScreenPage(),
              ],
              controller: controller,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 5), // 🔥 줄을 위로 살짝 올림
            child: Divider(height: 1, color: Colors.grey), // ✅ 구분선 추가
          ),
          TabBar(
            tabs: <Tab>[
              Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.home),
                    Text("홈", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search),
                    Text("검색", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload),
                    Text("업로드", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_square),
                    Text("이벤트", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              Tab(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person),
                    Text("내정보", style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
            indicator: BoxDecoration(),
            controller: controller,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose(); // ✅ null 체크 추가
    super.dispose();
  }
}
