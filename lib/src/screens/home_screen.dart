import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hospital_service/src/dialogs/loading_dialog.dart';
import 'package:hospital_service/src/helpers/current_location.dart';
import 'package:hospital_service/src/helpers/dimensions.dart';
import 'package:hospital_service/src/models/hospital.dart';
import 'package:hospital_service/src/providers/hospital_list_provider.dart';
import 'package:hospital_service/src/providers/location_provider.dart';
import 'package:provider/provider.dart';
import 'package:hospital_service/src/resources/network/network_repository.dart';
import '../helpers/dimensions.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  LocationProvider locationProvider;
  HospitalListProvider hospitalListProvider;
  bool isButtonEnabled = false;

  final TextStyle dropdownMenuItem =
      TextStyle(color: Colors.black, fontSize: 18);
  double distance = 0;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  void _submitForm(BuildContext context) async {
    _formKey.currentState.save();
    setState(() {
      isButtonEnabled = false;
    });
    locationProvider.setHospitalDistance = distance;
    getLocation().then((value) {
      if (value != null) {
        locationProvider.setLocation = value;
        showLoadingDialog(context: context);
        getNetworkRepository
            .sendCurrentLocation(
                latitude: value.latitude,
                longitude: value.longitude,
                range: distance)
            .then((value) {
          if (value.statusCode == 200) {
            List<dynamic> response = json.decode(value.body);
            List<Hospital> hospitals = new List<Hospital>();
            hospitalListProvider.setHospitalLists = hospitals;
            for (int i = 0; i < response.length; i++) {
              Map<String, dynamic> data = response[i].cast<String, dynamic>();
              Hospital h = new Hospital();
              if (data["distance"] != null &&
                  data["latitude"] != null &&
                  data["longitude"] != null &&
                  data["name"] != null) {
                h.setDistance =
                    double.parse(data["distance"].toStringAsFixed(2));
                h.setEmail = data["contact"].toString();
                h.setLatitude = data["latitude"];
                h.setLongitude = data["longitude"];
                h.setName = data["name"];
                hospitals.add(h);
              }
            }
            Navigator.pop(context);
            if (hospitals.length == 0) {
              Fluttertoast.showToast(
                  msg:
                      "No nearby hospitals found! Try again or change the distance limit!",
                  toastLength: Toast.LENGTH_SHORT);
            } else {
              hospitalListProvider.setHospitalLists = hospitals;
              Navigator.pushNamed(context, "/map");
            }
          } else if (value.statusCode == 404) {
            Fluttertoast.showToast(
                msg:
                    "No nearby hospitals found! Try again or change the distance limit!",
                toastLength: Toast.LENGTH_SHORT);
            print("Send Location: " + value.statusCode.toString());
            Navigator.pop(context);
          } else {
            Fluttertoast.showToast(
                msg: "Error fetching hospitals! Try again!",
                toastLength: Toast.LENGTH_SHORT);
            print("Send Location: " + value.statusCode.toString());
            Navigator.pop(context);
          }
        }).catchError((error) {
          Fluttertoast.showToast(
              msg: "Error fetching hospitals! Try again!",
              toastLength: Toast.LENGTH_SHORT);
          Navigator.pop(context);
        });
      } else {
        Fluttertoast.showToast(
            msg: "Error in getting location",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM);
        Navigator.pop(context);
      }
    }).catchError((error) {
      Fluttertoast.showToast(
          msg: "Error in getting location",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM);
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    locationProvider = Provider.of<LocationProvider>(context);
    hospitalListProvider = Provider.of<HospitalListProvider>(context);

    return Scaffold(
        appBar: AppBar(
          title: Text('HomeScreen'),
          actions: <Widget>[
            Hero(
              tag: "ico",
              child: Container(
                alignment: Alignment.center,
                margin:
                    EdgeInsets.only(right: getViewportWidth(context) * 0.02),
                height: getDeviceHeight(context) * 0.1,
                width: getDeviceWidth(context) * 0.1,
                child: Image.asset('assets/img/splash_bg.png'),
              ),
            ),
          ],
        ),
        body: GestureDetector(
          onTap: () {
            FocusScope.of(context).requestFocus(FocusNode());
          },
          child: SingleChildScrollView(
            child: Container(
              height: getViewportHeight(context),
              width: getViewportWidth(context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade500]),
              ),
              child: Column(
                children: <Widget>[
                  Container(
                    margin:
                        EdgeInsets.only(top: getViewportHeight(context) * 0.1),
                    height: getDeviceHeight(context) * 0.25,
                    width: getDeviceWidth(context) * 0.8,
                    child: Image.asset('assets/img/hosp_doc.png'),
                  ),
                  SizedBox(
                    height: getViewportHeight(context) * 0.1,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Input distance for nearby hospital',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: "Montserrat",
                            fontSize: getViewportWidth(context) * 0.04,
                            color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: getDeviceHeight(context) * 0.05,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.all(Radius.circular(30)),
                      child: Form(
                        key: _formKey,
                        child: TextFormField(
                          cursorColor: Theme.of(context).primaryColor,
                          style: dropdownMenuItem,
                          decoration: InputDecoration(
                            hintText: "Search by distance in km",
                            hintStyle:
                                TextStyle(color: Colors.black38, fontSize: 16),
                            prefixIcon: IconButton(
                                icon: Icon(
                                  Icons.search,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onPressed: () {
                                  _submitForm(context);
                                  _formKey.currentState.reset();
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                }),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 25, vertical: 13),
                          ),
                          keyboardType: TextInputType.phone,
                          onChanged: (String value) {
                            if (value.length == 0) {
                              setState(() {
                                isButtonEnabled = false;
                              });
                            } else {
                              setState(() {
                                isButtonEnabled = true;
                              });
                            }
                            distance = double.parse(value);
                          },
                          onSaved: (String value) {
                            if (value.length == 0) {
                              setState(() {
                                isButtonEnabled = false;
                              });
                            } else {
                              setState(() {
                                isButtonEnabled = true;
                              });
                            }
                            distance = double.parse(value);
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: getViewportHeight(context) * 0.06),
                  RaisedButton(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    splashColor: isButtonEnabled ? Colors.blue : null,
                    color: isButtonEnabled ? Colors.white : Colors.grey,
                    child: Container(
                      width: getViewportWidth(context) * 0.35,
                      height: getViewportHeight(context) * 0.06,
                      alignment: Alignment.center,
                      child: Text(
                        'Search',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isButtonEnabled
                              ? Theme.of(context).primaryColor
                              : Colors.black,
                          fontFamily: "Ubuntu",
                          fontSize: getViewportHeight(context) * 0.025,
                        ),
                      ),
                    ),
                    textColor: Colors.white,
                    onPressed: () {
                      if (isButtonEnabled) {
                        _submitForm(context);
                        _formKey.currentState.reset();
                        FocusScope.of(context).requestFocus(FocusNode());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
