import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //latitude, longitude

  static final LatLng companyLatLng = LatLng(
    37.5233273,
    126.921252,
  );
  static final CameraPosition initialPosition = CameraPosition(
      target: companyLatLng,
      zoom: 15); //우주에서 지구를 바롸봤을때 포지션


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder( //
        future: checkPermission(), //퓨처함수 넣을수 있음, 변화가 있을때, 빌더를 실행해서 다시 그려줌
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if(snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if(snapshot.data == '위치 권한이 허가되었습니다.'){
            return Column(
              children: [
                _CustomGoogleMap(initialPosition: initialPosition),
                _ChoolCheckButton(),
              ],
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
    );
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;

  const _CustomGoogleMap({required this.initialPosition,Key? key,})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return           Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialPosition,
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  const _ChoolCheckButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Expanded(
      child: Text(
          '출근'
      ),
    );
  }
}
