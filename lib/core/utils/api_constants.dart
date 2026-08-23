class ApiConstants {
  // ─── Base URLs ───────────────────────────────────────────────────────────
  // Server Host & API Base (Change to 'http://10.0.2.2:5000' if you want to test on local emulator)
  static const String serverBaseUrl = 'https://messfinder-backend-production.up.railway.app';
  static const String apiBaseUrl = '$serverBaseUrl/api';
  static const String baseUrl = apiBaseUrl; // Backward-compatible alias

  // External Microservices & Gateways
  static const String vercelBackendUrl = 'https://vercelbackend-ruby.vercel.app';
  static const String osmGeocodingUrl = 'https://nominatim.openstreetmap.org';

  // ─── Timeout Durations ───────────────────────────────────────────────────
  static const int connectionTimeout = 60; // 60 seconds
  static const int receiveTimeout = 60;

  // ─── Authentication Endpoints (/api/auth) ────────────────────────────────
  static const String authSignup = '/auth/signup';
  static const String authLogin = '/auth/login';
  static const String authGoogleLogin = '/auth/google-login';
  static const String authRefreshToken = '/auth/refresh-token';
  static const String authProfile = '/auth/profile';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authSendResetOtp = '/auth/send-reset-otp';
  static const String authVerifyResetOtp = '/auth/verify-reset-otp';
  static const String authResetPasswordWithOtp = '/auth/reset-password-with-otp';
  static const String authUpdateFcmToken = '/auth/fcm-token';
  static const String authChangePassword = '/auth/change-password';
  static const String authDeleteAccount = '/auth/profile';

  // Dynamic Auth Route Helper
  static String authUserById(String uid) => '/auth/user/$uid';

  // Backward compatibility
  static const String loginEndpoint = authLogin;
  static const String registerEndpoint = authSignup;

  // ─── Post & Mess Endpoints (/api/posts) ──────────────────────────────────
  static const String posts = '/posts';
  static const String myPosts = '/posts/user/my-posts';

  // Dynamic Post Route Helpers
  static String postById(String id) => '/posts/$id';
  static String postAvailability(String id) => '/posts/$id/availability';

  // ─── Marketplace Endpoints (/api/products) ───────────────────────────────
  static const String products = '/products';
  
  // Dynamic Product Route Helpers
  static String productById(String id) => '/products/$id';
  static String userProducts(String uid) => '/products/user/$uid';

  // ─── Chat Endpoints (/api/chats) ─────────────────────────────────────────
  static const String chats = '/chats';

  // Dynamic Chat Route Helpers
  static String chatMessages(String chatId) => '/chats/$chatId/messages';
  static String chatMessageItem(String chatId, String messageId) =>
      '/chats/$chatId/messages/$messageId';
  static String chatMessageReact(String chatId, String messageId) =>
      '/chats/$chatId/messages/$messageId/react';

  // ─── File Upload Endpoints (/api/upload) ─────────────────────────────────
  static const String upload = '/upload';
  static const String uploadMultiple = '/upload/multiple';
  static const String staticUploads = '/uploads';

  // Dynamic Static File URL Helper
  static String getStaticFileUrl(String filename) =>
      '$serverBaseUrl/uploads/$filename';

  // ─── Admin Endpoints (/api/admin) ────────────────────────────────────────
  static const String adminStats = '/admin/stats';
  static const String adminUsers = '/admin/users';
  static const String adminPosts = '/admin/posts';
  static const String adminBookings = '/admin/bookings';
  static const String adminPayments = '/admin/payments';
  static const String adminBroadcast = '/admin/broadcast';

  // Dynamic Admin Route Helpers
  static String adminUserDelete(String uid) => '/admin/users/$uid';
  static String adminUserRole(String uid) => '/admin/users/$uid/role';
  static String adminUserStatus(String uid) => '/admin/users/$uid/status';

  static String adminPostApprove(String postId) => '/admin/posts/$postId/approve';
  static String adminPostReject(String postId) => '/admin/posts/$postId/reject';
  static String adminPostDelete(String postId) => '/admin/posts/$postId';

  static String adminBookingApprove(String bookingId) => '/admin/bookings/$bookingId/approve';
  static String adminBookingReject(String bookingId) => '/admin/bookings/$bookingId/reject';
  static String adminBookingDelete(String bookingId) => '/admin/bookings/$bookingId';

  // ─── Custom Bookings Endpoints (/api/bookings) ───────────────────────────
  static const String bookings = '/bookings';
  static String landlordLeads(String uid) => '/bookings/landlord/$uid';
  static String postLeads(String postId) => '/bookings/post/$postId';
  static String bookingApprove(String bookingId) => '/bookings/$bookingId/approve';
  static String bookingReject(String bookingId) => '/bookings/$bookingId/reject';
  static String bookingDelete(String bookingId) => '/bookings/$bookingId';

  // ─── Push Notification Endpoints (Main Backend) ─────────────────────────
  static const String sendPushNotification = '/notifications/send';
  static const String sendPushNotificationUrl = '$apiBaseUrl/notifications/send';

  // ─── Socket.IO Events ────────────────────────────────────────────────────
  // Rooms & Connection
  static const String socketJoinChat = 'join_chat';
  static const String socketJoinUserRoom = 'join_user_room';

  // Messages & Reactions
  static const String socketSendMessage = 'send_message';
  static const String socketReceiveMessage = 'receive_message';
  static const String socketReactMessage = 'react_message';
  static const String socketMessageReacted = 'message_reacted';
  static const String socketEditMessage = 'edit_message';
  static const String socketMessageEdited = 'message_edited';
  static const String socketDeleteMessage = 'delete_message';
  static const String socketMessageDeleted = 'message_deleted';

  // Audio / Video Call Signaling
  static const String socketMakeCall = 'make_call';
  static const String socketIncomingCall = 'incoming_call';
  static const String socketAcceptCall = 'accept_call';
  static const String socketCallAccepted = 'call_accepted';
  static const String socketRejectCall = 'reject_call';
  static const String socketCallRejected = 'call_rejected';
  static const String socketEndCall = 'end_call';
  static const String socketCallEnded = 'call_ended';
  static const String socketCallUserOffline = 'call_user_offline';

  // ─── Firebase Firestore Collection Names ─────────────────────────────────
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String paymentsCollection = 'payments';
  static const String bookingsCollection = 'bookings';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';

  // ─── Payment Status Constants ────────────────────────────────────────────
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // ─── Firebase Storage Folder Paths ───────────────────────────────────────
  static const String postImagesFolder = 'post_images';
  static const String profileImagesFolder = 'profile_images';

  // ─── Local Storage / Shared Preferences Keys ─────────────────────────────
  static const String tokenKey = 'token';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'userId';
  static const String userRoleKey = 'userRole';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String isPaidKey = 'isPaid';
}
