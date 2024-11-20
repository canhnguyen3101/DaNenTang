import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/authentication/signup_screen.dart';
import 'package:taxi_app/splashScreen/splash_screen.dart';
import 'package:toast/toast.dart';

import '../global/global.dart';
import '../widgets/progress_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailtextEditingController = TextEditingController();
  TextEditingController passwordtextEditingController = TextEditingController();

  validateForm(BuildContext context) {
    ToastContext().init(context);
    if (!emailtextEditingController.text.contains('@')) {
      Toast.show("Email nhập định dạng không đúng.",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    } else if (passwordtextEditingController.text.isEmpty) {
      Toast.show("Vui lòng nhập mật khẩu",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    } else {
      loginDriverNow();
    }
  }

  loginDriverNow() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext c) {
        return ProgressDialog(
          message: "Vui lòng đợi...",
        );
      },
    );
    final User? firebaseUser = (await fAuth
            .signInWithEmailAndPassword(
      email: emailtextEditingController.text.trim(),
      password: passwordtextEditingController.text.trim(),
    )
            .catchError((msg) {
      Navigator.pop(context);
      //Toast in here
      Toast.show("Tên đăng nhập hoặc mật khẩu không chính xác.",
          duration: Toast.lengthLong, gravity: Toast.bottom);
      //Fluttertoast.showToast(msg: 'Error: ' + msg.toString());
    }))
        .user;
    if (firebaseUser != null) {
      DatabaseReference driversRef =
          FirebaseDatabase.instance.ref().child("drivers");
      driversRef.child(firebaseUser.uid).once().then((driverKey) {
        final snap = driverKey.snapshot;
        if (snap.value != null) {
          curentFirebaseUser = firebaseUser;
          Toast.show("Đăng nhập thành công.",
              duration: Toast.lengthShort, gravity: Toast.bottom);
          // ignore: use_build_context_synchronously
          Navigator.push(context,
              MaterialPageRoute(builder: (c) => const MySplashScreen()));
        } else {
          //Toast in here
          Toast.show("Tài khoản chưa được đăng ký.",
              duration: Toast.lengthShort, gravity: Toast.bottom);

          fAuth.signOut();
          Navigator.push(context,
              MaterialPageRoute(builder: (c) => const MySplashScreen()));
        }
      });
    } else {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      Toast.show("Đăng nhập không thành công.",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Image.asset("images/img_logo_taxi_thai_nguyen.png"),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Tài xế đăng nhập',
                style: TextStyle(
                    fontSize: 35,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: emailtextEditingController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.green),
                decoration: const InputDecoration(
                  labelText: "Email ",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                  ),
                ),
              ),
              TextField(
                controller: passwordtextEditingController,
                keyboardType: TextInputType.text,
                obscureText: true,
                style: const TextStyle(color: Colors.green),
                decoration: const InputDecoration(
                  labelText: "Mật khẩu ",
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.green),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.green,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  // Navigator.push(context,
                  //     MaterialPageRoute(builder: (c) => CarInforScreen()));
                  validateForm(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              TextButton(
                child: const Text(
                  'Chưa có tài khoản? Đăng ký',
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const SignUpScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
