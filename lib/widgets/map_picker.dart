import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _barangayCenter = LatLng(14.18430, 120.79640);

  static final LatLngBounds _barangayBounds = LatLngBounds(
    const LatLng(14.1400, 120.7650),
    const LatLng(14.2250, 120.8400),
  );

  static const List<LatLng> _barangayPolygon = [
    LatLng(14.1400, 120.7650),
    LatLng(14.1400, 120.8400),
    LatLng(14.2250, 120.8400),
    LatLng(14.2250, 120.7650),
    LatLng(14.1400, 120.7650),
  ];

  LatLng _pickedLocation = _barangayCenter;
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isReverseGeocoding = false;
  String _streetAddress = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _reverseGeocode(_barangayCenter);
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
  }

  LatLng _clampToBounds(LatLng point) {
    final lat = point.latitude.clamp(
      _barangayBounds.south,
      _barangayBounds.north,
    );
    final lon = point.longitude.clamp(
      _barangayBounds.west,
      _barangayBounds.east,
    );
    return LatLng(lat, lon);
  }

  bool _isInsideBounds(LatLng point) {
    return _barangayBounds.contains(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isReverseGeocoding = true;
      _streetAddress = '';
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}'
        '&format=json&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'com.example.bfp_final'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] as String?;
          final neighbourhood = address['neighbourhood'] as String?;
          final village = address['village'] as String?;
          final suburb = address['suburb'] as String?;
          final city = address['city'] as String?
              ?? address['town'] as String?
              ?? address['municipality'] as String?;

          final parts = [
            road ?? neighbourhood,
            suburb ?? village,
            city,
          ].whereType<String>().toList();

          setState(() {
            _streetAddress = parts.isNotEmpty
                ? parts.join(', ')
                : (data['display_name'] as String? ?? '');
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _streetAddress = 'Unable to fetch address');
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&addressdetails=1'
        '&viewbox=${_barangayBounds.west},${_barangayBounds.north},'
        '${_barangayBounds.east},${_barangayBounds.south}'
        '&bounded=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'com.example.bfp_final'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        setState(() {
          _searchResults = results
              .map((r) => {
                    'display_name': r['display_name'] as String,
                    'lat': double.parse(r['lat']),
                    'lon': double.parse(r['lon']),
                  })
              .toList();
          _showResults = _searchResults.isNotEmpty;
        });

        if (_searchResults.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found within the area.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectResult(Map<String, dynamic> result) {
    final location = LatLng(result['lat'], result['lon']);
    final clamped = _clampToBounds(location);
    setState(() {
      _pickedLocation = clamped;
      _showResults = false;
      _searchController.text = result['display_name'];
    });
    _mapController.move(clamped, 17.0);
    FocusScope.of(context).unfocus();
    _reverseGeocode(clamped);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.place, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    '${_searchResults.length} result${_searchResults.length > 1 ? 's' : ''} found',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // Results list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final parts = (result['display_name'] as String).split(', ');
                  final title = parts.first;
                  final subtitle =
                      parts.length > 1 ? parts.skip(1).join(', ') : '';

                  return InkWell(
                    onTap: () => _selectResult(result),
                    splashColor: Colors.red.withValues(alpha: 0.06),
                    highlightColor: Colors.red.withValues(alpha: 0.03),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: index < _searchResults.length - 1
                            ? Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              )
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 8),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 11,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gen. E. Aguinaldo / Bailen'),
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _barangayCenter,
              initialZoom: 15.5,
              minZoom: 14.5,
              maxZoom: 19.0,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: _barangayBounds,
              ),
              onTap: (tapPosition, point) {
                if (_isInsideBounds(point)) {
                  setState(() {
                    _pickedLocation = point;
                    _showResults = false;
                  });
                  FocusScope.of(context).unfocus();
                  _reverseGeocode(point);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please pick a location within the barangay.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bfp_final',
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _barangayPolygon,
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderColor: Colors.blue.withValues(alpha: 0.6),
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Current location — blue dot
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.circle,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),

                  // Picked location — red pin
                  Marker(
                    point: _pickedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Search bar + dropdown ─────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (value == _searchController.text) {
                          _searchLocation(value);
                        }
                      });
                    },
                    onSubmitted: _searchLocation,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_showResults) _buildSearchResults(),
              ],
            ),
          ),

          // ── Address + Confirm card ────────────────────────────
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Street address row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isReverseGeocoding
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _streetAddress.isNotEmpty
                                      ? _streetAddress
                                      : 'Tap the map to pick a location',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirm Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isReverseGeocoding
                            ? null
                            : () => Navigator.pop(context, {
                                  'location': _pickedLocation,
                                  'address': _streetAddress,
                                }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}