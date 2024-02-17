import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geocoding/geocoding.dart';

class ConvertLatingToDtring extends StatefulWidget {
  const ConvertLatingToDtring({super.key});

  @override
  State<ConvertLatingToDtring> createState() => _ConvertLatingToDtringState();
}

class _ConvertLatingToDtringState extends State<ConvertLatingToDtring> {

  String stAddress = '', stAdd = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Map Address'),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(stAddress),
          Text(stAdd),
          GestureDetector(
            onTap: ()async{

              List<Location> locations = await locationFromAddress("Gronausestraat 710, Enschede");
              List<Placemark> placemarks = await placemarkFromCoordinates(52.2165157, 6.9437819);



              //final coordinates = new Coordinates()


                  setState(() {
                    stAddress = locations.last.longitude.toString()+" "+locations.last.latitude.toString();
                    stAdd = placemarks.reversed.last.country.toString()+" "+placemarks.reversed.last.subAdministrativeArea.toString();
                  });

            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.green
                ),
                child: Center(
                  child: Text('convert'),
                ),
              ),
            ),
          )


        ],
      ),
    );
  }
}
