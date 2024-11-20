// ignore_for_file: must_be_immutable, avoid_print

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/assistants/assistant_methods.dart';
import 'package:taxi_app/mainScreens/new_trip_screen.dart';
import 'package:taxi_app/models/user_ride_request_infomation.dart';
import 'package:toast/toast.dart';

import '../global/global.dart';

class NotificationDialogBox extends StatefulWidget {
  UserRideRequestInfomation? userRideRequestDetails;

  NotificationDialogBox({super.key, this.userRideRequestDetails});

  @override
  State<NotificationDialogBox> createState() => _NotificationDialogBoxState();
}

class _NotificationDialogBoxState extends State<NotificationDialogBox> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      elevation: 2,
      child: Container(
        margin: const EdgeInsets.all(8),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[800],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 14,
            ),
            Image.asset(
              "images/car_logo.png",
              width: 160,
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              "Chuyến đi mới",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // origin location with icons.
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 1.0, right: 8.0),
                        child: Image.asset(
                          "images/origin.png",
                          width: 30,
                          height: 30,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          parseOriginAddress(
                              widget.userRideRequestDetails!.originAddress!),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 35.0,
                  ),

                  //destination location with icons.
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 1.0, right: 8.0),
                        child: Image.asset(
                          "images/destination.png",
                          width: 30,
                          height: 30,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.userRideRequestDetails!.destinationAddress!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 14.0,
            ),
            const Divider(
              height: 3,
              thickness: 3,
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      //cancle the rideRequest.
                      audioPlayer.pause();
                      audioPlayer.stop();
                      audioPlayer = AssetsAudioPlayer();

                      // Cancel the Request
                      FirebaseDatabase.instance
                          .ref()
                          .child("All Ride Request")
                          .child(widget.userRideRequestDetails!.rideRequestId!)
                          .remove()
                          .then((value) {
                        FirebaseDatabase.instance
                            .ref()
                            .child("drivers")
                            .child(curentFirebaseUser!.uid)
                            .child("newRideStatus")
                            .set("idle")
                            .then((value) {
                          FirebaseDatabase.instance
                              .ref()
                              .child("drivers")
                              .child(curentFirebaseUser!.uid)
                              .child("tripHistory")
                              .child(
                              widget.userRideRequestDetails!.rideRequestId!);
                        }).then((value) {
                          ToastContext().init(context);
                          Toast.show("Hủy yêu cầu thành công",
                              duration: Toast.lengthShort, gravity: Toast.bottom);
                        });
                      });

                      Navigator.pop(context);
                    },
                    child: Text(
                      "Huỷ".toUpperCase(),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                  const SizedBox(
                    width: 25.0,
                  ),
                  ElevatedButton(
                    style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      audioPlayer.pause();
                      audioPlayer.stop();
                      audioPlayer = AssetsAudioPlayer();
                      //cancle the rideRequest.

                      acceptRideRequest(context);
                    },
                    child: Text(
                      "Chấp nhận".toUpperCase(),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  String parseOriginAddress(String originAddress) {
    List<String> parsed = originAddress.split(" ");
    if (parsed.isNotEmpty && parsed.length > 1) {
      parsed.removeAt(0);
    }

    originAddress = "";
    for (String s in parsed) {
      originAddress += "$s ";
    }
    return originAddress;
  }

  acceptRideRequest(BuildContext context) {
    // Khởi tạo toast
    ToastContext().init(context);
    String getRideRequestId = "";
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(curentFirebaseUser!.uid)
        .child("newRideStatus")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        getRideRequestId = snap.snapshot.value.toString();
        print("1. bck This is get Ride Request Id: ");
        print(getRideRequestId);
      } else {
        // Show Toast
        Toast.show("Yêu cầu không tồn tại",
            duration: Toast.lengthShort, gravity: Toast.bottom);
      }

      print("1.bck This is userRideRequestDetails!.rideRequestId: ");
      print(widget.userRideRequestDetails!.rideRequestId.toString());
      // Show Toast
      Toast.show(
          "getRideRequestId: ${widget.userRideRequestDetails!.rideRequestId}",
          duration: Toast.lengthLong,
          gravity: Toast.bottom);

      if (getRideRequestId ==
          widget.userRideRequestDetails!.rideRequestId.toString()) {
        // Send driver to newRideScreen
        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(curentFirebaseUser!.uid)
            .child("newRideStatus")
            .set("accepted");

        AssistantMethods.pauseLiveLocationUpdates();

        // Trip started now - send driver to tripScreen
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (c) =>
                    NewTripScreen(
                        userRideRequestDetails: widget
                            .userRideRequestDetails)));
      } else {
        // Show Toast
        Toast.show("Yêu cầu không tồn tại",
            duration: Toast.lengthShort, gravity: Toast.bottom);
      }
    });
  }
}
