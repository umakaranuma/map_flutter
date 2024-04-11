// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late LatLng centerPosition = const LatLng(8.7637708, 80.0292578);
  LatLng? _currentPosition;
  late List<LatLng> _polylineCoordinates = [];
  late final List<LatLng> _polygonCoordinates = [
    const LatLng(
        6.9731, 79.9718), // Sample polygon coordinates, modify as needed
    const LatLng(6.9732, 79.9719),
    const LatLng(6.9733, 79.9720),
    // Add more vertices as needed
  ];
  late GoogleMapController _mapController;
  TextEditingController searchController = TextEditingController();
  Set<Marker> markers = {};
  late double distance = 0.0;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    } else {
      print('Location permission denied');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _getRoute();
        // print('Current position: $_currentPosition');
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  Future<void> _searchLocation(String locationName) async {
    try {
      List<Location> locations = await locationFromAddress(locationName);

      if (locations.isNotEmpty) {
        Location firstLocation = locations.first;
        LatLng searchedLocation =
            LatLng(firstLocation.latitude, firstLocation.longitude);
        setState(() {
          // _currentPosition = searchedLocation;
          centerPosition = searchedLocation; // Update _centerSriLanka
          _mapController.animateCamera(CameraUpdate.newLatLngZoom(
              searchedLocation, 15)); // Adjust zoom level as needed
          _addMarker(searchedLocation); // Add marker at the searched location
          _getRoute(); // Update route to the searched location
        });
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  void _addMarker(LatLng location) {
    setState(() {
      markers.add(
        Marker(
          markerId: MarkerId(location.toString()),
          position: location,
          infoWindow: const InfoWindow(
            title: 'Searched Location',
            snippet: 'This is the location you searched for',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue), // Use blue marker
          // If you want to use a custom location icon:
          // icon: BitmapDescriptor.fromAsset('assets/location_icon.png'),
        ),
      );
    });
  }

  Future<void> _getRoute() async {
    PolylinePoints polylinePoints = PolylinePoints();
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      'AIzaSyCAW13DZO4MqCDEdyjeTGWp7_kebTFE5E0',
      PointLatLng(_currentPosition!.latitude, _currentPosition!.longitude),
      PointLatLng(
        centerPosition.latitude,
        centerPosition.longitude,
      ),
      travelMode: TravelMode.driving,
    );

    if (result.points.isNotEmpty) {
      setState(() {
        _polylineCoordinates = result.points
            .map((point) => LatLng(point.latitude, point.longitude))
            .toList();
      });
      distance = calculateDistance(_polylineCoordinates);
      print('Distance: $distance meters');
    }
  }

  double calculateDistance(List<LatLng> points) {
    double totalDistance = 0.0;
    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        points[i].latitude,
        points[i].longitude,
        points[i + 1].latitude,
        points[i + 1].longitude,
      );
    }
    return totalDistance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map with Search Function'),
      ),
      body: _currentPosition == null
          ? const Center(
              child:
                  CircularProgressIndicator()) // Display loader while loading
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 8,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId("_sourceLocation"),
                      icon: BitmapDescriptor.defaultMarker,
                      position: centerPosition,
                    ),
                  },
                  polylines: {
                    if (_polylineCoordinates.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId("poly"),
                        color: Colors.black,
                        points: _polylineCoordinates,
                        width: 5,
                      ),
                  },
                  polygons: {
                    Polygon(
                      polygonId: const PolygonId("polygon"),
                      points: _polygonCoordinates,
                      fillColor: Colors.green.withOpacity(0.5), // Fill color
                      strokeColor: Colors.green, // Border color
                      strokeWidth: 2, // Border width
                    ),
                  },
                ),
                Positioned(
                  top: 100,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search location',
                              border: InputBorder.none,
                            ),
                            onSubmitted: _searchLocation,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _searchLocation(searchController.text);
                            // setState(() {
                            //   print('uuuuuuu${searchController.text}');
                            // });
                          },
                          icon: const Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
