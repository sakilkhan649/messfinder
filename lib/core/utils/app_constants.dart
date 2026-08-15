class AppConstants {
  // App Info
  static const String appName = 'MessFinder';
  static const String appBanglaName = 'MessFinder';
  static const String appTagline = 'Your Trusted Roommate Finder';
  static const String appSlogan = 'Find your perfect room easily';

  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';

  // Registration Fees (in BDT)
  static const int landlordFee = 70;
  static const int bachelorFee = 50;

  // Payment Numbers (Default display numbers for MVP)
  static const String bkashNumber = '017XXXXXXXX (Personal)';
  static const String nagadNumber = '017XXXXXXXX (Personal)';
  static const String rocketNumber = '017XXXXXXXX (Personal)';

  // Payment Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Bachelor Types
  static const String typeMale = 'male';
  static const String typeFemale = 'female';
  static const String typeBoth = 'both';

  // Mess Facilities List
  static const List<String> availableFacilities = [
    'WiFi',
    '24/7 Water Supply',
    'Meal System Available',
    'Filtered Drinking Water',
    'Study Table & Chair',
    'Attached Bathroom',
    'Attached Balcony',
    'Daily Cleaning Service',
    'Gas Pipeline / Cylinder',
    'Kitchen Facility',
    'Lift / Elevator',
    'Generator Backup',
    'Security / CCTV',
    'Bike Parking',
  ];

  // Popular Areas in Dhaka (for easy filtering)
  static const List<String> popularAreas = [
    'All',
    'Farmgate',
    'Nilkhet',
    'Mirpur',
    'Uttara',
    'Dhanmondi',
    'Mohammadpur',
    'Badda',
    'Bashundhara',
    'Banani',
  ];
}
