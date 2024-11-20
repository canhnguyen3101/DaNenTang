import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:taxi_app/global/global.dart';
import 'package:taxi_app/splashScreen/splash_screen.dart';

class CarInforScreen extends StatefulWidget {
  @override
  State<CarInforScreen> createState() => _CarInforScreenState();
}

class _CarInforScreenState extends State<CarInforScreen> {
  TextEditingController carModeltextEditingController = TextEditingController();
  TextEditingController carNumbertextEditingController =
      TextEditingController();
  TextEditingController carColortextEditingController = TextEditingController();

  List<String> carTypesList = ['4 chỗ', '7 chỗ', 'Xe máy']; //loại ptien
  String? selectedCarType;

  saveCarInfo() {
    Map driverCarInfoMap = {
      "car_color": carColortextEditingController.text.trim(),
      "car_number": carNumbertextEditingController.text.trim(),
      "car_model": carModeltextEditingController.text.trim(),
      "type": selectedCarType,
    };

    DatabaseReference driversRef =
        FirebaseDatabase.instance.ref().child("drivers");
    driversRef
        .child(curentFirebaseUser!.uid)
        .child("car_details")
        .set(driverCarInfoMap);

    //Fluttertoast.showToast(msg: 'Phương tiện đã được chấp nhận. Chúc mừng bạn');
    Navigator.push(
        context, MaterialPageRoute(builder: (c) => const MySplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                'Thông tin về xe',
                style: TextStyle(
                    fontSize: 35,
                    color: Colors.green,
                    fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: carModeltextEditingController,
                style: const TextStyle(color: Colors.green),
                decoration: const InputDecoration(
                  labelText: "Số khung xe ",
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
                controller: carNumbertextEditingController,
                style: const TextStyle(color: Colors.green),
                decoration: const InputDecoration(
                  labelText: "Biển số xe ",
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
                controller: carColortextEditingController,
                style: const TextStyle(color: Colors.green),
                decoration: const InputDecoration(
                  labelText: "Màu xe ",
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
              DropdownButton(
                iconSize: 20,
                hint: const Text(
                  'Chọn loại xe',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.yellow,
                  ),
                ),
                value: selectedCarType,
                onChanged: (newValue) {
                  setState(() {
                    selectedCarType = newValue.toString();
                  });
                },
                items: carTypesList.map((car) {
                  return DropdownMenuItem(
                    value: car,
                    child: Text(
                      car,
                      style: const TextStyle(color: Colors.green),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () {
                  if (carColortextEditingController.text.isNotEmpty &&
                      carNumbertextEditingController.text.isNotEmpty &&
                      carModeltextEditingController.text.isNotEmpty &&
                      selectedCarType != null) {
                    saveCarInfo();
                  }
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
            ],
          ),
        ),
      ),
    );
  }
}
