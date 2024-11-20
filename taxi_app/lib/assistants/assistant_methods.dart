// ignore_for_file: must_be_immutable, avoid_print, use_build_context_synchronously

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:taxi_app/assistants/request_assistant.dart';

import '../global/global.dart';
import '../global/map_key.dart';
import '../infoHandler/app_info.dart';
import '../models/direction_details.dart';
import '../models/directions.dart';
import '../models/trips_history_model.dart';
import '../models/user_model.dart';

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

  static void readCurrentOnlineUserInfo() async {
    curentFirebaseUser = fAuth.currentUser;

    DatabaseReference userRef = FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(curentFirebaseUser!.uid);

    userRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        userModelCurrentInfo = UserModel.fromSnapshot(snap.snapshot);
      }
    });
  }

  static Future<DirectionDetailsInfo?>
      obtainOriginToDestinationDirectionDetails(
          LatLng origionPosition, LatLng destinationPosition) async {
    String urlOriginToDestinationDirectionDetails =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origionPosition.latitude},${origionPosition.longitude}&destination=${destinationPosition.latitude},${destinationPosition.longitude}&key=$mapKey";
    var responseDirectionApi = await RequestAssistant.receiveRequest(
        urlOriginToDestinationDirectionDetails);

    print(
        "Phản hồi urlOriginToDestinationDirectionDetails =$responseDirectionApi");

    if (responseDirectionApi == 'Error Occurred, Failed. No Response.') {
      return null;
    }
    DirectionDetailsInfo directionDetailsInfo = DirectionDetailsInfo();
    print("Start getting direction Details Info! ");
    directionDetailsInfo.e_points =
        responseDirectionApi["routes"][0]["overview_polyline"]["points"];

    directionDetailsInfo.distance_text =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["text"];

    directionDetailsInfo.distance_value =
        responseDirectionApi["routes"][0]["legs"][0]["distance"]["value"];

    directionDetailsInfo.duration_text =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["text"];

    directionDetailsInfo.duration_value =
        responseDirectionApi["routes"][0]["legs"][0]["duration"]["value"];

    print("End getting direction Details Info! ");
    return directionDetailsInfo;
  }

  static pauseLiveLocationUpdates() {
    print("Start Pause Live Location Updates!");
    streamSubscriptionPosition!.pause();
    Geofire.removeLocation(curentFirebaseUser!.uid);
    print("End Pause Live Location Updates!");
  }

  static resumeLiveLocationUpdates() {
    print("Resume Live Location Updates!");
    streamSubscriptionPosition!.resume();
    Geofire.setLocation(curentFirebaseUser!.uid,
        driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
    print("End Live Location Updates!");
  }

  //Tinh thoi gian
  static int caculateFareAmountFromOriginToDestination(
      DirectionDetailsInfo directionDetailsInfo) {
    double timeTravelFareAmountPerMinute =
        (directionDetailsInfo.duration_value! / 60.0) * 0.1;

    double distanceTravelFareAmountPerKilometer =
        (directionDetailsInfo.duration_value! / 1000.0) * 0.1;

    double totalFareAmount =
        timeTravelFareAmountPerMinute + distanceTravelFareAmountPerKilometer;
    // VND price
    double localCurrentTotalFare = totalFareAmount * 23000.0;

    if (DriverVehicleType!.contains("Xe máy")) {
      int resultAmount = ((localCurrentTotalFare.truncate()) / 2) as int;
      return resultAmount;
    }

    if (DriverVehicleType!.contains("4 chỗ")) {
      return localCurrentTotalFare.truncate();
    }

    if (DriverVehicleType!.contains("7 chỗ")) {
      int resultAmount = ((localCurrentTotalFare.truncate()) * 2);
      return resultAmount;
    } else {
      return localCurrentTotalFare.truncate();
    }
  }

  // READ TRIP KEY: tripKey = rideRequestKey
  static void readTripsKeysForOnlineDriver(context) {
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .orderByChild("driverId")
        .equalTo(fAuth.currentUser!.uid)
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

  // Read Driver Earnings
  static void readDriverEarnings(context) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(fAuth.currentUser!.uid)
        .child("earnings")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String driverEarnings = snap.snapshot.value.toString();
        Provider.of<AppInfo>(context, listen: false)
            .updateDriverTotalEarnings(driverEarnings);
      }
    });

    readTripsKeysForOnlineDriver(context);
  }

  static void readDriverRatings(context) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(fAuth.currentUser!.uid)
        .child("ratings")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String driverRatings = snap.snapshot.value.toString();
        Provider.of<AppInfo>(context, listen: false)
            .updateDriverAverageRatings(driverRatings);
      }
    });
  }
}
