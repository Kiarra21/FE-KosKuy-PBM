import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/app_colors.dart';

class BranchMapWidget extends StatelessWidget {
  const BranchMapWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.onPicked,
    this.height = 180,
  });

  final double latitude;
  final double longitude;
  final ValueChanged<LatLng>? onPicked;
  final double height;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        height: height,
        child: ColoredBox(
          color: const Color(0xFFE5E9EF),
          child: FlutterMap(
            key: ValueKey('${latitude.toStringAsFixed(6)}-$longitude'),
            options: MapOptions(
              initialCenter: point,
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 19,
              onTap: onPicked == null
                  ? null
                  : (tapPosition, selectedPoint) => onPicked!(selectedPoint),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                fallbackUrl:
                    'https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const [],
                userAgentPackageName: 'com.example.fe_sakukampus_pbm',
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint('KosKuy map tile error: $error');
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 42,
                    height: 42,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 42,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: .9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Map',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
