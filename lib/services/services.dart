//Package imports
import 'package:cloud_firestore/cloud_firestore.dart';

class FireBaseServices {
  static late QuerySnapshot _querySnapshot;
  static final _db = FirebaseFirestore.instance;

  //Function to get Rooms
  static getRooms() async {
    //Looking for rooms with single user
    _querySnapshot = await _db
        .collection('rooms')
        .where('users', isEqualTo: 1)
        .limit(1)
        .get();
    //Looking for empty rooms
    if (_querySnapshot.docs.isEmpty) {
      _querySnapshot = await _db
          .collection('rooms')
          .where('users', isEqualTo: 0)
          .limit(1)
          .get(); 
    } 
    await _db
    .collection('rooms')
    .doc(_querySnapshot.docs[0].id)
    .update({'users': FieldValue.increment(1)});
    return _querySnapshot;
  }

  //Function to leave room basically reducing user count in the room
  static leaveRoom() async {
    await _db
        .collection('rooms')
        .doc(_querySnapshot.docs[0].id)
        .update({'users': FieldValue.increment(-1)});
  }
}
