import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/restaurant.dart';

class KakaoWebMap extends StatefulWidget {
  final double lat;
  final double lng;
  final List<Restaurant> restaurants;
  final Function(String markerId) onMarkerTap;
  final Function(double lat, double lng, int level) onCameraIdle;

  const KakaoWebMap({
    super.key,
    required this.lat,
    required this.lng,
    required this.restaurants,
    required this.onMarkerTap,
    required this.onCameraIdle,
  });

  @override
  State<KakaoWebMap> createState() => _KakaoWebMapState();
}

class _KakaoWebMapState extends State<KakaoWebMap> {
  late String _viewId;
  js.JsObject? _map;
  final List<js.JsObject> _markers = [];
  bool _sdkLoaded = false;
  html.DivElement? _mapContainer;

  @override
  void initState() {
    super.initState();
    _viewId = 'kakao-map-${DateTime.now().microsecondsSinceEpoch}';

    // Register view factory
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int id) {
        final element = html.DivElement()
          ..id = _viewId
          ..style.width = '100%'
          ..style.height = '100%';
        _mapContainer = element;
        return element;
      },
    );

    _loadSdk();
  }

  void _loadSdk() {
    if (js.context.hasProperty('kakao')) {
      setState(() {
        _sdkLoaded = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _initMap());
      return;
    }

    final appKey = dotenv.env['KAKAO_MAP_KEY'] ?? '';
    final script = html.ScriptElement()
      ..type = 'text/javascript'
      ..src =
          'https://dapi.kakao.com/v2/maps/sdk.js?autoload=false&appkey=$appKey&libraries=services,clusterer'
      ..async = true;

    html.document.head!.append(script);

    script.onLoad.listen((_) {
      setState(() {
        _sdkLoaded = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _initMap());
    });
  }

  void _initMap() {
    if (!mounted) return;

    final kakao = js.context['kakao'];
    if (kakao == null) return;

    final maps = kakao['maps'];
    if (maps == null) return;

    maps.callMethod('load', [
      () {
        final container = _mapContainer;
        if (container == null) return;

        final centerLatLng =
            js.JsObject(maps['LatLng'], [widget.lat, widget.lng]);
        final options = js.JsObject(js.context['Object']);
        options['center'] = centerLatLng;
        options['level'] = 8;

        _map = js.JsObject(maps['Map'], [container, options]);

        // Add idle listener
        maps['event'].callMethod('addListener', [
          _map,
          'idle',
          () {
            final center = _map!.callMethod('getCenter');
            final lat = center.callMethod('getLat') as double;
            final lng = center.callMethod('getLng') as double;
            final level = _map!.callMethod('getLevel') as int;
            widget.onCameraIdle(lat, lng, level);
          }
        ]);

        _updateMarkers();
      }
    ]);
  }

  @override
  void didUpdateWidget(covariant KakaoWebMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_map != null) {
      if ((widget.lat - oldWidget.lat).abs() > 0.0001 ||
          (widget.lng - oldWidget.lng).abs() > 0.0001) {
        final maps = js.context['kakao']['maps'];
        final latLng = js.JsObject(maps['LatLng'], [widget.lat, widget.lng]);
        _map!.callMethod('panTo', [latLng]);
      }
      _updateMarkers();
    }
  }

  void _updateMarkers() {
    if (_map == null) return;

    final kakao = js.context['kakao'];
    final maps = kakao['maps'];

    // Clear old markers
    for (final m in _markers) {
      m.callMethod('setMap', [null]);
    }
    _markers.clear();

    // Add new markers
    for (final r in widget.restaurants) {
      if (r.lat == null || r.lng == null) continue;

      final position = js.JsObject(maps['LatLng'], [r.lat, r.lng]);
      final markerOptions = js.JsObject(js.context['Object']);
      markerOptions['position'] = position;
      markerOptions['clickable'] = true;

      final marker = js.JsObject(maps['Marker'], [markerOptions]);
      marker.callMethod('setMap', [_map]);

      // Add click listener
      maps['event'].callMethod('addListener', [
        marker,
        'click',
        () {
          widget.onMarkerTap(r.id.toString());
        }
      ]);

      _markers.add(marker);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_sdkLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return SizedBox.expand(
      child: HtmlElementView(viewType: _viewId),
    );
  }
}
