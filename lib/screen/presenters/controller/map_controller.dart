// ignore_for_file: avoid_print

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPageController {
  static Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
    );
  }

  static Future<List<Location>> searchLocation(String locationName) async {
    return await locationFromAddress(locationName);
  }

  static Future<PolylineResult> getRoute(
      LatLng currentPosition, LatLng centerPosition, String userkey) async {
    PolylinePoints polylinePoints = PolylinePoints();
    return await polylinePoints.getRouteBetweenCoordinates(
      userkey,
      PointLatLng(currentPosition.latitude, currentPosition.longitude),
      PointLatLng(centerPosition.latitude, centerPosition.longitude),
      travelMode: TravelMode.driving,
    );
  }

  static double calculateDistance(List<LatLng> points) {
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

  static Future<void> requestLocationPermission(
      Function() onPermissionGranted) async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      onPermissionGranted();
    } else {
      print('Location permission denied');
    }
  }

  static Future<void> getCurrentLocationAndSetState(
      Function(Position) setStateFunction) async {
    try {
      Position position = await getCurrentLocation();
      setStateFunction(position);
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  static void addMarker(Set<Marker> markers, LatLng location) {
    markers.add(
      Marker(
        markerId: MarkerId(location.toString()),
        position: location,
        infoWindow: const InfoWindow(
          title: 'Searched Location',
          snippet: 'This is the location you searched before',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }
}
