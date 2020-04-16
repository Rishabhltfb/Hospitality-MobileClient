import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hospitality/src/dialogs/loading_dialog.dart';
import 'package:hospitality/src/helpers/current_location.dart';
import 'package:hospitality/src/helpers/dimensions.dart';
import 'package:hospitality/src/models/hospital.dart';
import 'package:hospitality/src/providers/hospital_list_provider.dart';
import 'package:hospitality/src/providers/location_provider.dart';
import 'package:hospitality/src/resources/network/network_repository.dart';
import 'package:hospitality/src/widgets/bouncy_page_animation.dart';
import 'package:provider/provider.dart';

import 'map_screen.dart';

class SearchHospitalScreen extends StatefulWidget {
  final ScrollController controller;
  final GlobalKey<FormState> formKey;

  SearchHospitalScreen({@required this.formKey, @required this.controller});
  @override
  State<StatefulWidget> createState() {
    return _SearchHospitalScreenState(formKey: formKey, controller: controller);
  }
}

class _SearchHospitalScreenState extends State<SearchHospitalScreen> {
  double viewportHeight;
  double viewportWidth;
  LocationProvider locationProvider;
  HospitalListProvider hospitalListProvider;
  bool isButtonEnabled = false;
  ScrollController controller;
  GlobalKey<FormState> formKey;
  double distance = 0;
  final TextStyle dropdownMenuItem =
      TextStyle(color: Colors.black, fontSize: 18);

  _SearchHospitalScreenState(
      {@required this.formKey, @required this.controller});

  Widget build(BuildContext context) {
    viewportHeight = getViewportHeight(context);
    viewportWidth = getViewportWidth(context);
    locationProvider = Provider.of<LocationProvider>(context);
    hospitalListProvider = Provider.of<HospitalListProvider>(context);

    return GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SingleChildScrollView(
          controller: controller,
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
                      EdgeInsets.only(top: getViewportHeight(context) * 0.05),
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
                          fontFamily: "Poppins",
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
                      key: formKey,
                      child: TextFormField(
                        onTap: () {
                          controller.animateTo(
                            getViewportHeight(context) * 0.2,
                            curve: Curves.easeOut,
                            duration: const Duration(milliseconds: 300),
                          );
                        },
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
                                formKey.currentState.reset();
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
                        fontFamily: "Manrope",
                        fontSize: getViewportHeight(context) * 0.025,
                      ),
                    ),
                  ),
                  textColor: Colors.white,
                  onPressed: () {
                    if (isButtonEnabled) {
                      _submitForm(context);
                      formKey.currentState.reset();
                      FocusScope.of(context).requestFocus(FocusNode());
                    }
                  },
                ),
              ],
            ),
          ),
        ));
  }

  void _submitForm(BuildContext context) async {
    controller.animateTo(
      0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
    formKey.currentState.save();
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
            if (hospitals.length == 0) {
              Fluttertoast.showToast(
                  msg:
                      "No nearby hospitals found! Try again or change the distance limit!",
                  toastLength: Toast.LENGTH_SHORT);
              Navigator.pop(context);
            } else {
              hospitalListProvider.setHospitalLists = hospitals;
              Navigator.pop(context);
              Navigator.push(context, BouncyPageRoute(widget: MapSample()));
            }
          } else if (value.statusCode == 404) {
            Navigator.pop(context);
            Fluttertoast.showToast(
                msg:
                    "No nearby hospitals found! Try again or change the distance limit!",
                toastLength: Toast.LENGTH_SHORT);
            print("Send Location: " + value.statusCode.toString());
          } else {
            Navigator.pop(context);
            Fluttertoast.showToast(
                msg: "Error fetching hospitals! Try again!",
                toastLength: Toast.LENGTH_SHORT);
            print("Send Location: " + value.statusCode.toString());
          }
        }).catchError((error) {
          Navigator.pop(context);
          Fluttertoast.showToast(
              msg: "Error fetching hospitals! Try again!",
              toastLength: Toast.LENGTH_SHORT);
        });
      } else {
        Fluttertoast.showToast(
            msg: "Error in getting location",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM);
      }
    }).catchError((error) {
      Fluttertoast.showToast(
          msg: "Error in getting location",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM);
    });
  }
}