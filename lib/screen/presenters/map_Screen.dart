// ignore_for_file: avoid_print, file_names

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemp/screen/presenters/controller/map_controller.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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
  String userkey = "AIzaSyCAW13DZO4MqCDEdyjeTGWp7_kebTFE5E0";

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

      if (locations.isNotEmpty) {
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

  Future<void> _getRoute() async {
    if (_currentPosition != null) {
      try {
        PolylineResult result = await MapPageController.getRoute(
            _currentPosition!, centerPosition, userkey);

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
                    child: Text(
                      'Distance: ${distance.toStringAsFixed(2)} km',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
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
            },
            icon: const Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
