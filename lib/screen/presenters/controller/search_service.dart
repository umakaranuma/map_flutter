// search_service.dart

import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googlemp/screen/presenters/controller/map_controller.dart';
import 'dart:math' as math;

class SearchService {
  static Future<void> searchLocation(String locationName, Set<Marker> markers,
      LatLng? currentPosition, GoogleMapController mapController) async {
    try {
      List<Location> locations =
          await MapPageController.searchLocation(locationName);
      markers.clear(); // Clear existing markers

      if (locations.isNotEmpty) {
        for (Location location in locations) {
          LatLng searchedLocation =
              LatLng(location.latitude, location.longitude);
          MapPageController.addMarker(markers, searchedLocation);

          // Calculate straight-line distance
          if (currentPosition != null) {
            double straightLineDistance =
                _distanceBetweenLatLng(currentPosition, searchedLocation);
            print(
                'Straight-line distance to $locationName: ${straightLineDistance.toStringAsFixed(2)} meters');
          }
        }
        Location firstLocation = locations.first;
        LatLng searchedLocation =
            LatLng(firstLocation.latitude, firstLocation.longitude);
        mapController
            .animateCamera(CameraUpdate.newLatLngZoom(searchedLocation, 15));
        MapPageController.addMarker(markers, searchedLocation);
      }
    } catch (e) {
      print('Error searching location: $e');
    }
  }

  static double _distanceBetweenLatLng(LatLng point1, LatLng point2) {
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
}
