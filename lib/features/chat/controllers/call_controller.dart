import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import 'package:mess_finder/core/utils/app_logger.dart';
import 'package:mess_finder/core/utils/api_constants.dart';
import 'package:mess_finder/core/services/notification_service.dart';
import 'package:mess_finder/features/auth/controllers/auth_controller.dart';
import 'package:mess_finder/features/notifications/models/app_notification_model.dart';
import 'package:mess_finder/features/chat/controllers/chat_controller.dart';
import 'package:mess_finder/features/chat/views/call_screen.dart';
import 'package:mess_finder/features/chat/views/incoming_call_screen.dart';

enum CallState { idle, outgoing, incoming, connected, ended }

class CallController extends GetxController {
  static CallController get to => Get.find<CallController>();

  // Agora App ID
  String get agoraAppId =>
      dotenv.env['AGORA_APP_ID'] ?? 'c371f9276721413fbe91e6b08b427b6d';

  RtcEngine? _engine;
  RtcEngine? get engine => _engine;

  socket_io.Socket? _socket;

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
  final RxBool isEngineReady = false.obs;

  // Call Logging Tracking
  bool isCaller = false;
  bool _hasLoggedCall = false;

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
    final authCtrl = Get.find<AuthController>();
    ever(authCtrl.currentUser, (user) {
      if (user != null && user.uid.isNotEmpty) {
        if (_socket == null || _socket?.connected != true) {
          _initSocketSignaling();
        }
      } else {
        _socket?.disconnect();
        _socket = null;
      }
    });
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

    final backendUrl = dotenv.env['SOCKET_URL'] ?? ApiConstants.serverBaseUrl;
    _socket = socket_io.io(
      backendUrl,
      socket_io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setQuery({'userId': currentUid})
          .build(),
    );

    _socket?.connect();

    _socket?.onConnect((_) {
      AppLogger.i('Call signaling socket connected for $currentUid', tag: 'CALL_CTRL');
      // Ensure backend routes calls correctly by joining personal user room
      _socket?.emit(ApiConstants.socketJoinUserRoom, currentUid);
    });

    // 1. Incoming Call Listener
    _socket?.on('incoming_call', (data) {
      // Ignore if I am the caller (backend might be broadcasting)
      if (data['callerId'] == currentUid) {
        return;
      }

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

      // Play Incoming Call Ringtone
      _startIncomingRingtone();

      NotificationService().showCallNotification(
        callerName: peerUserName,
        isVideo: isVideoCall.value,
        payload: currentChannel,
      );

      Get.to(
        () => IncomingCallScreen(
          callerName: peerUserName,
          callerPhoto: peerUserPhoto,
          isVideo: isVideoCall.value,
          onAccept: () {
            _stopRingtone();
            NotificationService().cancelCallNotification();
            Get.back(); // close incoming call screen
            acceptCall();
          },
          onDecline: () {
            _stopRingtone();
            NotificationService().cancelCallNotification();
            Get.back(); // close incoming call screen
            rejectCall();
          },
        ),
        transition: Transition.fadeIn,
        routeName: '/IncomingCallScreen',
      );
    });

    // 2. Call Accepted Listener
    _socket?.on('call_accepted', (data) async {
      AppLogger.i('Call accepted by peer', tag: 'CALL_CTRL');
      _stopRingtone();
      _ringingTimeoutTimer?.cancel();
      NotificationService().cancelCallNotification();
      currentRtcToken = data['token'] ?? '';
      callState.value = CallState.connected;
      callStatusText.value = 'Connected';
      _startCallTimer();
      
      // Join channel now that we have the token (if caller)
      if (isCaller && currentRtcToken.isNotEmpty) {
        try {
          await _engine?.joinChannel(
            token: currentRtcToken,
            channelId: currentChannel,
            uid: 0,
            options: ChannelMediaOptions(
              clientRoleType: ClientRoleType.clientRoleBroadcaster,
              channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
              publishCameraTrack: isVideoCall.value,
              publishMicrophoneTrack: true,
              autoSubscribeAudio: true,
              autoSubscribeVideo: isVideoCall.value,
            ),
          );
        } catch (e) {
          AppLogger.e('Caller delayed join channel error: $e', e, null, 'CALL_CTRL');
        }
      }
    });

    // 3. Call Rejected / Busy Listener
    _socket?.on('call_rejected', (data) {
      AppLogger.i('Call rejected by peer: $data', tag: 'CALL_CTRL');
      _stopRingtone();
      _ringingTimeoutTimer?.cancel();
      NotificationService().cancelCallNotification();

      final isBusy = data['reason'] == 'busy';
      callStatusText.value = isBusy ? 'Line Busy' : 'Call Declined';

      if (isCaller) {
        _logCallToChat(status: isBusy ? 'busy' : 'declined');
      }

      endCall(notifyPeer: false);

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
    });

    // 4. Target User Offline Listener
    _socket?.on('call_user_offline', (data) async {
      AppLogger.i('Target user is offline: $data', tag: 'CALL_CTRL');
      _stopRingtone();
      _ringingTimeoutTimer?.cancel();
      callStatusText.value = 'User is Offline';

      if (isCaller) {
        _logCallToChat(status: 'missed');
      }

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

      endCall(notifyPeer: false);

      Get.snackbar(
        'User is Offline',
        '$peerUserName is currently offline. A missed call notification has been sent.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.amber.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    });

    // 5. Call Ended Listener
    _socket?.on('call_ended', (data) {
      AppLogger.i('Call ended by peer', tag: 'CALL_CTRL');
      _stopRingtone();
      _ringingTimeoutTimer?.cancel();
      NotificationService().cancelCallNotification();
      callStatusText.value = 'Call Ended';
      if (callDuration.value > 0) {
        _logCallToChat(status: 'completed', duration: callDuration.value);
      }
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

    isCaller = true;
    _hasLoggedCall = false;
    peerUserId = targetUserId;
    peerUserName = targetUserName;
    peerUserPhoto = targetUserPhoto;
    isVideoCall.value = isVideo;
    currentChannel = 'call_${myUid}_${DateTime.now().millisecondsSinceEpoch}';
    callState.value = CallState.outgoing;
    callStatusText.value = 'Ringing...';

    // Start Outgoing Ringback Sound
    _startOutgoingRingtone();

    // 1. Open Call Screen IMMEDIATELY so transition is smooth & instant
    Get.to(
      () => const CallScreen(),
      routeName: '/CallScreen',
      transition: Transition.fadeIn,
    );

    // 2. Initialize Agora in background without blocking UI thread
    _initAgoraEngine(isVideo, token: currentRtcToken);

    // 30-Second Ringing Timeout
    _ringingTimeoutTimer?.cancel();
    _ringingTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (callState.value == CallState.outgoing) {
        _stopRingtone();
        callStatusText.value = 'No Answer';
        _logCallToChat(status: 'missed');
        // Send missed call notification
        NotificationService().sendAndStore(
          receiverUid: targetUserId,
          title: '📞 Missed Call',
          body: 'Missed ${isVideo ? "video" : "audio"} call from ${myUser?.name ?? "Someone"}.',
          type: NotificationType.call,
          senderUid: myUid,
        );

        endCall(notifyPeer: true);

        Get.snackbar(
          'No Answer',
          '$peerUserName did not answer. A missed call notification has been sent.',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.amber.shade800,
          colorText: Colors.white,
        );
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
    _stopRingtone();
    isCaller = false;
    _hasLoggedCall = false;
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
    Get.to(
      () => const CallScreen(),
      routeName: '/CallScreen',
      transition: Transition.fadeIn,
    );

    // Initialize Agora engine
    _initAgoraEngine(isVideoCall.value, token: currentRtcToken);

    _socket?.emit('accept_call', {
      'callerId': peerUserId,
      'channelName': currentChannel,
    });
  }

  // ── Reject Call (Receiver) ──────────────────────────────────────────
  void rejectCall() {
    _stopRingtone();
    _socket?.emit('reject_call', {'callerId': peerUserId});
    _cleanupCall();
  }

  // ── End Call (Either participant) ──────────────────────────────────
  Future<void> endCall({bool notifyPeer = true}) async {
    _stopRingtone();
    _ringingTimeoutTimer?.cancel();
    if (callDuration.value > 0) {
      _logCallToChat(status: 'completed', duration: callDuration.value);
    } else if (isCaller && !_hasLoggedCall) {
      _logCallToChat(status: 'cancelled');
    }
    if (notifyPeer && peerUserId.isNotEmpty) {
      _socket?.emit('end_call', {'targetUserId': peerUserId});
    }

    final bool wasRingingOrConnected = callState.value != CallState.idle;
    
    _cleanupCall();

    if (wasRingingOrConnected) {
      // Safely close the call screen without relying on fragile route names
      Get.back(); // Pops the CallScreen or IncomingCallScreen
    }
  }

  // ── Agora Engine Setup ───────────────────────────────────────────────
  Future<void> _initAgoraEngine(bool isVideo, {String token = ''}) async {
    try {
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: agoraAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            AppLogger.i('Joined Agora channel: ${connection.channelId}', tag: 'CALL_CTRL');
          },
          onUserJoined: (RtcConnection connection, int uid, int elapsed) {
            AppLogger.i('Remote user joined: $uid', tag: 'CALL_CTRL');
            _stopRingtone();
            remoteUid.value = uid;
            callState.value = CallState.connected;
            callStatusText.value = 'Connected';
            _startCallTimer();
          },
          onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
            AppLogger.i('Remote user offline: $uid', tag: 'CALL_CTRL');
            _stopRingtone();
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
        try {
          await _engine!.enableVideo();
          await _engine!.startPreview();
        } catch (videoError) {
          AppLogger.w('Failed to enable video/preview: $videoError', tag: 'CALL_CTRL');
        }
      }

      // Join channel only if we have a token (Caller will join later on call_accepted)
      if (token.isNotEmpty) {
        await _engine!.joinChannel(
          token: token,
          channelId: currentChannel,
          uid: 0,
          options: ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
            publishCameraTrack: isVideo,
            publishMicrophoneTrack: true,
            autoSubscribeAudio: true,
            autoSubscribeVideo: isVideo,
          ),
        );
      }

      // Set speakerphone safely
      try {
        await _engine!.setEnableSpeakerphone(isSpeakerOn.value);
      } catch (speakerError) {
        AppLogger.w('Speakerphone routing notice: $speakerError', tag: 'CALL_CTRL');
      }

      isEngineReady.value = true;
    } catch (e) {
      isEngineReady.value = false;
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

  // ── Ringtone Sounds Helpers ─────────────────────────────────────────
  void _startOutgoingRingtone() {
    try {
      FlutterRingtonePlayer().play(
        android: AndroidSounds.notification,
        ios: IosSounds.glass,
        looping: true,
        volume: 0.3, // Lower volume for outgoing beep
      );
    } catch (e) {
      AppLogger.w('Outgoing ringtone notice: $e', tag: 'CALL_CTRL');
    }
  }

  void _startIncomingRingtone() {
    try {
      FlutterRingtonePlayer().playRingtone(
        looping: true,
        volume: 1.0,
      );
    } catch (e) {
      AppLogger.w('Incoming ringtone notice: $e', tag: 'CALL_CTRL');
    }
  }

  void _stopRingtone() {
    try {
      FlutterRingtonePlayer().stop();
    } catch (e) {
      AppLogger.w('Stop ringtone notice: $e', tag: 'CALL_CTRL');
    }
  }

  void _cleanupCall() {
    _stopRingtone();
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
    isEngineReady.value = false;
    callState.value = CallState.idle;
    callStatusText.value = 'Calling...';
    
    currentRtcToken = '';
    currentChannel = '';
    peerUserId = '';
    peerUserName = '';
    peerUserPhoto = null;

    NotificationService().cancelCallNotification();

    final oldEngine = _engine;
    _engine = null;
    
    if (oldEngine != null) {
      Future.microtask(() async {
        try {
          await oldEngine.leaveChannel();
          await oldEngine.release();
        } catch (e) {
          AppLogger.w('Agora cleanup warning: $e', tag: 'CALL_CTRL');
        }
      });
    }
  }

  void _logCallToChat({required String status, int duration = 0}) {
    if (_hasLoggedCall || peerUserId.isEmpty) return;
    _hasLoggedCall = true;

    final isVideo = isVideoCall.value;
    final callType = isVideo ? 'video' : 'audio';
    final dur = duration > 0 ? duration : callDuration.value;
    final logText = '[CALL_LOG:$callType:$status:$dur]';

    final targetUid = peerUserId;
    final targetName = peerUserName;
    final targetPhoto = peerUserPhoto;

    try {
      if (Get.isRegistered<ChatController>()) {
        final chatCtrl = Get.find<ChatController>();
        chatCtrl.createOrGetChatRoom(targetUid, targetName, targetPhoto).then((chatId) {
          chatCtrl.sendMessage(chatId, logText, targetUid);
        }).catchError((e) {
          AppLogger.w('Failed to log call message: $e', tag: 'CALL_CTRL');
        });
      } else {
        final chatCtrl = Get.put(ChatController());
        chatCtrl.createOrGetChatRoom(targetUid, targetName, targetPhoto).then((chatId) {
          chatCtrl.sendMessage(chatId, logText, targetUid);
        }).catchError((e) {
          AppLogger.w('Failed to log call message: $e', tag: 'CALL_CTRL');
        });
      }
    } catch (e) {
      AppLogger.w('Log call to chat error: $e', tag: 'CALL_CTRL');
    }
  }
}
