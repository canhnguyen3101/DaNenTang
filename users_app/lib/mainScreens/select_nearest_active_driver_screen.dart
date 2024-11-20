import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smooth_star_rating_nsafe/smooth_star_rating.dart';
import 'package:toast/toast.dart';
import 'package:users_app/assistants/assistant_methods.dart';
import 'package:users_app/global/global.dart';

// ignore: must_be_immutable
class SelectNearestActiveDriverScreen extends StatefulWidget {
  DatabaseReference? referenceRideRequest;

  SelectNearestActiveDriverScreen({super.key, this.referenceRideRequest});

  @override
  State<SelectNearestActiveDriverScreen> createState() =>
      _SelectNearestActiveDriverScreenState();
}

class _SelectNearestActiveDriverScreenState
    extends State<SelectNearestActiveDriverScreen> {
  String fareAmount = "not found";

  String getFareAmountAccordingToVehicleType(int index) {
    if (tripDirectionDetailsInfo != null) {
      if (dList[index]["car_details"]["type"].toString().contains("Xe máy")) {
        return (AssistantMethods.caculateFareAmountFromOriginToDestination(
                    tripDirectionDetailsInfo!) /
                2.0)
            .toStringAsFixed(1);
      }
      if (dList[index]["car_details"]["type"].toString().contains("4 chỗ")) {
        return (AssistantMethods.caculateFareAmountFromOriginToDestination(
                tripDirectionDetailsInfo!))
            .toStringAsFixed(1);
      }
      if (dList[index]["car_details"]["type"].toString().contains("7 chỗ")) {
        return (AssistantMethods.caculateFareAmountFromOriginToDestination(
                    tripDirectionDetailsInfo!) *
                2.0)
            .toStringAsFixed(1);
      }
    }
    return fareAmount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "TÀI XẾ GẦN BẠN",
          style: TextStyle(
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
          onPressed: () {
            //delere the ride request from database
            widget.referenceRideRequest!.remove();
            ToastContext().init(context);
            Toast.show("Huỷ tìm kiếm tài xế.",
                duration: Toast.lengthShort, gravity: Toast.bottom);

            SystemNavigator.pop();

            // Navigator.pop(context);
          },
        ),
      ),
      body: ListView.builder(
        itemCount: dList.length,
        itemBuilder: (BuildContext context, int index) {
          return GestureDetector(
            onTap: () {
              setState(() {
                choosenDriverId = dList[index]["id"].toString();
              });

              Navigator.pop(context, "driverChoosed");
            },
            child: Card(
              color: Colors.green,
              elevation: 3,
              shadowColor: Colors.white,
              margin: const EdgeInsets.all(8),
              child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Image.asset(
                    "images/${dList[index]["car_details"]["type"]}.png",
                    width: 70,
                  ),
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Driver Name
                    Text(
                      dList[index]["name"],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    //Car model
                    Text(
                      dList[index]["car_details"]["car_model"],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    // Star Ratings
                    SmoothStarRating(
                      rating: dList[index]["ratings"] == null
                          ? 0.0
                          : double.parse(dList[index]["ratings"]),
                      color: Colors.yellow,
                      borderColor: Colors.white,
                      allowHalfRating: true,
                      starCount: 5,
                      size: 15,
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "${getFareAmountAccordingToVehicleType(index)} VNĐ",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    // display duration text
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      tripDirectionDetailsInfo != null
                          ? tripDirectionDetailsInfo!.duration_text!
                          : "no locate",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // Display distance text
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      tripDirectionDetailsInfo != null
                          ? tripDirectionDetailsInfo!.distance_text!
                          : "no locate",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
