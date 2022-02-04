//dart imports
import 'dart:convert';

//Package imports
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:http/http.dart' as http;

//Project imports
import 'package:omegle_100ms/services/services.dart';

//Class to handle Join Room Service
class JoinService {

  //Function to get roomId stored in Firebase
  static Future<String> getRoom() async {
    QuerySnapshot? _result;
    await FireBaseServices.getRooms().then((data) {
      _result = data;
    });
    return _result?.docs[0].get('roomId');
  }

  //Function to join the room
  static Future<bool> join(HMSSDK hmssdk) async {
    String roomUrl = await getRoom();
    Uri endPoint = Uri.parse("https://prod-in.100ms.live/hmsapi/decoder.app.100ms.live/api/token");
    http.Response response = await http.post(endPoint, body: {
      'user_id': "user",
      'room_id':roomUrl,
      'role':"host"
    });
    var body = json.decode(response.body);
    if (body == null || body['token'] == null) {
      return false;
    }
    //We use the token from above response to create the HMSConfig Object which
    //we need to pass in the join method of hmssdk
    HMSConfig config = HMSConfig(authToken: body['token'], userName: "user");
    await hmssdk.join(config: config);
    return true;
  }

}
