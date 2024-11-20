// ignore_for_file: must_be_immutable, avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:taxi_app/global/global.dart';
import 'package:taxi_app/models/user_ride_request_infomation.dart';
import 'package:taxi_app/widgets/fare_amount_collection_dialog.dart';

import '../assistants/assistant_methods.dart';
import '../models/direction_details.dart';
import '../widgets/progress_dialog.dart';

class NewTripScreen extends StatefulWidget {
  UserRideRequestInfomation? userRideRequestDetails;

  NewTripScreen({
    super.key,
    this.userRideRequestDetails,
  });

  @override
  State<NewTripScreen> createState() => _NewTripScreenState();
}

class _NewTripScreenState extends State<NewTripScreen> {
  GoogleMapController? newTripGoogleMapController;

  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  String? buttonTitle = "Tôi đã đến";
  Color? buttonColor = Colors.green;

  Set<Marker> setOfMarkers = <Marker>{};
  Set<Circle> setOfCircle = <Circle>{};
  Set<Polyline> setOfPolyline = <Polyline>{};

  List<LatLng> polyLinePositionCoordinates = [];

  PolylinePoints polylinePoints = PolylinePoints();

  double mapPadding = 0;
  BitmapDescriptor? iconAnimatedMarker;
  var geoLocation = Geolocator();

  Position? onlineDriverCurrentPosition;

  // when driver accerrp the user ride

  // origionLatLng = driverCurrent location
  // destinationLatLng = user PickUp location

  // step 2. driver already picked up the user in his
  // origionLatLng = driverCurrent location => driver current location
  // destinationLatLng = user PickUp location

  Future<String> drawPolyLineFromOriginToDestination(
      LatLng originLatLng, LatLng destinationLatLng) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: "Đang vẽ đường đi",
      ),
    );
    print("1. Đang vẽ đường đi!...");
    DirectionDetailsInfo? directionDetailsInfo =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);
    print("1. Đã vẽ xong đường đi!...");
    if (directionDetailsInfo != null) {
      print("1. Vị trí không rỗng directuinDetailsInfo != null");
      print(
          "1. Vị trí Bắt đầu và Điểm đến do người dùng Yêu Cầu :== ${directionDetailsInfo.e_points}");
    }
    print(directionDetailsInfo!.e_points!);

    print("1. These are points = ");
    print(directionDetailsInfo.e_points);

// Move this pop to bottom of this function
// Close the progress Dialog
    // Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList =
        pPoints.decodePolyline(directionDetailsInfo.e_points!);

    // Clear here to make sure to not get any remnant of polyLineCoordinatesList before this new List we going to add
    polyLinePositionCoordinates.clear();
    if (decodedPolyLinePointsResultList.isNotEmpty) {
      for (PointLatLng pointLatLng in decodedPolyLinePointsResultList) {
        polyLinePositionCoordinates
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    // Clear here to make sure to not get any remnant of polyLine before this new polyLin we going to add
    setOfPolyline.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: polyLinePositionCoordinates,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      setOfPolyline.add(polyline);
    });

    LatLngBounds boundsLaLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLaLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLaLng = LatLngBounds(
          southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
          northeast:
              LatLng(destinationLatLng.latitude, originLatLng.longitude));
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLaLng = LatLngBounds(
          southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
          northeast:
              LatLng(originLatLng.latitude, destinationLatLng.longitude));
    } else {
      boundsLaLng =
          LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    newTripGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLaLng, 65));

    Marker originMaker = Marker(
      markerId: const MarkerId("originID"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    Marker destinationMaker = Marker(
      markerId: const MarkerId("destinationID"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      setOfMarkers.add(originMaker);
      setOfMarkers.add(destinationMaker);
    });

    Circle originCircle = Circle(
        circleId: const CircleId("originID"),
        fillColor: Colors.green,
        radius: 12,
        strokeWidth: 3,
        strokeColor: Colors.white,
        center: originLatLng);

    Circle destinationCircle = Circle(
        circleId: const CircleId("destinationID"),
        fillColor: Colors.green,
        radius: 12,
        strokeWidth: 3,
        strokeColor: Colors.white,
        center: destinationLatLng);

    setState(() {
      setOfCircle.add(originCircle);
      setOfCircle.add(destinationCircle);
    });
    // Close the progress Dialog
    Navigator.pop(context);
    return "OK";
  }

  @override
  void initState() {
    super.initState();

    saveAssignedDriverDetailsToUserRideRequest();
  }

  createDriverIconMarker() {
    if (iconAnimatedMarker == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png")
          .then((value) {
        iconAnimatedMarker = value;
      });
    }
  }

  getDriversLocationUpdatesAttRealTime() {
    LatLng oldLatLng = const LatLng(0, 0);
    streamSubscriptionDriverLivePosition =
        Geolocator.getPositionStream().listen((Position position) {
      driverCurrentPosition = position;
      onlineDriverCurrentPosition = position;

      LatLng latLngLiveDriverPosition = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      );

      Marker animatingMarker = Marker(
        markerId: const MarkerId("AnimatedMarker"),
        position: latLngLiveDriverPosition,
        icon: iconAnimatedMarker!,
        infoWindow: const InfoWindow(title: "Đây là vị trí của bạn"),
      );
      setState(() {
        CameraPosition cameraPosition =
            CameraPosition(target: latLngLiveDriverPosition, zoom: 16);
        newTripGoogleMapController!
            .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
        setOfMarkers.removeWhere(
            (element) => element.markerId.value == "AnimatedMarker");
        setOfMarkers.add(animatingMarker);
      });
      oldLatLng = latLngLiveDriverPosition;
      updateDurationTimeAtRealTime();

      // Updating driver Position real time
      Map driverLatLngDataMap = {
        "latitude": onlineDriverCurrentPosition!.latitude.toString(),
        "longitude": onlineDriverCurrentPosition!.longitude.toString(),
      };
      FirebaseDatabase.instance
          .ref()
          .child("All Ride Request")
          .child(widget.userRideRequestDetails!.rideRequestId!)
          .child("driverLocation");
    });
  }

// Update duration time at real time
  String rideRequestStatus = "accepted";
  String durationFromOriginToDestination = "Đang tính toán";
  bool isRequestDirectionDetails = false;

  updateDurationTimeAtRealTime() async {
    if (isRequestDirectionDetails == false) {
      isRequestDirectionDetails = true;

      if (onlineDriverCurrentPosition == null) {
        return;
      }

      LatLng originLatLng = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude,
      ); //Driver current Location

      LatLng? destinationLatLng;

      if (rideRequestStatus == "accepted") {
        // Khi tài xế chưa đến nơi đón khách hàng thì đường đi sẽ từ "vị tris hiện tại của tài xế" đến "vị trí đón khách hàng"
        destinationLatLng =
            widget.userRideRequestDetails!.originLatLng; //user PickUp Location
      } else {
        // Khi tài xế đã đến nơi đón khách hàng thì đường đi sẽ từ "vị tris hiện tại của tài xế" đến "vị trí điểm đến"
        destinationLatLng = widget
            .userRideRequestDetails!.destinationLatLng; //user DropOff Location
      }

      var directionInformation =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
              originLatLng, destinationLatLng!);
      print("directionInformation = ${directionInformation.toString()}");
      if (directionInformation != null) {
        setState(() {
          print("Start Set duration! durationFromOriginToDestination");
          durationFromOriginToDestination = directionInformation.duration_text!;
          print(
              "End Set duration! durationFromOriginToDestination = $durationFromOriginToDestination");
        });
      }

      isRequestDirectionDetails = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    createDriverIconMarker();
    return Scaffold(
      body: Stack(
        children: [
          //google map

          GoogleMap(
            padding: EdgeInsets.only(bottom: mapPadding),
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            initialCameraPosition: _kGooglePlex,
            markers: setOfMarkers,
            circles: setOfCircle,
            polylines: setOfPolyline,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newTripGoogleMapController = controller;

              setState(() {
                mapPadding = 350;
              });

              var driverCurrentLatLng = LatLng(driverCurrentPosition!.latitude,
                  driverCurrentPosition!.longitude);

              var userPickUpLatLng =
                  widget.userRideRequestDetails!.originLatLng;

              drawPolyLineFromOriginToDestination(
                  driverCurrentLatLng, userPickUpLatLng!);

              getDriversLocationUpdatesAttRealTime();

              ///................................................................
            },
          ),
          //ui
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white12,
                    blurRadius: 18,
                    spreadRadius: 0.5,
                    offset: Offset(0.6, 0.6),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    //duration
                    Text(
                      durationFromOriginToDestination,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    const Divider(
                      thickness: 2,
                      height: 2,
                      color: Colors.green,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    //username - icon
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                      child: Row(
                        children: [
                          Text(
                            "Khách hàng: ${widget.userRideRequestDetails!.userName!}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Icon(
                            Icons.phone_android,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    //user PickUp Address with icon
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
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 24.0,
                    ),

                    //user DropOff Address with icon

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
                                color: Colors.black,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),

                    const Divider(
                      thickness: 2,
                      height: 2,
                      color: Colors.green,
                    ),
                    const SizedBox(
                      height: 10,
                    ),

                    ElevatedButton.icon(
                      onPressed: () async {
                        // Driver has arrived to PickUp Location / Tôi đã đến
                        if (rideRequestStatus == "accepted") {
                          rideRequestStatus = "arrived";
                          FirebaseDatabase.instance
                              .ref()
                              .child("All Ride Request")
                              .child(
                                  widget.userRideRequestDetails!.rideRequestId!)
                              .child("status")
                              .set(rideRequestStatus);
                          setState(() {
                            // Start Trip
                            buttonTitle = "Bắt đầu chuyến đi";
                            buttonColor = Colors.green;
                          });

                          showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) => ProgressDialog(
                                    message: "Đang vẽ chuyến đi...",
                                  ));

                          // Draw polyline from user origin to destination
                          await drawPolyLineFromOriginToDestination(
                              widget.userRideRequestDetails!.originLatLng!,
                              widget
                                  .userRideRequestDetails!.destinationLatLng!);

                          Navigator.pop(context);
                        } // end  if(rideRequestStatus == "accepted")
                        // When user sit in driver's car - Start the trip / Bắt đầu chuyến đi
                        else if (rideRequestStatus == "arrived") {
                          rideRequestStatus = "ontrip";
                          FirebaseDatabase.instance
                              .ref()
                              .child("All Ride Request")
                              .child(
                                  widget.userRideRequestDetails!.rideRequestId!)
                              .child("status")
                              .set(rideRequestStatus);
                          setState(() {
                            // During the trip
                            buttonTitle = "Kết thúc chuyến đi";
                            buttonColor = Colors.redAccent;
                          });
                        } // end else if
                        // Driver when reached the destination
                        else if (rideRequestStatus == "ontrip") {
                          endTripNow();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                      ),
                      icon: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 25,
                      ),
                      label: Text(
                        buttonTitle!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // End the Trip when finish the route to destination
  endTripNow() async {
    showDialog(
        context: context,
        builder: (BuildContext context) => ProgressDialog(
              message: "Đang kết thúc chuyến đi...",
            ));

    // Tính tiền cho chuyến đi
    var currentDriverPositionLatLng = LatLng(
        onlineDriverCurrentPosition!.latitude,
        onlineDriverCurrentPosition!.longitude);
    var tripDetailsDirection =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            currentDriverPositionLatLng,
            widget.userRideRequestDetails!.originLatLng!);
    int totalFareAmount =
        AssistantMethods.caculateFareAmountFromOriginToDestination(
            tripDetailsDirection!);

    FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .child("fareAmount")
        .set(totalFareAmount.toString());
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .child(widget.userRideRequestDetails!.rideRequestId!)
        .child("status")
        .set("ended");
    streamSubscriptionDriverLivePosition!.cancel();

    Navigator.pop(context);

    // Display Fare Amount dialog Box
    showDialog(
        context: context,
        builder: (BuildContext context) =>
            FareAmountCollectionDialog(totalFareAmount: totalFareAmount));

    saveFareAmountToDriverEarnings(totalFareAmount);
  }

  saveAssignedDriverDetailsToUserRideRequest() {
    DatabaseReference databaseReference = FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .child(widget.userRideRequestDetails!.rideRequestId!);

    Map driverLocationDataMap = {
      "latitude": driverCurrentPosition!.latitude.toString(),
      "longitude": driverCurrentPosition!.longitude.toString(),
    };
    databaseReference.child("driverLocation").set(driverLocationDataMap);

    databaseReference.child("status").set("accepted");
    databaseReference.child("driverId").set(onlineDriverData.id);
    databaseReference.child("driverName").set(onlineDriverData.name);
    databaseReference.child("driverPhone").set(onlineDriverData.phone);
    databaseReference.child("car_details").set(
        "${onlineDriverData.car_color} ${onlineDriverData.car_model} ${onlineDriverData.car_number}");

    // saveRideRequestToDriverHistory();
  }

  // Lưu tiền
  saveFareAmountToDriverEarnings(int totalFareAmount) {
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(curentFirebaseUser!.uid)
        .child("earnings")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) //earnings sub Child exists
      {
        int oldEarnings = int.parse(snap.snapshot.value.toString());
        int driverTotalEarnings = totalFareAmount + oldEarnings;

        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(curentFirebaseUser!.uid)
            .child("earnings")
            .set(driverTotalEarnings.toString());
      } else //earnings sub Child do not exists - create a new one
      {
        FirebaseDatabase.instance
            .ref()
            .child("drivers")
            .child(curentFirebaseUser!.uid)
            .child("earnings")
            .set(totalFareAmount.toString());
      }
    });
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

  // saveRideRequestToDriverHistory() {
  //   DatabaseReference tripHistoryRef = FirebaseDatabase.instance
  //       .ref()
  //       .child("drivers")
  //       .child(curentFirebaseUser!.uid)
  //       .child("tripHistory");
  //
  //   tripHistoryRef
  //       .child(widget.userRideRequestDetails!.rideRequestId!)
  //       .set(true);
  // }
}
