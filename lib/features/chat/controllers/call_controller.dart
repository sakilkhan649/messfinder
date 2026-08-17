import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:mess_finder/core/utils/app_logger.dart';
import 'package:mess_finder/core/services/notification_service.dart';
import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';
import 'package:mess_finder/features/chat/views/call_screen.dart';
import 'package:mess_finder/features/chat/views/widgets/incoming_call_dialog.dart';

enum CallState { idle, outgoing, incoming, connected, ended }

class CallController extends GetxController {
  static CallController get to => Get.find<CallController>();

  // Agora App ID
  String get agoraAppId =>
      dotenv.env['AGORA_APP_ID'] ?? 'c371f9276721413fbe91e6b08b427b6d';

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  IO.Socket? _socket;

  // Call States
  final Rx<CallState> callState = CallState.idle.obs;
  final RxString callStatusText = 'Calling...'.obs;
  final RxBool isVideoCall = false.obs;
  final RxBool isMuted = false.obs;
  final RxBool isVideoDisabled = false.obs;
  final RxBool isSpeakerOn = true.obs;
  final RxBool isFrontCamera = true.obs;
  final RxInt remoteUid = 0.obs;
  final RxInt callDuration = 0.obs;

  // Participant Info
  String currentChannel = '';
  String currentRtcToken = '';
  String peerUserId = '';
  String peerUserName = '';
  String? peerUserPhoto;

  Timer? _timer;
  Timer? _ringingTimeoutTimer;

  @override
  void onInit() {
    super.onInit();
    _initSocketSignaling();
  }

  @override
  void onClose() {
    _cleanupCall();
    super.onClose();
  }

  void _initSocketSignaling() {
    final authCtrl = Get.find<AuthController>();
    final currentUid = authCtrl.currentUser.value?.uid;
    if (currentUid == null || currentUid.isEmpty) return;

    final backendUrl = dotenv.env['SOCKET_URL'] ?? 'http://10.0.2.2:5000';
    _socket = IO.io(
      backendUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'userId': currentUid})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      AppLogger.i('Call signaling socket connected for $currentUid', tag: 'CALL_CTRL');
    });

    // 1. Incoming Call Listener
    _socket?.on('incoming_call', (data) {
      if (callState.value != CallState.idle) {
        // User is currently busy on another active call!
        _socket?.emit('reject_call', {
          'callerId': data['callerId'],
          'reason': 'busy',
        });

        // Store a missed call notification for the busy user
        final callerName = data['callerName'] ?? 'Someone';
        final authCtrl = Get.find<AuthController>();
        final myUid = authCtrl.currentUser.value?.uid ?? '';
        NotificationService().storeNotification(AppNotificationModel(
          id: '',
          title: '📞 Missed Call (Busy)',
          body: 'Missed call from $callerName while you were on another call.',
          type: NotificationType.call,
          receiverUid: myUid,
          senderUid: data['callerId'],
          createdAt: DateTime.now(),
        ));
        return;
      }

      currentChannel = data['channelName'] ?? '';
      currentRtcToken = data['token'] ?? '';
      peerUserId = data['callerId'] ?? '';
      peerUserName = data['callerName'] ?? 'Unknown User';
      peerUserPhoto = data['callerPhoto'];
      isVideoCall.value = data['isVideo'] == true;
      callState.value = CallState.incoming;
      callStatusText.value = 'Incoming Call...';

      NotificationService().showCallNotification(
        callerName: peerUserName,
        isVideo: isVideoCall.value,
        payload: currentChannel,
      );

      Get.dialog(
        IncomingCallDialog(
          callerName: peerUserName,
          callerPhoto: peerUserPhoto,
          isVideo: isVideoCall.value,
          onAccept: () {
            NotificationService().cancelCallNotification();
            Get.back();
            acceptCall();
          },
          onDecline: () {
            NotificationService().cancelCallNotification();
            Get.back();
            rejectCall();
          },
        ),
        barrierDismissible: false,
      );
    });

    // 2. Call Accepted Listener
    _socket?.on('call_accepted', (data) async {
      AppLogger.i('Call accepted by peer', tag: 'CALL_CTRL');
      _ringingTimeoutTimer?.cancel();
      NotificationService().cancelCallNotification();
      currentRtcToken = data['token'] ?? '';
      callState.value = CallState.connected;
      callStatusText.value = 'Connected';
      _startCallTimer();
    });

    // 3. Call Rejected / Busy Listener
    _socket?.on('call_rejected', (data) {
      AppLogger.i('Call rejected by peer: $data', tag: 'CALL_CTRL');
      _ringingTimeoutTimer?.cancel();
      NotificationService().cancelCallNotification();

      final isBusy = data['reason'] == 'busy';
      callStatusText.value = isBusy ? 'Line Busy' : 'Call Declined';

      Get.snackbar(
        isBusy ? 'Line Busy' : 'Call Declined',
        isBusy
            ? '$peerUserName is currently on another call.'
            : '$peerUserName is unavailable or declined the call.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: isBusy ? Colors.amber.shade800 : Colors.red.shade700,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      Future.delayed(const Duration(seconds: 2), () {
        endCall();
      });
    });

    // 4. Target User Offline Listener
    _socket?.on('call_user_offline', (data) async {
      AppLogger.i('Target user is offline: $data', tag: 'CALL_CTRL');
      _ringingTimeoutTimer?.cancel();
      callStatusText.value = 'User is Offline';

      final authCtrl = Get.find<AuthController>();
      final myUser = authCtrl.currentUser.value;

      // Send & store Missed Call push notification in Firestore
      if (peerUserId.isNotEmpty) {
        NotificationService().sendAndStore(
          receiverUid: peerUserId,
          title: '📞 Missed Call',
          body: '${myUser?.name ?? "Someone"} tried to call you.',
          type: NotificationType.call,
          senderUid: myUser?.uid,
        );
      }

      Get.snackbar(
        'User is Offline',
        '$peerUserName is currently offline. A missed call notification has been sent.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.amber.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      Future.delayed(const Duration(seconds: 3), () {
        endCall();
      });
    });

    // 5. Call Ended Listener
    _socket?.on('call_ended', (data) {
      AppLogger.i('Call ended by peer', tag: 'CALL_CTRL');
      _ringingTimeoutTimer?.cancel();
      NotificationService().cancelCallNotification();
      callStatusText.value = 'Call Ended';
      endCall(notifyPeer: false);
    });
  }

  // ── Make Call (Caller) ───────────────────────────────────────────────
  Future<void> makeCall({
    required String targetUserId,
    required String targetUserName,
    String? targetUserPhoto,
    required bool isVideo,
  }) async {
    final micGranted = await Permission.microphone.request().isGranted;
    if (!micGranted) {
      Get.snackbar('Permission Required', 'Microphone permission is needed to make calls.');
      return;
    }

    if (isVideo) {
      final camGranted = await Permission.camera.request().isGranted;
      if (!camGranted) {
        Get.snackbar('Permission Required', 'Camera permission is needed for video calls.');
        return;
      }
    }

    final authCtrl = Get.find<AuthController>();
    final myUser = authCtrl.currentUser.value;
    final myUid = myUser?.uid ?? '';

    peerUserId = targetUserId;
    peerUserName = targetUserName;
    peerUserPhoto = targetUserPhoto;
    isVideoCall.value = isVideo;
    currentChannel = 'call_${myUid}_${DateTime.now().millisecondsSinceEpoch}';
    callState.value = CallState.outgoing;
    callStatusText.value = 'Ringing...';

    // 1. Open Call Screen IMMEDIATELY so transition is smooth & instant
    Get.to(() => const CallScreen());

    // 2. Initialize Agora in background without blocking UI thread
    _initAgoraEngine(isVideo, token: currentRtcToken);

    // 30-Second Ringing Timeout
    _ringingTimeoutTimer?.cancel();
    _ringingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (callState.value == CallState.outgoing) {
        callStatusText.value = 'No Answer';
        // Send missed call notification
        NotificationService().sendAndStore(
          receiverUid: targetUserId,
          title: '📞 Missed Call',
          body: 'Missed ${isVideo ? "video" : "audio"} call from ${myUser?.name ?? "Someone"}.',
          type: NotificationType.call,
          senderUid: myUid,
        );

        Get.snackbar(
          'No Answer',
          '$peerUserName did not answer. A missed call notification has been sent.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
        );

        Future.delayed(const Duration(seconds: 2), () {
          endCall();
        });
      }
    });

    // Send Push Notification
    NotificationService().sendPush(
      receiverUid: targetUserId,
      title: isVideo ? '📹 Incoming Video Call' : '📞 Incoming Audio Call',
      body: '${myUser?.name ?? "User"} is calling you...',
      type: 'call',
      relatedId: currentChannel,
    );

    // Emit Signal to Server
    _socket?.emit('make_call', {
      'targetUserId': targetUserId,
      'channelName': currentChannel,
      'isVideo': isVideo,
      'callerId': myUid,
      'callerName': myUser?.name ?? 'User',
      'callerPhoto': null,
    });
  }

  // ── Accept Call (Receiver) ──────────────────────────────────────────
  Future<void> acceptCall() async {
    final micGranted = await Permission.microphone.request().isGranted;
    if (!micGranted) {
      Get.snackbar('Permission Required', 'Microphone permission is required.');
      return;
    }

    if (isVideoCall.value) {
      final camGranted = await Permission.camera.request().isGranted;
      if (!camGranted) {
        Get.snackbar('Permission Required', 'Camera permission is required.');
        return;
      }
    }

    callState.value = CallState.connected;
    callStatusText.value = 'Connected';
    _startCallTimer();

    // Open screen immediately
    Get.to(() => const CallScreen());

    // Initialize Agora engine
    _initAgoraEngine(isVideoCall.value, token: currentRtcToken);

    _socket?.emit('accept_call', {
      'callerId': peerUserId,
      'channelName': currentChannel,
    });
  }

  // ── Reject Call (Receiver) ──────────────────────────────────────────
  void rejectCall() {
    _socket?.emit('reject_call', {'callerId': peerUserId});
    _cleanupCall();
  }

  // ── End Call (Either participant) ──────────────────────────────────
  Future<void> endCall({bool notifyPeer = true}) async {
    _ringingTimeoutTimer?.cancel();
    if (notifyPeer && peerUserId.isNotEmpty) {
      _socket?.emit('end_call', {'targetUserId': peerUserId});
    }

    _cleanupCall();

    if (Get.currentRoute == '/CallScreen' || Get.isDialogOpen == true) {
      Get.back();
    }
  }

  // ── Agora Engine Setup ───────────────────────────────────────────────
  Future<void> _initAgoraEngine(bool isVideo, {String token = ''}) async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            AppLogger.i('Joined Agora channel: ${connection.channelId}', tag: 'CALL_CTRL');
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            AppLogger.i('Remote user joined: $uid', tag: 'CALL_CTRL');
            remoteUid.value = uid;
            callState.value = CallState.connected;
            callStatusText.value = 'Connected';
            _startCallTimer();
          },
          onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
            AppLogger.i('Remote user offline: $uid', tag: 'CALL_CTRL');
            endCall(notifyPeer: false);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            AppLogger.i('Left Agora channel', tag: 'CALL_CTRL');
          },
        ),
      );

      // Always enable audio
      await _engine!.enableAudio();

      if (isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      }

      // Join channel
      await _engine!.joinChannel(
        token: token,
        channelId: currentChannel,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
          publishCameraTrack: isVideo,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideo,
        ),
      );

      // Set speakerphone safely
      try {
        await _engine!.setEnableSpeakerphone(isSpeakerOn.value);
      } catch (speakerError) {
        AppLogger.w('Speakerphone routing notice: $speakerError', tag: 'CALL_CTRL');
      }
    } catch (e) {
      AppLogger.e('Error initializing Agora Engine: $e', e, null, 'CALL_CTRL');
    }
  }

  // ── Call Controls ────────────────────────────────────────────────────
  void toggleMute() {
    isMuted.value = !isMuted.value;
    try {
      _engine?.muteLocalAudioStream(isMuted.value);
    } catch (e) {
      AppLogger.w('toggleMute notice: $e', tag: 'CALL_CTRL');
    }
  }

  void toggleVideo() {
    isVideoDisabled.value = !isVideoDisabled.value;
    try {
      _engine?.muteLocalVideoStream(isVideoDisabled.value);
    } catch (e) {
      AppLogger.w('toggleVideo notice: $e', tag: 'CALL_CTRL');
    }
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    try {
      _engine?.setEnableSpeakerphone(isSpeakerOn.value);
    } catch (e) {
      AppLogger.w('toggleSpeaker notice: $e', tag: 'CALL_CTRL');
    }
  }

  void switchCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    try {
      _engine?.switchCamera();
    } catch (e) {
      AppLogger.w('switchCamera notice: $e', tag: 'CALL_CTRL');
    }
  }

  void _startCallTimer() {
    _timer?.cancel();
    callDuration.value = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      callDuration.value++;
    });
  }

  void _cleanupCall() {
    _ringingTimeoutTimer?.cancel();
    _ringingTimeoutTimer = null;
    _timer?.cancel();
    _timer = null;
    callDuration.value = 0;
    remoteUid.value = 0;
    isMuted.value = false;
    isVideoDisabled.value = false;
    isSpeakerOn.value = true;
    isFrontCamera.value = true;
    callState.value = CallState.idle;
    callStatusText.value = 'Calling...';

    NotificationService().cancelCallNotification();

    try {
      _engine?.leaveChannel();
      _engine?.release();
    } catch (_) {}
    _engine = null;
  }
}
