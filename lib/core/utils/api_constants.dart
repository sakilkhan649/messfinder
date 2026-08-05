class ApiConstants {
  // Base URLs (For future REST API / SMS Gateway / OSM Nominatim API)
  static const String baseUrl = 'https://api.example.com';
  static const String osmGeocodingUrl = 'https://nominatim.openstreetmap.org';

  // Timeout Durations
  static const int connectionTimeout = 30; // 30 seconds
  static const int receiveTimeout = 30;

  // Firebase Firestore Collection Names
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String paymentsCollection = 'payments';
  static const String bookingsCollection = 'bookings';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';

  // Payment Status Constants
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Firebase Storage Folder Paths
  static const String postImagesFolder = 'post_images';
  static const String profileImagesFolder = 'profile_images';

  // Local Storage / Shared Preferences Keys
  static const String tokenKey = 'token';
  static const String userIdKey = 'userId';
  static const String userRoleKey = 'userRole';
  static const String isLoggedInKey = 'isLoggedIn';
  static const String isPaidKey = 'isPaid';

  // API Endpoints (if needed later)
  static const String loginEndpoint = '/api/v1/auth/login';
  static const String registerEndpoint = '/api/v1/auth/register';
}
