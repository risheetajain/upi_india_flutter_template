import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:upi_india/upi_india.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const UpiPay());
  }
}

class UpiPay extends StatefulWidget {
  const UpiPay({Key? key}) : super(key: key);

  @override
  _UpiPayState createState() => _UpiPayState();
}

class _UpiPayState extends State<UpiPay> {
  final amountController = TextEditingController();
  final UpiIndia _upiIndia = UpiIndia();
  List<UpiApp>? apps = [];
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _upiIndia.getAllUpiApps(mandatoryTransactionId: false).then((value) {
      setState(() {
        apps = value;
      });
    }).catchError((e) {
      apps = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Please Enter Amount to do payment",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: amountController,
              keyboardType: TextInputType.number,
              maxLength: 5,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  focusedBorder: OutlineInputBorder(),
                  border: OutlineInputBorder()),
              autofocus: true,
              validator: (val) {
                if (val == null || val.isEmpty) {
                  return "Please Enter valid Amount";
                } else if (int.parse(val) <= 0) {
                  return "Amount should be more than 0";
                } else {
                  return null;
                }
              },
            ),
            ElevatedButton(
                child: const Text("UPI India"),
                onPressed: () {
                  upiBottomSheet(context);
                }),
            const SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
    );
  }

  void upiBottomSheet(context) {
    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      context: context,
      builder: (builder) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "Make a Payment",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              Material(child: Text(amountController.text)),
              displayUpiApps()
            ],
          ),
        );
      },
    );
  }

  Widget displayUpiApps() {
    if (apps == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (apps!.isEmpty) {
      return const Center(
        child: Text(
          "No apps found for Transaction.",
        ),
      );
    } else {
      return Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Wrap(
            children: apps!.map((UpiApp app) {
              if (app.name == "GPay") {
                return Container();
              } else {
                return GestureDetector(
                  onTap: () {
                    initiateTransaction(app).then((value) {
                      final finalAmount = num.parse(amountController.text);
                      if (value.status?.toUpperCase() == "SUCCESS") {
                        Fluttertoast.showToast(
                          msg: _checkTxnStatus(value.status!),
                        );
                      }
                    });
                  },
                  child: SizedBox(
                    height: 100,
                    width: 100,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.memory(
                          app.icon,
                          height: 60,
                          width: 60,
                        ),
                        Text(app.name),
                      ],
                    ),
                  ),
                );
              }
            }).toList(),
          ),
        ),
      );
    }
  }

  // Initiate functions for transaction according to app
  Future<UpiResponse> initiateTransaction(UpiApp app) async {
    setState(() {});
    return _upiIndia.startTransaction(
      app: app,
      receiverUpiId: "your upi id",// it must be business account then only it will work 
      receiverName: "Your name",
      transactionRefId: "TestingUpiIndiaPlugin",
      transactionNote: "Not actual. Just an example.",
      amount: double.parse(amountController.text),
    );
  }

// Upi Error checking
  String _upiErrorHandler(error) {
    switch (error) {
      case UpiIndiaAppNotInstalledException:
        return "Requested app not installed on device";
      case UpiIndiaUserCancelledException:
        return "You cancelled the transaction";
      case UpiIndiaNullResponseException:
        return "Requested app didn\"t return any response";
      case UpiIndiaInvalidParametersException:
        return "Requested app cannot handle the transaction";
      default:
        return "An Unknown error has occurred";
    }
  }

// Trasaction status check
  _checkTxnStatus(String status) {
    String x = "";
    switch (status) {
      case UpiPaymentStatus.SUCCESS:
        x = "Transaction Successful";
        break;
      case UpiPaymentStatus.SUBMITTED:
        x = "Transaction Submitted";
        break;
      case UpiPaymentStatus.FAILURE:
        x = "Transaction Failed";
        break;
      default:
        x = "Received an Unknown transaction status";
    }
    return x;
  }
}
