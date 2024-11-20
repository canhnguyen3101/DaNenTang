// ignore_for_file: avoid_print

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/global/global.dart';
import 'package:taxi_app/models/user_ride_request_infomation.dart';
import 'package:taxi_app/push_notifications/notification_dialog_box.dart';
import 'package:toast/toast.dart';

class PushNotificationSystem {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMessaging(BuildContext context) async {
    //1. When the app complete close and opened
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? remoteMessage) {
      if (remoteMessage != null) {
        //display ride request inf

        readUserRideRequestInfomation(
            remoteMessage.data["rideRequestId"], context);
      }
    });

    //2. When the app open

    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage) {
      readUserRideRequestInfomation(
          remoteMessage!.data["rideRequestId"], context);
    });

    //3. When the app in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage) {
      //display request inf
      readUserRideRequestInfomation(
          remoteMessage!.data["rideRequestId"], context);
    });
  }

  readUserRideRequestInfomation(
      String userRideRequestId, BuildContext context) {
        FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .child(userRideRequestId)
        .once()
        .then((snapData) {
      if (snapData.snapshot.key != null) {
        audioPlayer.open(Audio("music/music_notification.mp3"));
        print("Play Music");
        audioPlayer.play();
        print("Play Music End Here");

        print("Start Retrieving Data");
        String? rideRequestId = snapData.snapshot.key;
        print("Ride request ID : ${rideRequestId!}");
        print("origin Lat ${(snapData.snapshot.child("origin").child("latitide").value)}");

        // origin LatLng
        double originLat = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["latitide"]);
        double originLng = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["longitude"]);
        // Origin Address
        String originAddress =
            (snapData.snapshot.value! as Map)["originAddress"];

        // destination LatLng
        double destinationLat = double.parse(
            (snapData.snapshot.value! as Map)["destination"]["latitide"]);
        double destinationLng = double.parse(
            (snapData.snapshot.value! as Map)["destination"]["longitude"]);
        String destinationAddress =
            (snapData.snapshot.value! as Map)["destinationAddress"];
        //...
        String userName = (snapData.snapshot.value! as Map)["userName"];
        String userPhone = (snapData.snapshot.value! as Map)["userPhone"];
        //...
        print("End Retrieving Data");

        UserRideRequestInfomation userRideRequestDetails =
            UserRideRequestInfomation();
        userRideRequestDetails.originLatLng = LatLng(originLat, originLng);
        userRideRequestDetails.originAddress = originAddress;

        userRideRequestDetails.destinationLatLng =
            LatLng(destinationLat, destinationLng);
        userRideRequestDetails.destinationAddress = destinationAddress;

        userRideRequestDetails.userName = userName;
        userRideRequestDetails.userPhone = userPhone;

        userRideRequestDetails.rideRequestId = rideRequestId;

        showDialog(
          context: context,
          builder: (BuildContext context) => NotificationDialogBox(
            userRideRequestDetails: userRideRequestDetails,
          ),
        );
      } else {
        Toast.show("ID không tồn tại.",
            duration: Toast.lengthShort, gravity: Toast.bottom);
      }
    });
  }

  Future genarateAndGetToken() async {
    String? registrationToken = await messaging.getToken();

    print("FCM Registration Token: ");
    print(registrationToken);
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(curentFirebaseUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }
}
