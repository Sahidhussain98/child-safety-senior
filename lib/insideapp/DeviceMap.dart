import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DeviceMap extends StatefulWidget {
  final Set<Marker> markers;
  final CameraPosition initialCameraPosition;

  DeviceMap({
    required this.markers,
    required this.initialCameraPosition,
  });

  @override
  _DeviceMapState createState() => _DeviceMapState();
}

class _DeviceMapState extends State<DeviceMap> {
  Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Map'),
      ),
      body: GoogleMap(
        initialCameraPosition: widget.initialCameraPosition,
        markers: widget.markers,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
