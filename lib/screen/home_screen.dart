import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

    bool choolCheckDone =false;
    GoogleMapController? mapController;


  //latitude, longitude

  static final LatLng companyLatLng = LatLng(
    37.647825198564725,
    126.92027554384417,
  );

  static final double okDistance = 100;
  static final Circle withinDistanceCircle = Circle(
    circleId: CircleId('withinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.blue.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.blue,   //원둘레색
    strokeWidth: 1,
  );
  static final Circle notWithinDistanceCircle = Circle(
    circleId: CircleId('notWithinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.red.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.red,   //원둘레색
    strokeWidth: 1,
  );
  static final Circle chckDoneCircle = Circle(
    circleId: CircleId('chckDoneCircle'),
    center: companyLatLng,
    fillColor: Colors.green.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.green,   //원둘레색
    strokeWidth: 1,
  );

  static final Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: companyLatLng,
  );

  static final CameraPosition initialPosition = CameraPosition(
      target: companyLatLng,
      zoom: 15); //우주에서 지구를 바롸봤을때 포지션


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder<String>( //
        future: checkPermission(), //퓨처함수 넣을수 있음, 변화가 있을때, 빌더를 실행해서 다시 그려줌
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if(snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if(snapshot.data == '위치 권한이 허가되었습니다.'){
            return StreamBuilder<Position>(
              stream: Geolocator.getPositionStream(),
              builder: (context, snapshot) {
                bool isWithinRange = false;
                if(snapshot.hasData) { //거리구하는 로직
                  final start = snapshot.data!; //내 위치
                  final end = companyLatLng;
                  final distance = Geolocator.distanceBetween(start.latitude, start.longitude, end.latitude, end.longitude);

                  if(distance < okDistance) {
                    isWithinRange = true;
                  }
                }



                print(snapshot.data);
                return Column(
                  children: [
                    _CustomGoogleMap(
                        initialPosition: initialPosition,
                        circle: choolCheckDone
                            ? chckDoneCircle //choolcheckDone이 true인 경우 checkDoneCircle 리턴
                            : isWithinRange //choolcheckdone이 false인 경우 거리계산
                                ? withinDistanceCircle
                                : notWithinDistanceCircle,
                        marker: marker,
                      onMapCreated: onMapCreated,
                    ),
                    _ChoolCheckButton(
                      choolCheckDone: choolCheckDone,
                      isWithinRange: isWithinRange,
                      onPressed: onChoolCheckPressed,
                    ),
                  ],
                );
              }
            );
          }

          return Center(
            child: Text(snapshot.data),
          );
          print(snapshot.data);
          print(snapshot.connectionState); //none, waiting, active, done

        },
      ),
    );
  }

  onMapCreated(GoogleMapController controller) {
        mapController = controller;

  }

  onChoolCheckPressed() async {
    final result = await showDialog(
        context: context,
        builder:(BuildContext context){
          return AlertDialog(
            title: Text('출근하기'),
            content: Text('출근을 하시겠습니까?'),
            actions: [
              TextButton(onPressed: () {
                Navigator.of(context).pop(false);
              },
                  child: Text('취소')),

              TextButton(onPressed: () {
                Navigator.of(context).pop(true);
              },
                  child: Text('출근하기')),
            ],
          );
      },
    );

    if(result) {
      setState(() {
        choolCheckDone = true;
      });
    }
  }


  Future<String> checkPermission() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if(!isLocationEnabled) {
      return '위치 서비스를 활성화 해주세요';
    }
    LocationPermission checkPermission = await Geolocator.checkPermission(); //denied, denied forever, use, always
    if(checkPermission == LocationPermission.denied) {
      checkPermission = await Geolocator.requestPermission(); //리퀘스트한 값이 저장이됨
      if(checkPermission == LocationPermission.denied) {
        return '위치 권한을 허가해주세요 ';
      }
    }
    if(checkPermission == LocationPermission.deniedForever) {
      return '앱의 위치 권한을 세팅에서 허가해주세요';
    }

    return '위치 권한이 허가되었습니다.';
  }




  AppBar renderAppBar() {
    return  AppBar(
      title: Center(
        child: Text('오늘도 출근',
          style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w700
          ),
        ),
      ),
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          color: Colors.blue,
          onPressed: () async {
            if(mapController == null){
              return;
            }

            final location = await Geolocator.getCurrentPosition();
            mapController!.animateCamera(
                CameraUpdate.newLatLng(
              LatLng(
                location.latitude,
                location.longitude,
              )
            ));
          },
          icon: Icon(Icons.my_location),)
      ],
    );
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;
  final MapCreatedCallback onMapCreated;

  const _CustomGoogleMap({required this.initialPosition,
    required this.circle,required this.marker,required this.onMapCreated,
    Key? key,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return           Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        circles: Set.from([circle]),
        markers: Set.from([marker]),
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  final bool isWithinRange;
  final VoidCallback onPressed;
  final bool choolCheckDone;



  const _ChoolCheckButton({
    required this.isWithinRange,
    required this.onPressed,
    required this.choolCheckDone,
    Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(
            Icons.timelapse_outlined,
            size: 50,
            color: choolCheckDone
                ? Colors.green
                : isWithinRange
                  ? Colors.blue
                  : Colors.red
          ),
          const SizedBox(height: 20.0),
          if(!choolCheckDone && isWithinRange)// if문 바로 아래에 영향 true일 경우 리턴
          TextButton(
              onPressed:onPressed,
          child: Text('출근하기')
          ),
        ],
      )
    );
  }
}
