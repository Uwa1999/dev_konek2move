import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:konek2move/utils/app_colors.dart';
import 'package:shimmer/shimmer.dart';

const kGoogleApiKey = "AIzaSyA4eJv1jVmJWrTdOO6SOsEGirFKueKRg98";

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _currentPosition = const LatLng(14.5995, 120.9842);
  bool _loading = true;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _placeSuggestions = [];
  bool _showSuggestions = false;

  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};

  double _distanceKm = 0.0;
  String _eta = "";

  // Map style strings
  String _normalMapStyle = '';
  String _darkMapStyle = '';
  String _retroMapStyle = '';
  String _currentMapStyle = '';

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadMapStyles();
  }

  Future<void> _loadMapStyles() async {
    // Replace these JSON strings with your Google Maps Styling Wizard JSON
    _normalMapStyle = '[]'; // default
    _darkMapStyle = '''
[
  {"elementType": "geometry", "stylers":[{"color": "#212121"}]},
  {"elementType": "labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType": "labels.text.fill","stylers":[{"color": "#e0e0e0"}]},  // softer text
  {"featureType": "road","elementType": "geometry","stylers":[{"color":"#424242"}]},
  {"featureType": "road","elementType": "geometry.stroke","stylers":[{"color":"#212121"}]},
  {"featureType": "road","elementType": "labels.text.fill","stylers":[{"color":"#b0b0b0"}]}, 
  {"featureType": "road.highway","elementType": "geometry","stylers":[{"color":"#616161"}]},
  {"featureType": "road.highway","elementType": "geometry.stroke","stylers":[{"color":"#212121"}]},
  {"featureType": "road.highway","elementType": "labels.text.fill","stylers":[{"color":"#d0d0d0"}]} 
]


''';
    _retroMapStyle = '''
[
  {"elementType": "geometry","stylers":[{"color":"#ebe3cd"}]},
  {"elementType": "labels.text.fill","stylers":[{"color":"#523735"}]},
  {"featureType": "road","elementType": "geometry","stylers":[{"color":"#f5f1e6"}]},
  {"featureType": "road","elementType": "geometry.stroke","stylers":[{"color":"#c9b2a6"}]},
  {"featureType": "road.highway","elementType": "geometry","stylers":[{"color":"#f8c967"}]},
  {"featureType": "road.highway","elementType": "geometry.stroke","stylers":[{"color":"#e9bc62"}]},
  {"featureType": "road.highway","elementType": "labels.text.fill","stylers":[{"color":"#000000"}]}
]

''';
    _currentMapStyle = _normalMapStyle;
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _loading = false;
    });

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 16),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    mapController.setMapStyle(_currentMapStyle);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _showSuggestions = false;
      _placeSuggestions = [];
      _markers.clear();
      _polylines.clear();
      _distanceKm = 0.0;
      _eta = "";
    });
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _placeSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final url =
        "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(input)}&key=$kGoogleApiKey&types=geocode&language=en&components=country:PH";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _placeSuggestions = data['predictions'];
        _showSuggestions = true;
      });
    }
  }

  Future<void> _selectPlace(String placeId, String description) async {
    final url =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey";

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final location = data['result']['geometry']['location'];
      final LatLng destination = LatLng(location['lat'], location['lng']);

      mapController.animateCamera(CameraUpdate.newLatLngZoom(destination, 16));

      _polylines.clear();
      _markers.clear();

      _markers.add(
        Marker(
          markerId: const MarkerId('current'),
          position: _currentPosition,
          infoWindow: const InfoWindow(title: "You"),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(title: description),
        ),
      );

      await _createPolyline(_currentPosition, destination);

      setState(() {
        _searchController.text = description;
        _showSuggestions = false;
        _placeSuggestions = [];
      });
    }
  }

  // Future<void> _createPolyline(LatLng origin, LatLng destination) async {
  //   final url =
  //       'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$kGoogleApiKey';
  //
  //   final response = await http.get(Uri.parse(url));
  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     if (data['routes'].isNotEmpty) {
  //       final points = data['routes'][0]['overview_polyline']['points'];
  //       final polylineCoordinates = _decodePolyline(points);
  //
  //       final legs = data['routes'][0]['legs'];
  //       double distanceMeters = 0;
  //       String etaText = "";
  //       if (legs.isNotEmpty) {
  //         distanceMeters = legs[0]['distance']['value'].toDouble();
  //         etaText = legs[0]['duration']['text'];
  //       }
  //
  //       setState(() {
  //         _polylines.add(
  //           Polyline(
  //             polylineId: const PolylineId('route'),
  //             points: polylineCoordinates,
  //             color: AppColors.primary,
  //             width: 5,
  //           ),
  //         );
  //         _distanceKm = distanceMeters / 1000;
  //         _eta = etaText;
  //       });
  //     }
  //   }
  // }
  Future<void> _createPolyline(LatLng origin, LatLng destination) async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$kGoogleApiKey&departure_time=now';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    if (data['routes'].isEmpty) return;

    final route = data['routes'][0];
    final legs = route['legs'];
    if (legs.isEmpty) return;

    final leg = legs[0];
    final distanceMeters = leg['distance']['value'].toDouble();
    final etaText = leg['duration_in_traffic'] != null
        ? leg['duration_in_traffic']['text']
        : leg['duration']['text'];

    final List<LatLng> routePoints = _decodePolyline(
      route['overview_polyline']['points'],
    );

    // Clear old polylines
    _polylines.clear();

    // 1️⃣ Add background line (white glow)
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route_bg'),
        points: routePoints,
        color: Colors.white.withOpacity(0.6),
        width: 12,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      ),
    );

    // 2️⃣ Add foreground line with traffic-aware colors along steps
    for (var step in leg['steps']) {
      final stepPoints = _decodePolyline(step['polyline']['points']);
      final duration = step['duration']['value']; // seconds
      final distance = step['distance']['value']; // meters
      final speed = distance / duration; // meters per second (rough)

      // Assign traffic color
      Color color;
      if (speed < 4) {
        color = Colors.red; // heavy traffic
      } else if (speed < 8) {
        color = Colors.orange; // moderate traffic
      } else {
        color = AppColors.primary; // free-flow
      }

      _polylines.add(
        Polyline(
          polylineId: PolylineId(step['html_instructions']),
          points: stepPoints,
          color: color,
          width: 6,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          geodesic: true,
        ),
      );
    }

    setState(() {
      _distanceKm = distanceMeters / 1000;
      _eta = etaText;
    });
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polyline.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return polyline;
  }

  void _showMapStyleDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final styles = [
          {
            "name": "Normal",
            "description": "Default Google Map.",
            "style": _normalMapStyle,
          },
          {
            "name": "Dark",
            "description": "Dark theme, ideal for night-time.",
            "style": _darkMapStyle,
          },
          {
            "name": "Retro",
            "description": "Vintage retro style.",
            "style": _retroMapStyle,
          },
        ];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 50,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Text(
                'Select Map Style',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // List of styles
              ...styles.map((item) {
                final isSelected = _currentMapStyle == item["style"];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: Text(
                    item["name"]!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    item["description"]!,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : null,
                  onTap: () {
                    _applyMapStyle(item["style"]!);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _applyMapStyle(String style) {
    setState(() {
      _currentMapStyle = style;
    });
    mapController.setMapStyle(_currentMapStyle);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _loading
              ? Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(color: Colors.grey[300]),
                )
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  markers: _markers,
                  polylines: _polylines,
                  // trafficEnabled: true,
                ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Material(
                  color: AppColors.surface,
                  elevation: 5,
                  borderRadius: BorderRadius.circular(24),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search place...',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
                    ),
                    onChanged: _fetchSuggestions,
                  ),
                ),
                if (_showSuggestions && _placeSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _placeSuggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 0),
                      itemBuilder: (context, index) {
                        final suggestion = _placeSuggestions[index];
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () => _selectPlace(
                            suggestion['place_id'],
                            suggestion['description'],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_distanceKm > 0 && _eta.isNotEmpty)
            Positioned(
              bottom: 12,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Distance: ${_distanceKm.toStringAsFixed(2)} km | ETA: $_eta',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                _fab(Icons.my_location, "My Location", () {
                  mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition, 16),
                  );
                }),
                const SizedBox(height: 12),
                _fab(Icons.add, "Zoom In", () {
                  mapController.animateCamera(CameraUpdate.zoomIn());
                }),
                const SizedBox(height: 12),
                _fab(Icons.remove, "Zoom Out", () {
                  mapController.animateCamera(CameraUpdate.zoomOut());
                }),
                const SizedBox(height: 12),
                _fab(Icons.style, "Map Style", () {
                  _showMapStyleDialog();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fab(IconData icon, String tooltip, VoidCallback onPressed) {
    return FloatingActionButton(
      onPressed: onPressed,
      mini: true,
      tooltip: tooltip,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.primary,
      elevation: 6,
      child: Icon(icon),
    );
  }
}
