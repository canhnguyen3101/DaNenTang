// ignore_for_file: prefer_interpolation_to_compose_strings, avoid_print, use_build_context_synchronously, prefer_collection_literals

import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:toast/toast.dart';
import 'package:users_app/assistants/assistant_methods.dart';
import 'package:users_app/assistants/geofire_assistant.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/infoHandler/app_info.dart';
import 'package:users_app/main.dart';
import 'package:users_app/mainScreens/rate_driver_screen.dart';
import 'package:users_app/mainScreens/search_places_screen.dart';
import 'package:users_app/mainScreens/select_nearest_active_driver_screen.dart';
import 'package:users_app/models/active_nearby_available_drivers.dart';
import 'package:users_app/models/direction_details.dart';
import 'package:users_app/widgets/my_drawer.dart';
import 'package:users_app/widgets/pay_fare_amount_dialog.dart';
import 'package:users_app/widgets/progress_dialog.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? newGoogleMapController;
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  blackThemeGoogleMap() {
    newGoogleMapController!.setMapStyle('''
                    [
                      {
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "featureType": "administrative.locality",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#263c3f"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#6b9a76"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#38414e"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#212a37"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#9ca5b3"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#1f2835"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#f3d19c"
                          }
                        ]
                      },
                      {
                        "featureType": "transit",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#2f3948"
                          }
                        ]
                      },
                      {
                        "featureType": "transit.station",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#515c6d"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      }
                    ]
                ''');
  }

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double seachLocationContainerHeight = 220;
  double waitingResponseFromDriverContainerHeight = 0;

  double assignedDriverInfoContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocator = Geolocator();

  String userName = "";
  String userEmail = "";

  double bottomPaddingOfMap = 0; //icon zoom

  //draw line
  List<LatLng> pLineCoOrdinatesList = [];
  Set<Polyline> polyLineSet = {};

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  bool openNavigationDrawer = true;

  bool activeNearbyDriverKeysLoaded = false;

  BitmapDescriptor? activeNearbyIcon;

  List<ActiveNearbyAvailableDrivers> onlineNearByAvailableDriversList = [];

  DatabaseReference? referenceRideRequest;

  String driverRideStatus = "Driver is Coming";

  StreamSubscription<DatabaseEvent>? tripRideRequestInfoStreamSubSription;

  bool requestPositionInfo = true;

  //----------------------------------------------------------------------------
  LocationPermission? locationPermission;
//check location
  checkIfLocationPermissitonAllwed() async {
    // Nếu _locationPermission == null thì gán
    locationPermission = await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    } else {}

    // setup userMdelCurrentInfor
    userModelCurrentInfo = await AssistantMethods.readCurrentOnlineUserInfo();

    // Fix red screen: Null Pointer Exception.
    userName = userModelCurrentInfo == null
        ? "Không có kết nối"
        : userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo == null
        ? "Xin khởi động lại"
        : userModelCurrentInfo!.email!;
    AssistantMethods.readTripsKeysForOnlineUser(context);
  }

  locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    userCurrentPosition = cPosition;

    LatLng latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);

    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress =
        await AssistantMethods.searchAddressForGeographicCoOrdinates(
            userCurrentPosition!, context);
    print("1. this is your address = " + humanReadableAddress);

    initializeGeoFireListener();

    //
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissitonAllwed();
  }

  saveRideRequestInfomation() {
    //1. save the RideRequest Ìnfomation
    referenceRideRequest =
        FirebaseDatabase.instance.ref().child("All Ride Request").push();

    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;

    var destinationLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      "latitide": originLocation!.locationLatitude.toString(),
      "longitude": originLocation.locationLongitude.toString(),
    };

    Map destinatationLocationMap = {
      "latitide": destinationLocation!.locationLatitude.toString(),
      "longitude": destinationLocation.locationLongitude.toString(),
    };

    Map userInfomationMap = {
      "origin": originLocationMap,
      "destination": destinatationLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name!,
      "userPhone": userModelCurrentInfo!.phone!,
      "originAddress": originLocation.locationName,
      "destinationAddress": destinationLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(userInfomationMap);

    tripRideRequestInfoStreamSubSription =
        referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null) {
        return;
      }

      if ((eventSnap.snapshot.value as Map)["car_details"] != null) {
        setState(() {
          driverCarDetails =
              (eventSnap.snapshot.value as Map)["car_details"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["driverPhone"] != null) {
        setState(() {
          driverPhone =
              (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["driverName"] != null) {
        setState(() {
          driverName =
              (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["status"] != null) {
        userRideRequestStatus =
            (eventSnap.snapshot.value as Map)["status"].toString();
      }

      if ((eventSnap.snapshot.value as Map)["driverLocation"] != null) {
        double driverCurrentPositionLat = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());

        double driverCurrentPositionLng = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());

        LatLng driverCurrentPositionLatLng =
            LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        //status = accept
        if (userRideRequestStatus == "accepted") {
          updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng);
        }

        //status = arrived

        if (userRideRequestStatus == "arrived") {
          setState(() {
            driverRideStatus = "Tài xế đã đến";
          });
        }

        //status = ontrip

        if (userRideRequestStatus == "ontrip") {
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }

        //status = ended

        if (userRideRequestStatus == "ended") {
          if ((eventSnap.snapshot.value as Map)["fareAmount"] != null) {
            double fareAmountC = double.parse(
                (eventSnap.snapshot.value as Map)["fareAmount"].toString());

            var respone = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext c) => PayFareAmountDialog(
                fareAmount: fareAmountC,
              ),
            );

            if (respone == "cashPayed") {
              //rating...
              if ((eventSnap.snapshot.value as Map)["driverId"] != null) {
                String assignedDriverId =
                    (eventSnap.snapshot.value as Map)["driverId"].toString();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (c) => RateDriverScreen(
                              assignedDriverId: assignedDriverId,
                            )));
              }
            }
          }
        }
      }
    });

    onlineNearByAvailableDriversList =
        GeoFireAssistant.activeNearbyAvailableDriversList;

    seachNearestOnlineDrivres();
  }

  updateArrivalTimeToUserPickUpLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;
      LatLng userPickUpPosition =
          LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
      var directionDetailsInfo =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
              driverCurrentPositionLatLng, userPickUpPosition);

      if (directionDetailsInfo == null) {
        return;
      }

      setState(() {
        driverRideStatus = directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if (requestPositionInfo == true) {
      requestPositionInfo = false;

      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).userDropOffLocation;
      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLatitude!,
          dropOffLocation.locationLongitude!);
      var directionDetailsInfo =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
              driverCurrentPositionLatLng, userDestinationPosition);

      if (directionDetailsInfo == null) {
        return;
      }

      setState(() {
        driverRideStatus = "Tài xế đang đến vị trí của bạn ::" +
            directionDetailsInfo.duration_text.toString();
      });

      requestPositionInfo = true;
    }
  }

  seachNearestOnlineDrivres() async {
    //no active driver
    if (onlineNearByAvailableDriversList.isEmpty) {
      //2. cancle the RideRequest Ìnfomation

      referenceRideRequest!.remove();

      setState(() {
        polyLineSet.clear();
        markersSet.clear();
        circlesSet.clear();
        pLineCoOrdinatesList.clear();
      });

      Toast.show("Không có tài xế gần bạn.",
          duration: Toast.lengthShort, gravity: Toast.bottom);

      Toast.show("Khởi động lại App để tìm kiếm.",
          duration: Toast.lengthShort, gravity: Toast.bottom);

      Future.delayed(const Duration(milliseconds: 4000), () {
        SystemNavigator.pop();
      });
      return;
    }

    //active driver
    await retrieveOnlineDriversInfomation(onlineNearByAvailableDriversList);

    var respone = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => SelectNearestActiveDriverScreen(
                referenceRideRequest: referenceRideRequest)));

    if (respone == "driverChoosed") {
      FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(choosenDriverId!)
          .once()
          .then((snap) {
        if (snap.snapshot.value != null) {
          //notifi send TO THE DRIVER
          sendNotificationToDriverNow(choosenDriverId!);

          showWaitingReponseFromDriverUI();

          FirebaseDatabase.instance
              .ref()
              .child("drivers")
              .child(choosenDriverId!)
              .child("newRideStatus")
              .onValue
              .listen((eventSnapshot) {
            //1. driver canceled the ride Request
            if (eventSnapshot.snapshot.value == "idle") {
              ToastContext().init(context);
              Toast.show(
                  "Tài xế đã huỷ yêu cầu của bạn. Vui lòng chọn tài xế khác",
                  duration: Toast.lengthShort,
                  gravity: Toast.bottom);
              Future.delayed(const Duration(milliseconds: 3000), () {
                Toast.show("Khởi động lại ứng dụng",
                    duration: Toast.lengthShort, gravity: Toast.bottom);
                SystemNavigator.pop();
              });
            }

            //2. driver accepted  the rideReuquest

            if (eventSnapshot.snapshot.value == "accepted") {
              showUIForAssignedDriverInfo();
            }
          });
        } else {
          ToastContext().init(context);
          Toast.show("Tài xế không tồn tại. Thử lại...",
              duration: Toast.lengthShort, gravity: Toast.bottom);
        }
      });
    }
  }

  showUIForAssignedDriverInfo() {
    setState(() {
      waitingResponseFromDriverContainerHeight = 0;
      seachLocationContainerHeight = 0;
      assignedDriverInfoContainerHeight = 245;
    });
  }

  showWaitingReponseFromDriverUI() {
    setState(() {
      seachLocationContainerHeight = 0;
      waitingResponseFromDriverContainerHeight = 220;
    });
  }

  sendNotificationToDriverNow(String choosenDriverId) {
    // assign requestId to requestStatus in
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(choosenDriverId)
        .child("newRideStatus")
        .set(referenceRideRequest!.key);

    // Automate push the notification
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(choosenDriverId)
        .child("token")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String deviceRegistrationToken = snap.snapshot.value.toString();

        AssistantMethods.sendNotificationToDriverNow(deviceRegistrationToken,
            referenceRideRequest!.key.toString(), context);

        // Tạo toast để thông báo
        ToastContext().init(context);
        Toast.show("Gửi yêu cầu thành công.",
            duration: Toast.lengthShort, gravity: Toast.bottom);
      } else {
        // Nếu snap rỗng, không có dữ liệu
        // Tạo toast để thông báo
        ToastContext().init(context);
        Toast.show("Vui lòng chọn tài xế khác.",
            duration: Toast.lengthShort, gravity: Toast.bottom);
        return;
      }
    });
  }

  retrieveOnlineDriversInfomation(List onlineNearestDriversList) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child("drivers");
    for (ActiveNearbyAvailableDrivers driver in onlineNearestDriversList) {
      await ref.child(driver.driverId.toString()).once().then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;
        dList.add(driverKeyInfo);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    createActiveNearByDriverIconMarker();
    return Scaffold(
      key: sKey,
      drawer: SizedBox(
        width: 280,
        child: Theme(
          data: Theme.of(context).copyWith(
            canvasColor: const Color.fromARGB(209, 189, 189, 189),
          ),
          child: MyDrawer(
            name: userName,
            email: userEmail,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: true,
            zoomGesturesEnabled: true,
            initialCameraPosition: _kGooglePlex,
            polylines: polyLineSet,
            markers: markersSet,
            circles: circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              //... for black theme google map
              // blackThemeGoogleMap();

              setState(() {
                bottomPaddingOfMap = 245;
              });
              locateUserPosition();
            },
          ),
          //custom hamburger button for drawer.
          Positioned(
            top: 30,
            left: 18,
            child: GestureDetector(
              onTap: () {
                if (openNavigationDrawer) {
                  sKey.currentState!.openDrawer();
                } else {
                  //restart
                  SystemNavigator.pop();
                  ToastContext().init(context);
                  Toast.show("Đang thoát ứng dụng",
                      duration: Toast.lengthShort, gravity: Toast.bottom);
                }
              },
              child: CircleAvatar(
                backgroundColor: Colors.white12,
                child: Icon(
                  openNavigationDrawer ? Icons.menu : Icons.close,
                  color: Colors.green,
                ),
              ),
            ),
          ),

          //ui for seaching location
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 120),
              child: Container(
                height: seachLocationContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(children: [
                    //from
                    Row(
                      children: [
                        const Icon(
                          Icons.add_location_outlined,
                          color: Colors.red,
                        ),
                        const SizedBox(
                          width: 12.0,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Vị trí hiện tại",
                              style:
                                  TextStyle(color: Colors.black, fontSize: 12),
                            ),
                            Text(
                              //location map
                              Provider.of<AppInfo>(context)
                                          .userPickUpLocation !=
                                      null
                                  ? "${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 24)}..."
                                  : "Không thấy địa chỉ",
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 10.0,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),

                    //to
                    GestureDetector(
                      onTap: () async {
                        //search places screen.
                        var reponseFromSeachScreen = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (c) => const SearchPlacesScreen()));
                        if (reponseFromSeachScreen
                            .toString()
                            .contains("obtainedDropoff")) {
                          // Change the top - right button to "X"
                          setState(() {
                            openNavigationDrawer = false;
                          });
                          // Draw Poly line
                          print("obtainedDropoff: ");
                          var result =
                              await drawPolyLineFromOriginToDestination();
                          print(result);
                          // replace
                          // await drawPolyLineFromOriginToDestination();
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_location_outlined,
                            color: Colors.red,
                          ),
                          const SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Vị trí cần đến",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 12),
                              ),
                              Text(
                                Provider.of<AppInfo>(context)
                                            .userDropOffLocation !=
                                        null
                                    ? Provider.of<AppInfo>(context)
                                        .userDropOffLocation!
                                        .locationName!
                                    : "Đi đâu?",
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                    const SizedBox(
                      height: 16.0,
                    ),

                    ElevatedButton(
                      onPressed: () {
                        ToastContext().init(context);
                        if (Provider.of<AppInfo>(context, listen: false)
                                .userDropOffLocation !=
                            null) {
                          saveRideRequestInfomation();
                        } else {
                          Toast.show("Vui lòng chọn vị trí cần đến.",
                              duration: Toast.lengthShort,
                              gravity: Toast.bottom);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: const Text("Yêu cầu"),
                    ),
                  ]),
                ),
              ),
            ),
          ),

          //ui for waiting response
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: waitingResponseFromDriverContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'Chờ phản hồi từ tài xế.',
                        duration: const Duration(seconds: 6),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                            fontSize: 32.0,
                            color: Colors.green,
                            fontWeight: FontWeight.bold),
                      ),
                      ScaleAnimatedText(
                        'Vui lòng đợi...',
                        duration: const Duration(seconds: 10),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                            fontSize: 32.0,
                            color: Colors.green,
                            fontFamily: 'Canterbury'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //ui for display inf driver
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: assignedDriverInfoContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //status of ride
                    Center(
                      child: Text(
                        driverRideStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.black,
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    //driver vehicle details
                    Text(
                      driverCarDetails,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(
                      height: 4.0,
                    ),

                    //driver name
                    Text(
                      driverName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.black,
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    //call driver button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Do smth here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(
                          Icons.phone_android,
                          color: Colors.white,
                          size: 22,
                        ),
                        label: const Text(
                          "Gọi tài xế",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
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

// Replace
// Future<void> drawPolyLineFromOriginToDestination()
  Future<String> drawPolyLineFromOriginToDestination() async {
    var originPositon =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;

    var destinationPositon =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(
        originPositon!.locationLatitude!, originPositon.locationLongitude!);

    var destinationLatLng = LatLng(destinationPositon!.locationLatitude!,
        destinationPositon.locationLongitude!);

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

// Replace
    // tripDirectionDetailsInfo = directionDetailsInfo;

    setState(() {
      print("1. Gán tripDirectionDetailsInfo Tính Tiền");
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    print("1. These are points = ");
    print(directionDetailsInfo.e_points);

// Move this pop to bottom of this function
// Close the progress Dialog
    // Navigator.pop(context);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList =
        pPoints.decodePolyline(directionDetailsInfo.e_points!);

    // Clear here to make sure to not get any remnant of polyLineCoordinatesList before this new List we going to add
    pLineCoOrdinatesList.clear();
    if (decodedPolyLinePointsResultList.isNotEmpty) {
      for (PointLatLng pointLatLng in decodedPolyLinePointsResultList) {
        pLineCoOrdinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      }
    }

    // Clear here to make sure to not get any remnant of polyLine before this new polyLin we going to add
    polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.blue,
        polylineId: const PolylineId("PolylineID"),
        jointType: JointType.round,
        points: pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polyLineSet.add(polyline);
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

    newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLaLng, 65));

    Marker originMaker = Marker(
      markerId: const MarkerId("originID"),
      infoWindow:
          InfoWindow(title: originPositon.locationName, snippet: "Origin"),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    Marker destinationMaker = Marker(
      markerId: const MarkerId("destinationID"),
      infoWindow: InfoWindow(
          title: destinationPositon.locationName, snippet: "Destination"),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      markersSet.add(originMaker);
      markersSet.add(destinationMaker);
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
      circlesSet.add(originCircle);
      circlesSet.add(destinationCircle);
    });
    // Close the progress Dialog
    Navigator.pop(context);
    return "OK";
  }

  initializeGeoFireListener() {
    Geofire.initialize("activeDrivers");

    Geofire.queryAtLocation(
            userCurrentPosition!.latitude, userCurrentPosition!.longitude, 10)!
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          case Geofire.onKeyEntered:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
                ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];

            GeoFireAssistant.activeNearbyAvailableDriversList
                .add(activeNearbyAvailableDriver);
            if (activeNearbyDriverKeysLoaded == true) {
              displayActiveDriverOnUsersMap();
            }
            break;

          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map['key']);
            displayActiveDriverOnUsersMap();
            break;

          case Geofire.onKeyMoved:
            // Update your key's location
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
                ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];
            GeoFireAssistant.updateActiveNearbyAvailableDriversLocation(
                activeNearbyAvailableDriver);
            displayActiveDriverOnUsersMap();
            break;

          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDriverOnUsersMap();
            break;
        }
      }

      setState(() {});
    });
  }

  displayActiveDriverOnUsersMap() {
    setState(() {
      markersSet.clear();
      circlesSet.clear();

      Set<Marker> driversMakerSet = Set<Marker>();

      for (ActiveNearbyAvailableDrivers eachDriver
          in GeoFireAssistant.activeNearbyAvailableDriversList) {
        LatLng eachDriverActivePosition =
            LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);
        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driversMakerSet.add(marker);
        setState(() {
          markersSet = driversMakerSet;
        });
      }
    });
  }

  createActiveNearByDriverIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/car.png")
          .then((value) {
        activeNearbyIcon = value;
      });
    }
  }
}
