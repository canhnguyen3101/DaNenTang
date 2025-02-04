import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:toast/toast.dart';
import 'package:users_app/authentication/login_screen.dart';
import 'package:users_app/splashScreen/splash_screen.dart';
import 'package:users_app/widgets/progress_dialog.dart';
import '../global/global.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController nametextEditingController = TextEditingController();
  TextEditingController emailtextEditingController = TextEditingController();
  TextEditingController phonetextEditingController = TextEditingController();
  TextEditingController passwordtextEditingController = TextEditingController();

  validateForm(BuildContext context) {
    ToastContext().init(context);
    if (nametextEditingController.text.length < 3) {
      Toast.show("Tên không được nhỏ hơn 3 ký tự.",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    }
    if (!emailtextEditingController.text.contains('@')) {
      Toast.show("Email nhập định dạng không đúng.",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    }
    if (phonetextEditingController.text.isEmpty) {
      Toast.show("Sai thông tin số điện thoại.",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    }
    if (passwordtextEditingController.text.length < 6) {
      Toast.show("Mật khẩu phải lớn hơn 3 ký tự.",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    } else {
      //check in here
      loginUserNow();
    }
  }

  loginUserNow() async {
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
            .createUserWithEmailAndPassword(
      email: emailtextEditingController.text.trim(),
      password: passwordtextEditingController.text.trim(),
    )
            .catchError((msg) {
      Navigator.pop(context);
      //Toast in here
      Toast.show("Email này đã được sử dụng",
          duration: Toast.lengthLong, gravity: Toast.bottom);
    }))
        .user;
    if (firebaseUser != null) {
      Map userMap = {
        "id": firebaseUser.uid,
        "name": nametextEditingController.text.trim(),
        "email": emailtextEditingController.text.trim(),
        "phone": phonetextEditingController.text.trim(),
      };

      DatabaseReference reference =
          FirebaseDatabase.instance.ref().child("users");
      reference.child(firebaseUser.uid).set(userMap);

      curentFirebaseUser = firebaseUser;
      Toast.show("Tài khoản đã được tạo",
          duration: Toast.lengthShort, gravity: Toast.bottom);
      // ignore: use_build_context_synchronously
      Navigator.push(
          context, MaterialPageRoute(builder: (c) => MySplashScreen()));
    } else {
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      Toast.show("Tạo tài khoản không thành công. Vui lòng liên hệ CSKH",
          duration: Toast.lengthShort, gravity: Toast.bottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        //cho phép cuộn xuống
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
              Padding(
                padding: const EdgeInsets.all(30.0),
                child: Image.asset("images/img_logo_taxi_thai_nguyen.png"),
              ),
              const SizedBox(
                height: 10,
              ),
              const Text(
                'Đăng ký thành viên',
                style: TextStyle(
                    fontSize: 35,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: nametextEditingController,
                style: const TextStyle(color: Colors.green),
                decoration: const InputDecoration(
                  labelText: "Họ và tên ",
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
                controller: phonetextEditingController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.green),
                decoration: const InputDecoration(
                  labelText: "Số điện thoại ",
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
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  validateForm(context);
                  // Navigator.push(context,
                  //     MaterialPageRoute(builder: (c) => CarInforScreen()));
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
              TextButton(
                child: const Text(
                  'Đã có tài khoản? Đăng nhập',
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (c) => const LoginScreen()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
