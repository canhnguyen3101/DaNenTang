import 'package:flutter/material.dart';
import 'package:taxi_app/global/global.dart';

class FareAmountCollectionDialog extends StatefulWidget {
  int? totalFareAmount;

  FareAmountCollectionDialog({super.key, this.totalFareAmount});

  @override
  State<FareAmountCollectionDialog> createState() =>
      _FareAmountCollectionDialogState();
}

class _FareAmountCollectionDialogState
    extends State<FareAmountCollectionDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
      backgroundColor: Colors.amber,
      child: Container(
        margin: const EdgeInsets.all(6.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 20.0,
            ),
            Text(
              "Chuyến đi (${DriverVehicleType!.toString().toUpperCase()})",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16),
            ),
            const SizedBox(
              height: 20.0,
            ),
            const Divider(
              thickness: 4,
              color: Colors.white,
            ),
            const SizedBox(
              height: 16.0,
            ),
            Expanded(
                child: Text(widget.totalFareAmount!.toString(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 36))),
            const SizedBox(
              height: 10.0,
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  "Đây là giá tiền của chuyến đi! Hãy thu phí từ hành khách",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(
              height: 10.0,
            ),
            Padding(
              padding: const EdgeInsets.all(18.0),
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent),
                  onPressed: () {
                    Future.delayed(const Duration(milliseconds: 2000), () {
                      Navigator.pop(context); // Đóng dialog
                    });
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Lấy Tiền!",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 20)),
                      Text("VNĐ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 20)),
                      // Image.asset(""),
                    ],
                  )),
            ),
            const SizedBox(
              height: 4.0,
            ),
          ],
        ),
      ),
    );
  }
}
