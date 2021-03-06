import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class tempPost {
  late DateTime date;
  late String imageURL;
  late int quantity;
  late double latitude;
  late double longitude;
}

class PostFormScaffold extends StatefulWidget {
  String? url;

  PostFormScaffold({Key? key, required this.url}) : super(key: key);

  @override
  PostFormScaffoldState createState() => PostFormScaffoldState();
}

class PostFormScaffoldState extends State<PostFormScaffold> {
  LocationData? locationData;

  var locationService = Location();

  final formKey = GlobalKey<FormState>();

  final postFields = tempPost();

  @override
  void initState() {
    super.initState();
    retrieveLocation();
    setState(() {});
  }

  void retrieveLocation() async {
    try {
      var _serviceEnabled = await locationService.serviceEnabled();
      if (!_serviceEnabled) {
        _serviceEnabled = await locationService.requestService();
        if (!_serviceEnabled) {
          print('Failed to enable service. Returning.');
          return;
        }
      }

      var _permissionGranted = await locationService.hasPermission();
      if (_permissionGranted == PermissionStatus.denied) {
        _permissionGranted = await locationService.requestPermission();
        if (_permissionGranted != PermissionStatus.granted) {
          print('Location service permission not granted. Returning.');
        }
      }

      locationData = await locationService.getLocation();
    } on PlatformException catch (e) {
      print('Error: ${e.toString()}, code: ${e.code}');
      locationData = null;
    }
    locationData = await locationService.getLocation();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(centerTitle: true, title: Text("New Post")),
        body: Column(children: [
          Container(
              padding: EdgeInsets.only(bottom: 20),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * .4,
              child: Image.network(widget.url!, fit: BoxFit.cover)),
          Form(
              key: formKey,
              child: Column(
                children: [
                  Semantics(
                      button: true,
                      label: "Enter the number of items wasted",
                      child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                              labelText: 'Number of wasted items',
                              border: OutlineInputBorder()),
                          onSaved: (value) {
                            postFields.quantity = int.parse(value!);
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter a value';
                            } else if (int.parse(value) <= 0) {
                              return 'Please enter a value 1 or greater';
                            } else {
                              return null;
                            }
                          })),
                ],
              ))
        ]),
        bottomNavigationBar: BottomAppBar(
          elevation: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                  child: Semantics(
                      button: true,
                      onTapHint: "Upload photo",
                      label: "Upload photo",
                      child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();
                              postFields.latitude = locationData!.latitude!;
                              postFields.longitude = locationData!.longitude!;
                              postFields.imageURL = widget.url!;
                              postFields.date = DateTime.now();
                              FirebaseFirestore.instance
                                  .collection('posts')
                                  .add({
                                'date': postFields.date,
                                'imageURL': postFields.imageURL,
                                'latitude': postFields.latitude,
                                'longitude': postFields.longitude,
                                'quantity': postFields.quantity
                              });
                              Navigator.of(context).pop();
                            }
                          },
                          child: Icon(Icons.cloud_upload, size: 150))))
            ],
          ),
        ));
  }
}
