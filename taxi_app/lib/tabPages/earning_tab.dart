import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../infoHandler/app_info.dart';
import '../mainScreens/trips_history_screen.dart';

class EarningsTabPage extends StatefulWidget {
  const EarningsTabPage({super.key});

  @override
  State<EarningsTabPage> createState() => _EarningsTabPageState();
}

class _EarningsTabPageState extends State<EarningsTabPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      child: Column(
        children: [
          //earnings
          Container(
            color: Colors.black,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80),
              child: Column(
                children: [
                  const Text(
                    "Tổng doanh thu của bạn:",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    "${Provider.of<AppInfo>(context, listen: false).driverTotalEarning} VNĐ",
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          //total number of trips
          ElevatedButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (c) => TripsHistoryScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Image.asset(
                    "images/car_logo.png",
                    width: 100,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  const Text(
                    "Chuyến đi hoàn thành",
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      Provider.of<AppInfo>(context, listen: false)
                                      .allTripsHistoryInformationList ==
                                  null ||
                              Provider.of<AppInfo>(context, listen: false)
                                  .allTripsHistoryInformationList
                                  .isEmpty
                          ? "0"
                          : Provider.of<AppInfo>(context, listen: false)
                              .allTripsHistoryInformationList
                              .length
                              .toString(),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
