import 'package:flutter/material.dart';
import 'package:taxi_app/tabPages/earning_tab.dart';
import 'package:taxi_app/tabPages/home_tab.dart';
import 'package:taxi_app/tabPages/profile_tab.dart';
import 'package:taxi_app/tabPages/ratings_tab.dart';

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  TabController? tabController;
  int selectedIndex = 0;

  onItemClicked(int index) {
    setState(() {
      selectedIndex = index;
      tabController!.index = selectedIndex;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics:
            const NeverScrollableScrollPhysics(), //ngăn người dùng vuốt trang
        controller: tabController,
        children: const [
          HomeTabPage(),
          EarningsTabPage(),
          RatingsTabPage(),
          ProfileTabPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: "Màn hình chính"),
          BottomNavigationBarItem(
              icon: Icon(Icons.credit_card), label: "Doanh thu"),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: "Đánh giá"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: "Trang cá nhân"),
        ],
        unselectedItemColor: Colors.green[100],
        selectedItemColor: Colors.yellow[400],
        backgroundColor: Colors.green[900],
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontSize: 14),
        showSelectedLabels: true,
        currentIndex: selectedIndex,
        onTap: onItemClicked,
      ),
    );
  }
}
