import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/location_provider.dart';
import '../models/signalement.dart';

class MapScreen extends StatefulWidget {
  final Signalement? signalement;
  final bool isEditMode;
  final bool isViewMode;

  const MapScreen({
    super.key,
    this.signalement,
    this.isEditMode = false,
    this.isViewMode = false,
  }) : assert(!(isEditMode && isViewMode), "Les modes edit et view ne peuvent pas être activés simultanément");

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializePosition();
    _checkLocationPermissions();
  }

  void _initializePosition() {
    if (widget.signalement != null) {
      _selectedPosition = LatLng(
        widget.signalement!.latitude,
        widget.signalement!.longitude,
      );
    }
  }

  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _isLoading = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && 
          permission != LocationPermission.always) {
        setState(() => _isLoading = false);
        return;
      }
    }

    setState(() => _isLoading = false);
  }

  void _centerMapOnUser(LatLng position) {
    _mapController.move(position, 13.0);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (!widget.isViewMode) { // Désactive les clics en mode visualisation
      setState(() => _selectedPosition = point);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPosition = context.watch<LocationProvider>().position;
    final initialPosition = _getInitialPosition(userPosition);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildMapContent(initialPosition),
      floatingActionButton: _buildFloatingActionButton(initialPosition),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        widget.isViewMode 
          ? "Localisation du signalement"
          : widget.isEditMode
            ? "Modifier la localisation"
            : "Choisir une localisation",
      ),
      actions: _buildAppBarActions(),
    );
  }

  List<Widget>? _buildAppBarActions() {
    if (widget.isViewMode) return null;

    return [
      IconButton(
        icon: const Icon(Icons.my_location),
        onPressed: () => _centerMapOnUser(_getUserPosition()),
      ),
      if (!widget.isViewMode)
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _selectedPosition != null
              ? () => Navigator.pop(context, _selectedPosition)
              : null,
        ),
    ];
  }

  Widget _buildMapContent(LatLng initialPosition) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialPosition,
            initialZoom: 13.0,
            onTap: _onMapTap,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [_buildMainMarker()],
            ),
          ],
        ),
        if (_shouldShowPositionInfo())
          _buildPositionInfo(),
      ],
    );
  }

  Marker _buildMainMarker() {
    final position = _selectedPosition ?? _getInitialPosition(null);
    return Marker(
      point: position,
      width: 40,
      height: 40,
      child: Icon(
        Icons.location_pin,
        color: widget.isViewMode ? Colors.green : Colors.red,
        size: 40,
      ),
    );
  }

  Widget? _buildFloatingActionButton(LatLng initialPosition) {
    if (widget.isViewMode) return null;

    return FloatingActionButton(
      onPressed: () => _centerMapOnUser(initialPosition),
      child: const Icon(Icons.gps_fixed),
    );
  }

  Widget _buildPositionInfo() {
    return Positioned(
      bottom: 15,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Text(
            'Position ${widget.isViewMode ? 'du signalement' : 'sélectionnée'}:\n'
            'Latitude: ${_selectedPosition!.latitude.toStringAsFixed(5)}\n'
            'Longitude: ${_selectedPosition!.longitude.toStringAsFixed(5)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  LatLng _getInitialPosition(Position? userPosition) {
    if (widget.signalement != null) {
      return LatLng(
        widget.signalement!.latitude,
        widget.signalement!.longitude,
      );
    }
    return userPosition != null
        ? LatLng(userPosition.latitude, userPosition.longitude)
        : const LatLng(5.3489, -4.0037);
  }

  LatLng _getUserPosition() {
    final userPosition = context.read<LocationProvider>().position;
    return userPosition != null
        ? LatLng(userPosition.latitude, userPosition.longitude)
        : const LatLng(5.3489, -4.0037);
  }

  bool _shouldShowPositionInfo() {
    return _selectedPosition != null || widget.signalement != null;
  }
}