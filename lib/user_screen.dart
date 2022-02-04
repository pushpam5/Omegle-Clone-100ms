//Package imports
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:omegle_100ms/utils/no_peer_screen.dart';
import 'package:provider/provider.dart';

//Project imports
import 'package:omegle_100ms/utils/chat_screen.dart';
import 'package:omegle_100ms/utils/circle_painter.dart';
import 'package:omegle_100ms/model/data_store.dart';
import 'package:omegle_100ms/services/hms_sdk_intializer.dart';
import 'package:omegle_100ms/services/join_service.dart';
import 'package:omegle_100ms/utils/loading_screen.dart';
import 'package:omegle_100ms/services/services.dart';

class UserScreen extends StatefulWidget {
  const UserScreen({Key? key}) : super(key: key);
  @override
  _UserScreenState createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen>
    with SingleTickerProviderStateMixin {
  //To keep Track of local tracks
  bool isLocalAudioOn = true;
  bool isLocalVideoOn = true;
  double waveRadius = 0.0;
  double waveGap = 10.0;
  late Animation<double> _animation;
  late AnimationController controller;
  bool _isLoading = false;
  Offset position = Offset(10, 10);

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    controller.forward();
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.reset();
      } else if (status == AnimationStatus.dismissed) {
        controller.forward();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<bool> leaveRoom() async {
    SdkInitializer.hmssdk.leave();
    FireBaseServices.leaveRoom();
    Navigator.pop(context);
    return false;
  }

  Future<void> switchRoom() async {
    setState(() {
      _isLoading = true;
    });
    isLocalAudioOn = true;
    isLocalVideoOn = true;

    SdkInitializer.hmssdk.leave();
    FireBaseServices.leaveRoom();
    bool roomJoinSuccessful = await JoinService.join(SdkInitializer.hmssdk);
    if (!roomJoinSuccessful) {
      Navigator.pop(context);
    }
    setState(() {
      _isLoading = false;
    });
  }

  bool _isMoved = false;
  @override
  Widget build(BuildContext context) {
    _animation = Tween(begin: 60.0, end: waveGap).animate(controller)
      ..addListener(() {
        setState(() {
          waveRadius = _animation.value;
        });
      });

    final _isVideoOff = context.select<UserDataStore, bool>(
        (user) => user.remoteVideoTrack?.isMute ?? true);
    final _isAudioOff = context.select<UserDataStore, bool>(
        (user) => user.remoteAudioTrack?.isMute ?? true);
    final _peer =
        context.select<UserDataStore, HMSPeer?>((user) => user.remotePeer);
    final remoteTrack = context
        .select<UserDataStore, HMSTrack?>((user) => user.remoteVideoTrack);
    final localTrack = context
        .select<UserDataStore, HMSVideoTrack?>((user) => user.localTrack);
    bool isNewMessage =
        context.select<UserDataStore, bool>((user) => user.isNewMessage);

    return WillPopScope(
      onWillPop: () async {
        return leaveRoom();
      },
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: (_isLoading)
              ? const LoadingScreen()
              : (_peer == null)
                  ? const NoPeerScreen()
                  : SizedBox(
                      height: MediaQuery.of(context).size.height,
                      width: MediaQuery.of(context).size.width,
                      child: Stack(
                        children: [
                          Container(
                              color: Colors.black.withOpacity(0.9),
                              child: _isVideoOff
                                  ? Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.blue.withAlpha(60),
                                                blurRadius: 10.0,
                                                spreadRadius: 2.0,
                                              ),
                                            ]),
                                        child: CustomPaint(
                                          size: const Size(150, 150),
                                          painter: CircleWavePainter(
                                              waveRadius, _isAudioOff),
                                        ),
                                      ),
                                    )
                                  : (remoteTrack != null)
                                      ? HMSVideoView(
                                          track: remoteTrack as HMSVideoTrack,
                                          matchParent: false)
                                      : const Center(child: Text("No Video"))),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 15),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () => {
                                      SdkInitializer.hmssdk
                                          .switchAudio(isOn: isLocalAudioOn),
                                      setState(() {
                                        isLocalAudioOn = !isLocalAudioOn;
                                      })
                                    },
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor:
                                          Colors.transparent.withOpacity(0.2),
                                      child: Icon(
                                        isLocalAudioOn
                                            ? Icons.mic
                                            : Icons.mic_off,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () async {
                                      switchRoom();
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withAlpha(60),
                                              blurRadius: 3.0,
                                              spreadRadius: 5.0,
                                            ),
                                          ]),
                                      child: const CircleAvatar(
                                        radius: 35,
                                        backgroundColor: Colors.red,
                                        child: Icon(Icons.refresh,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => {
                                      SdkInitializer.hmssdk
                                          .switchVideo(isOn: isLocalVideoOn),
                                      if (!isLocalVideoOn)
                                        SdkInitializer.hmssdk.startCapturing()
                                      else
                                        SdkInitializer.hmssdk.stopCapturing(),
                                      setState(() {
                                        isLocalVideoOn = !isLocalVideoOn;
                                      })
                                    },
                                    child: CircleAvatar(
                                      radius: 25,
                                      backgroundColor:
                                          Colors.transparent.withOpacity(0.2),
                                      child: Icon(
                                        isLocalVideoOn
                                            ? Icons.videocam
                                            : Icons.videocam_off_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _isVideoOff
                              ? const Align(
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.videocam_off,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                )
                              : Container(),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: GestureDetector(
                              onTap: () {
                                leaveRoom();
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: () {
                                if (isLocalVideoOn) {
                                  SdkInitializer.hmssdk.switchCamera();
                                }
                              },
                              child: CircleAvatar(
                                radius: 25,
                                backgroundColor:
                                    Colors.transparent.withOpacity(0.2),
                                child: const Icon(
                                  Icons.switch_camera_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 80,
                            right: 10,
                            child: GestureDetector(
                              onTap: () async {
                                isNewMessage = false;
                                showModalBottomSheet(
                                    isScrollControlled: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30.0),
                                    ),
                                    context: context,
                                    builder: (_) => ListenableProvider.value(
                                          value: Provider.of<UserDataStore>(
                                              context,
                                              listen: true),
                                          child: ChatScreen(
                                            peerId: _peer.peerId,
                                          ),
                                        ));
                              },
                              child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor:
                                      Colors.transparent.withOpacity(0.2),
                                  child: Stack(
                                    children: [
                                      const Align(
                                        alignment: Alignment.center,
                                        child: Icon(
                                          Icons.chat,
                                          color: Colors.white,
                                        ),
                                      ),
                                      isNewMessage
                                          ? const Positioned(
                                              right: 8,
                                              top: 8,
                                              child: Icon(
                                                Icons.circle,
                                                size: 12,
                                                color: Colors.blue,
                                              ),
                                            )
                                          : Container()
                                    ],
                                  )),
                            ),
                          ),
                          Positioned(
                            left: position.dx,
                            top: position.dy,
                            child: Draggable<bool>(
                              data: true,
                              childWhenDragging: Container(),
                              child: localPeerTile(localTrack),
                              onDragEnd: (details) =>
                                  {setState(() => position = details.offset)},
                              feedback: Container(
                                height: 200,
                                width: 150,
                                color: Colors.black,
                                child: Icon(
                                  Icons.videocam_off_rounded,
                                  color: Colors.white,
                                ),
                              )
                            ),
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget localPeerTile(HMSVideoTrack? localTrack) {
    return Container(
      height: 200,
      width: 150,
      color: Colors.black,
      child: (isLocalVideoOn && localTrack != null)
          ? HMSVideoView(
              track: localTrack,
            )
          : const Icon(
              Icons.videocam_off_rounded,
              color: Colors.white,
            ),
    );
  }
}
