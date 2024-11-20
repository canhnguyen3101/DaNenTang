import 'package:firebase_auth/firebase_auth.dart';
import 'package:users_app/models/direction_details.dart';
import 'package:users_app/models/user_model.dart';

final FirebaseAuth fAuth = FirebaseAuth.instance;
User? curentFirebaseUser;
UserModel? userModelCurrentInfo;
List dList = []; //driverKeys Info List (online driver)
DirectionDetailsInfo? tripDirectionDetailsInfo;

String? choosenDriverId = "";
String cloudMessaginServerToken =
    "key=AAAAcL6J9tM:APA91bFm-CkHjUWNvs6_O2fE7cZDSpRHf8c5toFrSDtFJswFPbTmCBe7p1tVIB0H24D2QxgEbCGP-NwkdLk1Vy9L0zaqlTjXrF9xCVG5V4ZU0DRnNsX2d2SYAAiUN2FlyMqXolGjcIrv";
String userDropOffAddress = "";

String driverCarDetails = "";
String driverName = "";
String userRideRequestStatus = "";
String driverPhone = "";
double countRatingStars = 0.0;
String titleStarsRating = ""; 
