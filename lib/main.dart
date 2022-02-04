//dart imports
import 'dart:io';

//Package imports
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

//Project imports
import 'package:omegle_100ms/model/data_store.dart';
import 'package:omegle_100ms/services/hms_sdk_intializer.dart';
import 'package:omegle_100ms/services/join_service.dart';
import 'package:omegle_100ms/user_screen.dart';

void main() async {
  HttpOverrides.global = MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late UserDataStore _dataStore;
  bool _isLoading = false;
  @override
  void initState() {
    SdkInitializer.hmssdk.build();
    getPermissions();
    super.initState();
  }

  void getPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    while ((await Permission.camera.isDenied)) {
      await Permission.camera.request();
    }
    while ((await Permission.microphone.isDenied)) {
      await Permission.microphone.request();
    }
  }

  //Handles room joining functionality
  Future<bool> joinRoom() async {
    setState(() {
      _isLoading = true;
    });
    //The join method initialize sdk,gets auth token,creates HMSConfig and helps in joining the room 
    bool isJoinSuccessful = await JoinService.join(SdkInitializer.hmssdk);
    if (!isJoinSuccessful) {
      return false;
    }
    _dataStore = UserDataStore();
    //Here we are attaching a listener to our DataStoreClass 
    _dataStore.startListen();
    setState(() {
      _isLoading = false;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Container(
        color: Colors.black.withOpacity(0.9),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 50.0),
                child: Text(
                  "Let's\nMeet in \n100ms",
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 60),
                ),
              ),
              _isLoading?
              const CircularProgressIndicator(strokeWidth: 3,color: Colors.blueAccent,)
              :ElevatedButton(
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 15),
                    textStyle: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    elevation: 10,
                    shadowColor: Colors.blue.shade900,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text("Join  "),
                    Icon(Icons.arrow_right_alt_outlined),
                  ],
                ),
                onPressed: () async {
                  bool isJoined = await joinRoom();
                  if (isJoined) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ListenableProvider.value(value: _dataStore,child: const UserScreen())));
                  } else {
                    const SnackBar(content: Text("Error"));
                  }
                },
              )
            ],
          ),
        ),
      )),
    );
  }
}

 class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
