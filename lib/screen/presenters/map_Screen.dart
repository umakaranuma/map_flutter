// ignore_for_file: avoid_print, file_names

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:googlemp/screen/presenters/controller/map_controller.dart';
import 'dart:math' as math;

class MapScreen extends StatefulWidget {
  String userkey;
  MapScreen({required this.userkey, super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late LatLng centerPosition = const LatLng(9.7637672, 80.0293589);
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
  late double straightdistance = 0.0;

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
    MapPageController.requestLocationPermission(_getCurrentLocation);
  }

  Future<void> _getCurrentLocation() async {
    MapPageController.getCurrentLocationAndSetState((position) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    });
  }

  Future<void> _searchLocation(String locationName) async {
    try {
      List<Location> locations =
          await MapPageController.searchLocation(locationName);
      setState(() {
        markers.clear(); // Clear existing markers
      });

      if (locations.isNotEmpty) {
        for (Location location in locations) {
          LatLng searchedLocation =
              LatLng(location.latitude, location.longitude);
          MapPageController.addMarker(markers, searchedLocation);

          // Calculate straight-line distance
          if (_currentPosition != null) {
            double straightLineDistance =
                _distanceBetweenLatLng(_currentPosition!, searchedLocation);
            print(
                'Straight-line distance to $locationName: ${straightLineDistance.toStringAsFixed(2)} meters');
            straightdistance = straightLineDistance;
          }
        }
        Location firstLocation = locations.first;
        LatLng searchedLocation =
            LatLng(firstLocation.latitude, firstLocation.longitude);
        setState(() {
          centerPosition = searchedLocation;
          _mapController
              .animateCamera(CameraUpdate.newLatLngZoom(searchedLocation, 15));
          MapPageController.addMarker(markers, searchedLocation);
        });
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  Container placesAutoCompleteTextField() {
    return Container(
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
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: searchController,
        googleAPIKey: widget.userkey,
        inputDecoration: const InputDecoration(
          hintText: 'Search location',
          border: InputBorder.none,
        ),
        debounceTime: 400,
        // Modify countries array as needed
        // countries: [''], // Example: India and United States
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          // Handle place details here if needed
          print('Place Details: ${prediction.lat}, ${prediction.lng}');
        },
        itemClick: (Prediction prediction) {
          // Handle item click here
          _searchLocation(prediction.description ?? '');
        },
        seperatedBuilder: const Divider(),
      ),
    );
  }

  Future<void> _getRoute() async {
    if (_currentPosition != null) {
      try {
        PolylineResult result = await MapPageController.getRoute(
            _currentPosition!, centerPosition, widget.userkey);

        if (result.points.isNotEmpty) {
          setState(() {
            _polylineCoordinates = result.points
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();
          });
          distance =
              MapPageController.calculateDistance(_polylineCoordinates) / 1000;
          print('Distance: $distance kilometers');
        }
      } catch (e) {
        print('Error getting route: $e');
      }
    }
  }

  //Function To Calculate distance between two points
  double _distanceBetweenLatLng(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters

    double lat1Radians = math.pi * point1.latitude / 180;
    double lat2Radians = math.pi * point2.latitude / 180;
    double deltaLatRadians =
        math.pi * (point2.latitude - point1.latitude) / 180;
    double deltaLngRadians =
        math.pi * (point2.longitude - point1.longitude) / 180;

    double a = math.sin(deltaLatRadians / 2) * math.sin(deltaLatRadians / 2) +
        math.cos(lat1Radians) *
            math.cos(lat2Radians) *
            math.sin(deltaLngRadians / 2) *
            math.sin(deltaLngRadians / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map with Search Function'),
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
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
                  markers: markers,
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
                      fillColor: Colors.green.withOpacity(0.5),
                      strokeColor: Colors.green,
                      strokeWidth: 2,
                    ),
                  },
                ),
                for (int i = 0; i < _polylineCoordinates.length - 1; i++)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Column(
                      children: [
                        Text(
                          'Straight Distance: ${straightdistance.toStringAsFixed(2)} m',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Distance: ${distance.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _getRoute,
                    child: const Text('Show Route'),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 10,
                  right: 10,
                  child: searchbar(),
                ),
              ],
            ),
    );
  }

  Container searchbar() {
    return Container(
      child: GooglePlaceAutoCompleteTextField(
        boxDecoration: BoxDecoration(
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
        textEditingController: searchController,
        googleAPIKey: widget.userkey,
        inputDecoration: const InputDecoration(
          hintText: 'Search location',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20),
        ),
        debounceTime: 400,
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          // Handle place details here if needed
          print('Place Details: ${prediction.lat}, ${prediction.lng}');
        },
        itemClick: (Prediction prediction) {
          // Handle item click here
          _searchLocation(prediction.description ?? '');
        },
        seperatedBuilder: const Divider(),
      ),
    );
  }
}
