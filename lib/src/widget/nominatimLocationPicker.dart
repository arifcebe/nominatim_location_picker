import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:nominatim_location_picker/src/loaders/loader_animator.dart';
import 'package:nominatim_location_picker/src/map/map.dart';
import 'package:nominatim_location_picker/src/services/nominatim.dart';
import 'package:auto_size_text/auto_size_text.dart';

class NominatimLocationPicker extends StatefulWidget {
  NominatimLocationPicker({
    this.searchHint = 'Search',
    this.awaitingForLocation = "Awaiting for you current location",
    this.customMarkerIcon,
    this.customMapLayer,
    this.location,
  });

  final String searchHint;
  final String awaitingForLocation;

  //
  final TileLayerOptions customMapLayer;

  //
  final Widget customMarkerIcon;
  final LatLng location;

  @override
  _NominatimLocationPickerState createState() =>
      _NominatimLocationPickerState();
}

class _NominatimLocationPickerState extends State<NominatimLocationPicker> {
  Map retorno;
  static Color primaryColor = Color(0xFFCB2240);
  List _addresses = List();

  //Color _color = primaryColor;
  TextEditingController _ctrlSearch = TextEditingController();
  Position _currentPosition;
  String _desc;
  bool _isSearching = false;
  double _lat;
  double _lng;
  MapController _mapController = MapController();

  List<Marker> _markers;

  LatLng _point;

  static final _defaultLocation = LatLng(0.0009845, 109.3222122);

  LatLng get _location => widget.location;

  @override
  void dispose() {
    _ctrlSearch.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _point = _location ?? _defaultLocation;
    _markers = [
      /*
      --- manage marker
    */
      Marker(
        width: 80.0,
        height: 80.0,
        point: _point,
        builder: (ctx) => _buildMarkerIcon(),
      )
    ];
    if (_location == null) {
      _getCurrentLocation();
    } else {
      _setupExistingLocation();
    }
  }

  void _changeAppBar() {
    /*
    --- manage appbar state
  */
    setState(() {
      _isSearching = !_isSearching;
    });
  }

  Widget _buildMarkerIcon() {
    return new Container(
        child: widget.customMarkerIcon == null
            ? Icon(
                Icons.location_on,
                size: 50.0,
              )
            : widget.customMarkerIcon);
  }

  _getCurrentLocation() {
    /*
    --- Função responsável por receber a localização atual do usuário
  */
    final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        _getCurrentLocationMarker();
        _getCurrentLocationDesc();
      });
    }).catchError((e) {
      print(e);
    });
  }

  _setupExistingLocation() {
    _currentPosition = Position(
      longitude: widget.location.longitude,
      latitude: widget.location.latitude,
    );
    _getCurrentLocationMarker();
    _getCurrentLocationDesc();
  }

  _getCurrentLocationMarker() {
    /*
    --- Função responsável por atualizar o marcador para a localização atual do usuário
  */
    setState(() {
      _lat = _currentPosition.latitude;
      _lng = _currentPosition.longitude;
      _point = LatLng(_lat, _lng);
      _markers[0] = Marker(
        width: 80.0,
        height: 80.0,
        // point: LatLng(_currentPosition.latitude, _currentPosition.longitude),
        point: _point,
        builder: (ctx) => _buildMarkerIcon(),
      );
    });
  }

  _getCurrentLocationDesc() async {
    /*
    --- Função responsável por atualizar a descrição para a referente a localização atual do usuário
  */
    dynamic res = await NominatimService().getAddressLatLng(
        "${_currentPosition.latitude} ${_currentPosition.longitude}");
    setState(() {
      _addresses = res;
      _lat = _currentPosition.latitude;
      _lng = _currentPosition.longitude;
      _point = LatLng(_lat, _lng);
      retorno = {
        'latlng': _point,
        'state': _addresses[0]['state'],
        'desc':
            "${_addresses[0]['state']}, ${_addresses[0]['city']}, ${_addresses[0]['suburb']}, ${_addresses[0]['neighbourhood']}, ${_addresses[0]['road']}"
      };
      _desc = _addresses[0]['description'];
    });
  }

  onWillpop() {
    /*
    --- Função responsável por controlar o retorno da página de pesquisas para a de buscas
  */
    setState(() {
      _isSearching = false;
    });
  }

  _buildAppbar(bool _isResult) {
    /*
    --- Widget responsável constução da appbar customizada .
  */
    return new AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      primary: true,
      title: _buildTextField(_isResult),
      leading: IconButton(
        icon: Icon(_isResult ? Icons.close : Icons.arrow_back_ios,
            color: primaryColor),
        onPressed: () {
          _isSearching
              ? setState(() {
                  _isSearching = false;
                })
              : Navigator.of(context).pop();
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus) {
            currentFocus.unfocus();
          }
          setState(() {
            _isSearching = false;
          });
        },
      ),
    );
  }

  _buildTextField(bool _isResult) {
    /*
    --- Responsável constução do textfield de pesquisa .
  */
    return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 0, 5, 0),
                child: TextFormField(
                  controller: _ctrlSearch,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  onFieldSubmitted: (value) {
                    _startSearchLocation(_isResult);
                  },
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.search, color: primaryColor),
              onPressed: () {
                _startSearchLocation(_isResult);
              },
            ),
          ],
        ));
  }

  void _startSearchLocation(bool isResult) async {
    FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }
    isResult == false
        ? _changeAppBar()
        : setState(() {
            _isSearching = true;
          });
    dynamic res = await NominatimService().getAddressLatLng(_ctrlSearch.text);
    setState(() {
      _addresses = res;
    });
  }

  Widget mapContext(BuildContext context) {
    /*
    --- Widget responsável pela representação cartográfica da região, assim como seu ponto no espaço.
  */
    while (_currentPosition == null) {
      return new Center(
        child: Loading(),
      );
    }

    return new MapPage(
      lat: _lat,
      lng: _lng,
      mapController: _mapController,
      markers: _markers,
      customMapLayer: widget.customMapLayer,
      onTap: (point) async {
        dynamic res = await NominatimService()
            .getAddressLatLng("${point.latitude} ${point.longitude}");
        setState(() {
          _addresses = res;
          _lat = point.latitude;
          _lng = point.longitude;
          _point = LatLng(_lat, _lng);
          retorno = {
            'latlng': _point,
            'state': _addresses[0]['state'],
            'desc':
                "${_addresses[0]['state']}, ${_addresses[0]['city']}, ${_addresses[0]['suburb']}, ${_addresses[0]['neighbourhood']}, ${_addresses[0]['road']}"
          };
          _desc = _addresses[0]['description'];
        });
      },
      buildMarkerIcon: _buildMarkerIcon(),
    );
  }

  Widget _buildBody(BuildContext context) {
    /*
    --- Widget responsável constução da página como um todo.
  */
    return new Stack(
      children: <Widget>[
        mapContext(context),
        _isSearching ? Container() : _buildDescriptionCard(),
        _isSearching ? Container() : floatingActionButton(),
        _isSearching ? searchOptions() : Text(''),
      ],
    );
  }

  Widget _buildDescriptionCard() {
    /*
    --- Widget responsável constução das descrições de um determinado local.
  */
    return new Positioned(
      bottom: MediaQuery.of(context).size.width * 0.05,
      right: MediaQuery.of(context).size.width * 0.05,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.15,
            child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 4,
                child: Row(
                  children: <Widget>[
                    Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        padding: EdgeInsets.all(15),
                        child: Center(
                            child: Scrollbar(
                                child: new SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          reverse: false,
                          child: AutoSizeText(
                            _desc == null ? widget.awaitingForLocation : _desc,
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.start,
                          ),
                        )))),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  floatingActionButton() {
    /*
    --- Widget responsável pelo envio das coordenadas LatLong para serem utilizadas por terceiros .
  */
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return new Positioned(
      bottom: -width * 0.025 + height * 0.075,
      right: width * 0.1,
      child: Container(
        height: width * 0.15,
        width: width * 0.15,
        child: FittedBox(
          child: FloatingActionButton(
              backgroundColor: primaryColor,
              child: Icon(Icons.arrow_forward),
              onPressed: () {
                Navigator.pop(context, retorno);
              }),
        ),
      ),
    );
  }

  Widget searchOptions() {
    /*
    --- Widget responsável pela exibição tela de exibição de um conjunto de resultados da pesquisa.
  */
    return new WillPopScope(
      onWillPop: () async => onWillpop(), //Bloquear o retorno
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          padding: EdgeInsets.fromLTRB(10, 5, 10, 20),
          color: Colors.transparent,
          child: ListView.builder(
            itemCount: _addresses.length,
            itemBuilder: (BuildContext ctx, int index) {
              return GestureDetector(
                child: _buildLocationCard(_addresses[index]['description']),
                onTap: () {
                  _mapController.move(
                      LatLng(double.parse(_addresses[index]['lat']),
                          double.parse(_addresses[index]['lng'])),
                      19);

                  setState(() {
                    _desc = _addresses[index][
                        'description']; /*"${_addresses[index]['country']}, ${_addresses[index]['state']}, ${_addresses[index]['city']}, ${_addresses[index]['city_district']}, ${_addresses[index]['suburb']}";*/
                    _isSearching = false;
                    _lat = double.parse(_addresses[index]['lat']);
                    _lng = double.parse(_addresses[index]['lng']);
                    retorno = {
                      'latlng': LatLng(_lat, _lng),
                      'state': _addresses[index]['state'],
                      'desc':
                          "${_addresses[index]['state']}, ${_addresses[index]['city']}, ${_addresses[index]['suburb']}, ${_addresses[index]['neighbourhood']}, ${_addresses[index]['road']}"
                    };
                    _markers[0] = Marker(
                      width: 80.0,
                      height: 80.0,
                      point: LatLng(double.parse(_addresses[index]['lat']),
                          double.parse(_addresses[index]['lng'])),
                      builder: (ctx) => new Container(
                          child: widget.customMarkerIcon == null
                              ? Icon(
                                  Icons.location_on,
                                  size: 50.0,
                                )
                              : widget.customMarkerIcon),
                    );
                  });
                },
              );
            },
          ),
        ),
      ),
    );
  }

  _buildLocationCard(String text) {
    /*
    --- Widget responsável constução individual dos resultados de uma pesquisa .
  */
    return new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.15,
          child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              //color: Colors.white,
              elevation: 0,
              child: Container(
                  padding: EdgeInsets.all(15),
                  child: AutoSizeText(
                    text,
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ))),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppbar(_isSearching),
      body: _buildBody(context),
    );
  }
}
