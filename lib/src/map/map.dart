import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class MapPage extends StatefulWidget {
  MapPage({
    Key key,
    @required this.lat,
    @required this.lng,
    @required this.mapController,
    @required this.markers,
    this.isNominatim = true,
    this.apiKey,
    this.customMapLayer,
    this.onTap,
    this.buildMarkerIcon,
  }) : super(key: key);
  final List<Marker> markers;
  final double lat;
  final double lng;
  final MapController mapController;
  final bool isNominatim;
  final String apiKey;
  final TileLayerOptions customMapLayer;
  final Function(LatLng) onTap;
  final Widget buildMarkerIcon;

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //Marker marker;
  List<Marker> markers;
  Widget body(BuildContext context) {
    return new FlutterMap(
      mapController: widget.mapController,
      options: MapOptions(
        center: LatLng(widget.lat, widget.lng),
        zoom: 13,
        maxZoom: 18,
        onTap: (point){
          widget.onTap(point);
          setState(() {
            markers[0] = Marker(
              width: 80.0,
              height: 80.0,
              point: point,
              builder: (ctx) => widget.buildMarkerIcon,
            );
          });
        },
      ),
      layers: [
        widget.isNominatim
            ? widget.customMapLayer == null
                ? new TileLayerOptions(
                    urlTemplate:
                        'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c'],
                    tileProvider: CachedNetworkTileProvider())
                : widget.customMapLayer
            : widget.customMapLayer == null
                ? new TileLayerOptions(
                    urlTemplate: "https://api.tiles.mapbox.com/v4/"
                        "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
                    additionalOptions: {
                      'accessToken': widget.apiKey,
                      'id': 'mapbox.streets',
                    },
                  )
                : widget.customMapLayer,
        MarkerLayerOptions(
          // markers: widget.markers,
          markers: markers
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: body(context),
    );
  }

  @override
  void initState() {
    super.initState();
    markers = widget.markers;
  }
}
