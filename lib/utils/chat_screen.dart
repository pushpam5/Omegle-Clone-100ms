//Package imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

//Project imports
import 'package:omegle_100ms/model/data_store.dart';
import 'package:omegle_100ms/services/hms_sdk_intializer.dart';
import 'package:omegle_100ms/model/message.dart';

class ChatScreen extends StatefulWidget {
  final String peerId;
  const ChatScreen({Key? key, this.peerId = ""}) : super(key: key);
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollDown() {
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(seconds: 1),
        curve: Curves.fastOutSlowIn,
      );
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _scrollDown();
    List<Message> _messages =
        Provider.of<UserDataStore>(context, listen: true).messages;
        Provider.of<UserDataStore>(context, listen: true).isNewMessage = false;

    return SingleChildScrollView(
      child: Container(
        // ignore: prefer_const_constructors
        padding: EdgeInsets.only(
            left: 10,
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 10),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
              topLeft:  Radius.circular(40.0),
              topRight: Radius.circular(40.0)),
          color: Colors.white,
        ),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 2 - 100,
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _messages.length,
                shrinkWrap: true,
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.only(
                        left: 14, right: 14, top: 10, bottom: 10),
                    child: Align(
                      alignment: (_messages[index].peerId == widget.peerId
                          ? Alignment.topLeft
                          : Alignment.topRight),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: (_messages[index].peerId == widget.peerId
                              ? Colors.green.shade200
                              : Colors.blue[200]),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Text(_messages[index].message,
                            style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 5),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: const InputDecoration(
                          hintText: "Write message...",
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      if(messageController.text.trim().isNotEmpty){
                        SdkInitializer.hmssdk.sendBroadcastMessage(
                          message: messageController.text);
                      setState(() {
                        _messages.add(Message(
                            message: messageController.text.trim(),
                            peerId: "localUser"));
                      });
                      _scrollDown();
                      messageController.text = "";
                      }
                      
                    },
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 18,
                    ),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
