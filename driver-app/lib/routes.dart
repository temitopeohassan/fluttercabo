import 'package:flutter/material.dart';

import 'screens/account.dart';
import 'screens/earnings.dart';
import 'screens/gallery.dart';
import 'screens/home.dart';
import 'screens/jobs.dart';
import 'screens/onboarding.dart';
import 'screens/performance.dart';
import 'screens/safety.dart';
import 'screens/system.dart';
import 'screens/trips.dart';

class ScreenEntry {
  const ScreenEntry(this.id, this.title, this.route, this.builder);

  /// Number from the screen spec, e.g. "1.4".
  final String id;
  final String title;
  final String route;
  final WidgetBuilder builder;

  int get section => int.parse(id.split('.').first);
}

const sectionNames = {
  1: 'Onboarding and verification',
  2: 'Home and going online',
  3: 'Ride requests and trips',
  4: 'Scheduled jobs',
  5: 'Earnings and payouts',
  6: 'Performance and growth',
  7: 'Safety and support',
  8: 'Account and settings',
  9: 'System and edge cases',
};

/// Every screen in the app, in spec order.
final screens = <ScreenEntry>[
  // 1. Onboarding and verification
  ScreenEntry('1.1', 'Splash screen', '/', (_) => const SplashScreen()),
  ScreenEntry(
    '1.2',
    'Welcome carousel',
    '/welcome',
    (_) => const WelcomeScreen(),
  ),
  ScreenEntry(
    '1.3',
    'Sign up / log in',
    '/sign-in',
    (_) => const SignInScreen(),
  ),
  ScreenEntry('1.4', 'OTP verification', '/otp', (_) => const OtpScreen()),
  ScreenEntry(
    '1.5',
    'Personal details',
    '/personal-details',
    (_) => const PersonalDetailsScreen(),
  ),
  ScreenEntry(
    '1.6',
    'Driver type',
    '/driver-type',
    (_) => const DriverTypeScreen(),
  ),
  ScreenEntry(
    '1.7',
    'Document upload',
    '/documents-upload',
    (_) => const DocumentUploadScreen(),
  ),
  ScreenEntry(
    '1.8',
    'Vehicle details',
    '/vehicle-details',
    (_) => const VehicleDetailsScreen(),
  ),
  ScreenEntry(
    '1.9',
    'Vehicle documents',
    '/vehicle-documents',
    (_) => const VehicleDocumentsScreen(),
  ),
  ScreenEntry(
    '1.10',
    'Vehicle photos',
    '/vehicle-photos',
    (_) => const VehiclePhotosScreen(),
  ),
  ScreenEntry(
    '1.11',
    'Face verification',
    '/face-verification',
    (_) => const FaceVerificationScreen(),
  ),
  ScreenEntry(
    '1.12',
    'Background check consent',
    '/background-check',
    (_) => const BackgroundCheckScreen(),
  ),
  ScreenEntry(
    '1.13',
    'Payout details',
    '/payout-details',
    (_) => const PayoutDetailsScreen(),
  ),
  ScreenEntry(
    '1.14',
    'Application status',
    '/application-status',
    (_) => const ApplicationStatusScreen(),
  ),
  ScreenEntry(
    '1.15',
    'Inspection booking',
    '/inspection-booking',
    (_) => const InspectionBookingScreen(),
  ),
  ScreenEntry(
    '1.16',
    'Training module',
    '/training',
    (_) => const TrainingScreen(),
  ),
  ScreenEntry(
    '1.16b',
    'Training quiz',
    '/training-quiz',
    (_) => const TrainingQuizScreen(),
  ),
  ScreenEntry(
    '1.17',
    'Approved / welcome',
    '/approved',
    (_) => const ApprovedScreen(),
  ),
  ScreenEntry(
    '1.18',
    'Permissions',
    '/permissions',
    (_) => const PermissionsScreen(),
  ),

  // 2. Home and going online
  ScreenEntry(
    '2.1',
    'Home (offline)',
    '/home',
    (_) => const HomeOfflineScreen(),
  ),
  ScreenEntry(
    '2.2',
    'Home (online)',
    '/home-online',
    (_) => const HomeOnlineScreen(),
  ),
  ScreenEntry(
    '2.3',
    'Demand hotspots',
    '/hotspots',
    (_) => const HotspotsScreen(),
  ),
  ScreenEntry(
    '2.4',
    'Ride preferences',
    '/ride-preferences',
    (_) => const RidePreferencesScreen(),
  ),
  ScreenEntry(
    '2.5',
    'Notifications inbox',
    '/notifications',
    (_) => const NotificationsScreen(),
  ),

  // 3. Ride requests and trips
  ScreenEntry(
    '3.1',
    'Incoming request',
    '/incoming-request',
    (_) => const IncomingRequestScreen(),
  ),
  ScreenEntry(
    '3.2',
    'Navigate to pickup',
    '/navigate-pickup',
    (_) => const NavigateToPickupScreen(),
  ),
  ScreenEntry(
    '3.3',
    'Arrived at pickup',
    '/arrived-pickup',
    (_) => const ArrivedAtPickupScreen(),
  ),
  ScreenEntry(
    '3.4',
    'Chat with rider',
    '/chat-rider',
    (_) => const ChatWithRiderScreen(),
  ),
  ScreenEntry(
    '3.5',
    'Verify rider',
    '/verify-rider',
    (_) => const VerifyRiderScreen(),
  ),
  ScreenEntry(
    '3.6',
    'Trip in progress',
    '/trip-in-progress',
    (_) => const TripInProgressScreen(),
  ),
  ScreenEntry('3.7', 'End trip', '/end-trip', (_) => const EndTripScreen()),
  ScreenEntry(
    '3.8',
    'Collect payment',
    '/collect-payment',
    (_) => const CollectPaymentScreen(),
  ),
  ScreenEntry(
    '3.9',
    'Trip summary',
    '/trip-summary',
    (_) => const TripSummaryScreen(),
  ),
  ScreenEntry(
    '3.10',
    'Rate rider',
    '/rate-rider',
    (_) => const RateRiderScreen(),
  ),
  ScreenEntry(
    '3.11',
    'Cancel trip',
    '/cancel-trip',
    (_) => const CancelTripScreen(),
  ),

  // 4. Scheduled jobs
  ScreenEntry('4.1', 'Jobs board', '/jobs', (_) => const JobsBoardScreen()),
  ScreenEntry(
    '4.2',
    'Job detail',
    '/job-detail',
    (_) => const JobDetailScreen(),
  ),
  ScreenEntry(
    '4.3',
    'My schedule',
    '/schedule',
    (_) => const MyScheduleScreen(),
  ),
  ScreenEntry(
    '4.4',
    'Airport pickup',
    '/airport-pickup',
    (_) => const AirportPickupScreen(),
  ),
  ScreenEntry(
    '4.4b',
    'Name board',
    '/name-board',
    (_) => const NameBoardScreen(),
  ),
  ScreenEntry(
    '4.5',
    'Tour job overview',
    '/tour-overview',
    (_) => const TourOverviewScreen(),
  ),
  ScreenEntry(
    '4.6',
    'Tour in progress',
    '/tour-in-progress',
    (_) => const TourInProgressScreen(),
  ),
  ScreenEntry(
    '4.7',
    'Guest check-in',
    '/guest-check-in',
    (_) => const GuestCheckInScreen(),
  ),
  ScreenEntry(
    '4.8',
    'Tour completed',
    '/tour-completed',
    (_) => const TourCompletedScreen(),
  ),

  // 5. Earnings and payouts
  ScreenEntry(
    '5.1',
    'Earnings dashboard',
    '/earnings',
    (_) => const EarningsDashboardScreen(),
  ),
  ScreenEntry(
    '5.2',
    'Earnings chart',
    '/earnings-chart',
    (_) => const EarningsChartScreen(),
  ),
  ScreenEntry(
    '5.3',
    'Trip history',
    '/trip-history',
    (_) => const TripHistoryScreen(),
  ),
  ScreenEntry(
    '5.4',
    'Trip earnings detail',
    '/trip-earnings-detail',
    (_) => const TripEarningsDetailScreen(),
  ),
  ScreenEntry('5.5', 'Payouts', '/payouts', (_) => const PayoutsScreen()),
  ScreenEntry(
    '5.6',
    'Cash balance',
    '/cash-balance',
    (_) => const CashBalanceScreen(),
  ),
  ScreenEntry(
    '5.7',
    'Incentives and bonuses',
    '/incentives',
    (_) => const IncentivesScreen(),
  ),

  // 6. Performance and growth
  ScreenEntry('6.1', 'Ratings', '/ratings', (_) => const RatingsScreen()),
  ScreenEntry(
    '6.2',
    'Performance stats',
    '/performance',
    (_) => const PerformanceStatsScreen(),
  ),
  ScreenEntry('6.3', 'Tiers and badges', '/tiers', (_) => const TiersScreen()),
  ScreenEntry(
    '6.4',
    'Tour guide certification',
    '/tour-certification',
    (_) => const TourCertificationScreen(),
  ),
  ScreenEntry(
    '6.5',
    'Learning centre',
    '/learning-centre',
    (_) => const LearningCentreScreen(),
  ),

  // 7. Safety and support
  ScreenEntry(
    '7.1',
    'Safety toolkit',
    '/safety',
    (_) => const SafetyToolkitScreen(),
  ),
  ScreenEntry('7.2', 'Emergency', '/emergency', (_) => const EmergencyScreen()),
  ScreenEntry(
    '7.3',
    'Report an incident',
    '/report-incident',
    (_) => const ReportIncidentScreen(),
  ),
  ScreenEntry('7.4', 'Lost item', '/lost-item', (_) => const LostItemScreen()),
  ScreenEntry('7.5', 'Help centre', '/help', (_) => const HelpCentreScreen()),
  ScreenEntry(
    '7.6',
    'Live support chat',
    '/support-chat',
    (_) => const SupportChatScreen(),
  ),
  ScreenEntry(
    '7.7',
    'Support tickets',
    '/support-tickets',
    (_) => const SupportTicketsScreen(),
  ),

  // 8. Account and settings
  ScreenEntry(
    '8.1',
    'Account overview',
    '/account',
    (_) => const AccountOverviewScreen(),
  ),
  ScreenEntry(
    '8.2',
    'Edit profile',
    '/edit-profile',
    (_) => const EditProfileScreen(),
  ),
  ScreenEntry(
    '8.3',
    'Vehicle management',
    '/vehicles',
    (_) => const VehicleManagementScreen(),
  ),
  ScreenEntry('8.4', 'Documents', '/documents', (_) => const DocumentsScreen()),
  ScreenEntry(
    '8.5',
    'Bank details',
    '/bank-details',
    (_) => const BankDetailsScreen(),
  ),
  ScreenEntry(
    '8.6',
    'Navigation settings',
    '/navigation-settings',
    (_) => const NavigationSettingsScreen(),
  ),
  ScreenEntry(
    '8.7',
    'Language settings',
    '/language',
    (_) => const LanguageSettingsScreen(),
  ),
  ScreenEntry(
    '8.8',
    'Notification and sound settings',
    '/notification-settings',
    (_) => const NotificationSettingsScreen(),
  ),
  ScreenEntry('8.9', 'Refer a driver', '/refer', (_) => const ReferScreen()),
  ScreenEntry('8.10', 'Legal', '/legal', (_) => const LegalScreen()),
  ScreenEntry(
    '8.11',
    'Log out and delete account',
    '/logout-delete',
    (_) => const LogoutDeleteScreen(),
  ),

  // 9. System and edge cases
  ScreenEntry(
    '9.1',
    'No internet',
    '/no-internet',
    (_) => const NoInternetScreen(),
  ),
  ScreenEntry(
    '9.2',
    'GPS signal lost',
    '/gps-lost',
    (_) => const GpsLostScreen(),
  ),
  ScreenEntry(
    '9.3',
    'Account on hold',
    '/account-on-hold',
    (_) => const AccountOnHoldScreen(),
  ),
  ScreenEntry(
    '9.4',
    'Document expired',
    '/document-expired',
    (_) => const DocumentExpiredScreen(),
  ),
  ScreenEntry(
    '9.5',
    'Outside service area',
    '/outside-service-area',
    (_) => const OutsideServiceAreaScreen(),
  ),
  ScreenEntry(
    '9.6',
    'App update required',
    '/update-required',
    (_) => const UpdateRequiredScreen(),
  ),

  // Not in the spec: a list of every screen, reachable from Account.
  ScreenEntry(
    '10.1',
    'Screen gallery',
    '/gallery',
    (_) => const GalleryScreen(),
  ),
];
