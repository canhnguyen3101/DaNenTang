import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:taxi_app/models/driver_data.dart';

import '../models/user_model.dart';

final FirebaseAuth fAuth = FirebaseAuth.instance;
User? curentFirebaseUser;
UserModel? userModelCurrentInfo;
StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;

AssetsAudioPlayer audioPlayer = AssetsAudioPlayer();
Position? driverCurrentPosition;

DriverData onlineDriverData = DriverData();
String? DriverVehicleType = "";
String? titleStarsRating = "Chưa có đánh giá";
bool isDriverActive = false;
String statusText = "Now Offline";