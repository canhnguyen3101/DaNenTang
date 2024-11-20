// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:ffi';

import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:users_app/assistants/request_assistant.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/global/map_key.dart';
import 'package:users_app/infoHandler/app_info.dart';
import 'package:users_app/models/direction_details.dart';
import 'package:users_app/models/directions.dart';
import 'package:users_app/models/user_model.dart';
import 'package:http/http.dart' as http;

import '../models/trips_history_model.dart';

class AssistantMethods {
  static Future<String> searchAddressForGeographicCoOrdinates(
      Position position, context) async {
    String apiUrl =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$mapKey";

    // String apiUrl =
    //     "https://maps.googleapis.com/maps/api/geocode/json?latlng=21.5869527,105.8040082&key=AIzaSyC0hUQhBYFddpsfGb64zwbbsqB9cP-3ovs";
    print(apiUrl);

    String humanReadableAddress = "";

    var requestResponse = await RequestAssistant.receiveRequest(apiUrl);

    print("1. requestResponse: == $requestResponse");

    if (requestResponse != "Error Occurred, Failed. No Response.") {
      humanReadableAddress = requestResponse["results"][0]["formatted_address"];

      Directions userPickUpAddress = Directions();
      userPickUpAddress.locationLatitude = position.latitude;
      userPickUpAddress.locationLongitude = position.longitude;
      userPickUpAddress.locationName = humanReadableAddress;

      Provider.of<AppInfo>(context, listen: false)
          .updatePickUpLocationAddress(userPickUpAddress);
    }

    return humanReadableAddress;
  }

  static Future<UserModel?> readCurrentOnlineUserInfo() async {
    curentFirebaseUser = fAuth.currentUser;

    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(curentFirebaseUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
        return UserModel.fromSnapshot(snap.snapshot);
      } else {
        return null;
      }
    });
    return userModelCurrentInfo;
  }

  static Future<DirectionDetailsInfo?>
      obtainOriginToDestinationDirectionDetails(
          LatLng origionPosition, LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origionPosition.latitude},${origionPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    // Request
    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);

// if the reponse is null || error || request limited
    if (responseDirectionApi
        .toString()
        .contains("Error Occurred, Failed. No Response.")) {
      print("1. Trip Info null");
      return null;
    }

// Chỉ print đến dòng này
    print("1. Trip Info responseDirectionApi = $responseDirectionApi");

    // Replace
    // DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo(
    //     distance_text: responseDirectionApi["routes"][0]["legs"][0]["distance"]
    //         ["text"],
    //     distance_value: responseDirectionApi["routes"][0]["legs"][0]["distance"]
    //         ["value"],
    //     duration_text: responseDirectionApi["routes"][0]["legs"][0]["duration"]
    //         ["text"],
    //     duration_value: responseDirectionApi["routes"][0]["legs"][0]["duration"]
    //         ["value"],
    //     e_points: responseDirectionApi["routes"][0]["overview_polyline"]
    //         ["points"]);

    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();

// Distance
    directionDetailsInfo.distance_text =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];
    directionDetailsInfo.distance_value =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];
// Duration
    directionDetailsInfo.duration_text =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];
    directionDetailsInfo.duration_value =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];
// poly Points
    directionDetailsInfo.e_points =
        responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    print(
        "1. Trip Info directionDetailsInfo PolyLine ${directionDetailsInfo.toString()}");
    return directionDetailsInfo;
  }

//Tinh thoi gian
  static double caculateFareAmountFromOriginToDestination(
      DirectionDetailsInfo directionDetailsInfo) {
    double timeTravelFareAmountPerMinute =
        (directionDetailsInfo.duration_value! / 60.0) * 0.1;

    double distanceTravelFareAmountPerKilometer =
        (directionDetailsInfo.duration_value! / 1000.0) * 0.1;

    double totalFareAmount =
        timeTravelFareAmountPerMinute + distanceTravelFareAmountPerKilometer;

    double localCurrentTotalFare = totalFareAmount * 23000.0;

    return double.parse(localCurrentTotalFare.toStringAsFixed(1));
  }

  static sendNotificationToDriverNow(
      String deviceRegistrationToken, String userRideRequestId, context) async {
    String destinationAddress = userDropOffAddress;
    //  var destinationAddressSub =
    // Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map<String, String> headerNotifycation = {
      'Content-Type': 'application/json',
      'Authorization': cloudMessaginServerToken,
    };

    Map bodyNotification = {
      "body": "Destination Address, \n$destinationAddress.",
      "title": "New Trip Request"
    };

    Map dataMap = {
      "click_action": "FLUTTER_NOTIFICATION_CLICK",
      "id": "1",
      "status": "done",
      "rideRequestId": userRideRequestId
    };

    Map officialNotificationFormat = {
      "notification": bodyNotification,
      "data": dataMap,
      "priority": "high",
      "to": deviceRegistrationToken,
    };

    var responseNotification = http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: headerNotifycation,
      body: jsonEncode(officialNotificationFormat),
    );

    print("1. responseNotification == $responseNotification");
  }

// READ TRIP KEY: tripKey = rideRequestKey
  static void readTripsKeysForOnlineUser(context) {
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .orderByChild("userName")
        .equalTo(userModelCurrentInfo!.name)
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        Map keysTripsId = snap.snapshot.value as Map;

        //count total number trips and share it with Provider
        int overAllTripsCounter = keysTripsId.length;
        Provider.of<AppInfo>(context, listen: false)
            .updateOverAllTripsCounter(overAllTripsCounter);

        //share trips keys with Provider
        List<String> tripsKeysList = [];
        keysTripsId.forEach((key, value) {
          tripsKeysList.add(key);
        });
        Provider.of<AppInfo>(context, listen: false)
            .updateOverAllTripsKeys(tripsKeysList);

        //get trips keys data - read trips complete information
        readTripsHistoryInformation(context);
      }
    });
  }

// For History
  static void readTripsHistoryInformation(context) {
    if (Provider.of<AppInfo>(context, listen: false)
        .allTripsHistoryInformationList
        .isNotEmpty) {
      Provider.of<AppInfo>(context, listen: false)
          .allTripsHistoryInformationList
          .clear();
    }
    var tripsAllKeys =
        Provider.of<AppInfo>(context, listen: false).historyTripsKeysList;

    for (String eachKey in tripsAllKeys) {
      FirebaseDatabase.instance
          .ref()
          .child("All Ride Request")
          .child(eachKey)
          .once()
          .then((snap) {
        var eachTripHistory = TripsHistoryModel.fromSnapshot(snap.snapshot);

        if ((snap.snapshot.value as Map)["status"] == "ended") {
          //update-add each history to OverAllTrips History Data List
          Provider.of<AppInfo>(context, listen: false)
              .updateOverAllTripsHistoryInformation(eachTripHistory);
        }
      });
    }
  }
  //...
}
