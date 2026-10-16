import 'package:flutter/material.dart';

import 'screens/bookings.dart';
import 'screens/explore.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'screens/profile.dart';
import 'screens/ride.dart';
import 'screens/safety.dart';
import 'screens/shuttle.dart';
import 'screens/system.dart';
import 'screens/tours.dart';
import 'screens/wallet.dart';

class ScreenEntry {
  const ScreenEntry(this.id, this.title, this.route, this.builder);

  /// Section and screen number, e.g. "3.4".
  final String id;
  final String title;
  final String route;
  final WidgetBuilder builder;

  int get section => int.parse(id.split('.').first);
}

const sectionNames = {
  1: 'Onboarding and account',
  2: 'Home and discovery',
  3: 'Cabo Ride',
  4: 'Cabo Shuttle',
  5: 'Cabo Tours',
  6: 'Cabo Explore',
  7: 'Payments and wallet',
  8: 'Safety',
  9: 'Bookings and support',
  10: 'Profile and settings',
  11: 'System and edge cases',
};

/// Every screen in the app, in section order.
final screens = <ScreenEntry>[
  // 1. Onboarding and account
  ScreenEntry('1.1', 'Splash screen', '/', (_) => const SplashScreen()),
  ScreenEntry('1.2', 'Welcome', '/welcome', (_) => const WelcomeScreen()),
  ScreenEntry(
    '1.3',
    'Sign up or log in',
    '/sign-in',
    (_) => const SignInScreen(),
  ),
  ScreenEntry('1.4', 'Phone number', '/phone', (_) => const PhoneScreen()),
  ScreenEntry('1.5', 'OTP verification', '/otp', (_) => const OtpScreen()),
  ScreenEntry('1.6', 'Email sign-in', '/email', (_) => const EmailScreen()),
  ScreenEntry(
    '1.7',
    'Profile setup',
    '/profile-setup',
    (_) => const ProfileSetupScreen(),
  ),
  ScreenEntry(
    '1.8',
    'Traveller type',
    '/traveller-type',
    (_) => const TravellerTypeScreen(),
  ),
  ScreenEntry(
    '1.9',
    'Emergency contact',
    '/emergency-contact',
    (_) => const EmergencyContactScreen(),
  ),
  ScreenEntry(
    '1.10',
    'Permissions',
    '/permissions',
    (_) => const PermissionsScreen(),
  ),
  ScreenEntry('1.11', 'All set', '/all-set', (_) => const AllSetScreen()),

  // 2. Home and discovery
  ScreenEntry('2.1', 'Home dashboard', '/home', (_) => const HomeScreen()),
  ScreenEntry('2.2', 'Search results', '/search', (_) => const SearchScreen()),
  ScreenEntry(
    '2.3',
    'Notifications',
    '/notifications',
    (_) => const NotificationsScreen(),
  ),
  ScreenEntry(
    '2.4',
    'Mobility inclusive',
    '/mobility',
    (_) => const MobilityScreen(),
  ),

  // 3. Cabo Ride
  ScreenEntry('3.1', 'Where to', '/where-to', (_) => const WhereToScreen()),
  ScreenEntry(
    '3.2',
    'Pick on map',
    '/pick-on-map',
    (_) => const PickOnMapScreen(),
  ),
  ScreenEntry(
    '3.3',
    'Confirm pickup',
    '/confirm-pickup',
    (_) => const ConfirmPickupScreen(),
  ),
  ScreenEntry(
    '3.4',
    'Choose a ride',
    '/choose-ride',
    (_) => const ChooseRideScreen(),
  ),
  ScreenEntry(
    '3.5',
    'Fare breakdown',
    '/fare-breakdown',
    (_) => const FareBreakdownScreen(),
  ),
  ScreenEntry(
    '3.6',
    'Payment method',
    '/payment-method',
    (_) => const PaymentMethodScreen(),
  ),
  ScreenEntry(
    '3.7',
    'Finding a driver',
    '/finding-driver',
    (_) => const FindingDriverScreen(),
  ),
  ScreenEntry(
    '3.8',
    'Driver on the way',
    '/driver-on-way',
    (_) => const DriverOnTheWayScreen(),
  ),
  ScreenEntry(
    '3.9',
    'Chat with driver',
    '/chat-driver',
    (_) => const ChatWithDriverScreen(),
  ),
  ScreenEntry(
    '3.10',
    'Trip in progress',
    '/trip-in-progress',
    (_) => const TripInProgressScreen(),
  ),
  ScreenEntry(
    '3.11',
    'Share trip',
    '/share-trip',
    (_) => const ShareTripScreen(),
  ),
  ScreenEntry('3.12', 'Add a stop', '/add-stop', (_) => const AddStopScreen()),
  ScreenEntry(
    '3.13',
    'Schedule a ride',
    '/schedule-ride',
    (_) => const ScheduleRideScreen(),
  ),
  ScreenEntry(
    '3.14',
    'Cancel ride',
    '/cancel-ride',
    (_) => const CancelRideScreen(),
  ),
  ScreenEntry(
    '3.15',
    'Trip complete and tip',
    '/trip-complete',
    (_) => const TripCompleteScreen(),
  ),
  ScreenEntry(
    '3.16',
    'Rate driver',
    '/rate-driver',
    (_) => const RateDriverScreen(),
  ),

  // 4. Cabo Shuttle
  ScreenEntry(
    '4.1',
    'Airport shuttle',
    '/shuttle',
    (_) => const ShuttleScreen(),
  ),
  ScreenEntry(
    '4.2',
    'Flight details',
    '/shuttle-flight',
    (_) => const ShuttleFlightScreen(),
  ),
  ScreenEntry(
    '4.3',
    'Vehicle and luggage',
    '/shuttle-vehicle',
    (_) => const ShuttleVehicleScreen(),
  ),
  ScreenEntry(
    '4.4',
    'Review and pay',
    '/shuttle-review',
    (_) => const ShuttleReviewScreen(),
  ),
  ScreenEntry(
    '4.5',
    'Shuttle confirmed',
    '/shuttle-confirmed',
    (_) => const ShuttleConfirmedScreen(),
  ),
  ScreenEntry(
    '4.6',
    'Driver assigned',
    '/shuttle-assigned',
    (_) => const ShuttleAssignedScreen(),
  ),

  // 5. Cabo Tours
  ScreenEntry('5.1', 'Tours home', '/tours', (_) => const ToursHomeScreen()),
  ScreenEntry('5.2', 'Tour list', '/tour-list', (_) => const TourListScreen()),
  ScreenEntry(
    '5.3',
    'Tour filters',
    '/tour-filters',
    (_) => const TourFiltersScreen(),
  ),
  ScreenEntry(
    '5.4',
    'Tour detail',
    '/tour-detail',
    (_) => const TourDetailScreen(),
  ),
  ScreenEntry(
    '5.5',
    'Itinerary and inclusions',
    '/tour-itinerary',
    (_) => const TourItineraryScreen(),
  ),
  ScreenEntry(
    '5.6',
    'Tour reviews',
    '/tour-reviews',
    (_) => const TourReviewsScreen(),
  ),
  ScreenEntry(
    '5.7',
    'Date and guests',
    '/tour-date',
    (_) => const TourDateScreen(),
  ),
  ScreenEntry(
    '5.8',
    'Add-ons',
    '/tour-addons',
    (_) => const TourAddonsScreen(),
  ),
  ScreenEntry(
    '5.9',
    'Tour checkout',
    '/tour-checkout',
    (_) => const TourCheckoutScreen(),
  ),
  ScreenEntry(
    '5.10',
    'Bank transfer',
    '/bank-transfer',
    (_) => const BankTransferScreen(),
  ),
  ScreenEntry(
    '5.11',
    'Booking confirmed',
    '/tour-confirmed',
    (_) => const TourConfirmedScreen(),
  ),
  ScreenEntry('5.12', 'QR ticket', '/ticket', (_) => const TicketScreen()),
  ScreenEntry(
    '5.13',
    'Write a review',
    '/write-review',
    (_) => const WriteReviewScreen(),
  ),
  ScreenEntry(
    '5.14',
    'Cancel or reschedule',
    '/tour-cancel',
    (_) => const TourCancelScreen(),
  ),
  ScreenEntry(
    '5.15',
    'Private tour request',
    '/private-tour',
    (_) => const PrivateTourScreen(),
  ),

  // 6. Cabo Explore
  ScreenEntry('6.1', 'Explore list', '/explore', (_) => const ExploreScreen()),
  ScreenEntry(
    '6.2',
    'Explore map',
    '/explore-map',
    (_) => const ExploreMapScreen(),
  ),
  ScreenEntry(
    '6.3',
    'Attraction detail',
    '/attraction',
    (_) => const AttractionScreen(),
  ),
  ScreenEntry('6.4', 'Wishlist', '/wishlist', (_) => const WishlistScreen()),
  ScreenEntry(
    '6.5',
    'Itinerary planner',
    '/itinerary',
    (_) => const ItineraryScreen(),
  ),
  ScreenEntry('6.6', 'Events', '/events', (_) => const EventsScreen()),

  // 7. Payments and wallet
  ScreenEntry('7.1', 'Wallet', '/wallet', (_) => const WalletScreen()),
  ScreenEntry('7.2', 'Top up', '/top-up', (_) => const TopUpScreen()),
  ScreenEntry(
    '7.3',
    'Payment methods',
    '/payment-methods',
    (_) => const PaymentMethodsScreen(),
  ),
  ScreenEntry('7.4', 'Add a card', '/add-card', (_) => const AddCardScreen()),
  ScreenEntry(
    '7.5',
    'Transactions',
    '/transactions',
    (_) => const TransactionsScreen(),
  ),
  ScreenEntry('7.6', 'Receipt', '/receipt', (_) => const ReceiptScreen()),
  ScreenEntry('7.7', 'Promo codes', '/promos', (_) => const PromosScreen()),

  // 8. Safety
  ScreenEntry(
    '8.1',
    'Safety centre',
    '/safety',
    (_) => const SafetyCentreScreen(),
  ),
  ScreenEntry('8.2', 'SOS emergency', '/sos', (_) => const SosScreen()),
  ScreenEntry(
    '8.3',
    'Are you OK check',
    '/are-you-ok',
    (_) => const AreYouOkScreen(),
  ),
  ScreenEntry(
    '8.4',
    'Trusted contacts',
    '/trusted-contacts',
    (_) => const TrustedContactsScreen(),
  ),

  // 9. Bookings and support
  ScreenEntry('9.1', 'My bookings', '/bookings', (_) => const BookingsScreen()),
  ScreenEntry(
    '9.2',
    'Past trip detail',
    '/past-trip',
    (_) => const PastTripScreen(),
  ),
  ScreenEntry(
    '9.3',
    'Report an issue',
    '/report-issue',
    (_) => const ReportIssueScreen(),
  ),
  ScreenEntry('9.4', 'Help centre', '/help', (_) => const HelpScreen()),
  ScreenEntry(
    '9.5',
    'Live support chat',
    '/support-chat',
    (_) => const SupportChatScreen(),
  ),
  ScreenEntry(
    '9.6',
    'Support tickets',
    '/support-tickets',
    (_) => const SupportTicketsScreen(),
  ),
  ScreenEntry(
    '9.7',
    'Rewards and referrals',
    '/rewards',
    (_) => const RewardsScreen(),
  ),

  // 10. Profile and settings
  ScreenEntry('10.1', 'Profile', '/profile', (_) => const ProfileScreen()),
  ScreenEntry(
    '10.2',
    'Edit profile',
    '/edit-profile',
    (_) => const EditProfileScreen(),
  ),
  ScreenEntry(
    '10.3',
    'Saved places',
    '/saved-places',
    (_) => const SavedPlacesScreen(),
  ),
  ScreenEntry('10.4', 'Language', '/language', (_) => const LanguageScreen()),
  ScreenEntry(
    '10.5',
    'Home currency',
    '/currency',
    (_) => const CurrencyScreen(),
  ),
  ScreenEntry(
    '10.6',
    'Notification settings',
    '/notification-settings',
    (_) => const NotificationSettingsScreen(),
  ),
  ScreenEntry(
    '10.7',
    'Accessibility',
    '/accessibility',
    (_) => const AccessibilityScreen(),
  ),
  ScreenEntry(
    '10.8',
    'Legal and privacy',
    '/legal',
    (_) => const LegalScreen(),
  ),
  ScreenEntry(
    '10.9',
    'Delete account',
    '/delete-account',
    (_) => const DeleteAccountScreen(),
  ),

  // 11. System and edge cases
  ScreenEntry(
    '11.1',
    'No internet',
    '/no-internet',
    (_) => const NoInternetScreen(),
  ),
  ScreenEntry(
    '11.2',
    'Location off',
    '/location-off',
    (_) => const LocationOffScreen(),
  ),
  ScreenEntry(
    '11.3',
    'Payment failed',
    '/payment-failed',
    (_) => const PaymentFailedScreen(),
  ),
  ScreenEntry(
    '11.4',
    'No drivers available',
    '/no-drivers',
    (_) => const NoDriversScreen(),
  ),
  ScreenEntry(
    '11.5',
    'Outside service area',
    '/outside-area',
    (_) => const OutsideAreaScreen(),
  ),
  ScreenEntry(
    '11.6',
    'App update required',
    '/update-required',
    (_) => const UpdateRequiredScreen(),
  ),

  // Not a product screen: a list of every screen, reachable from Profile.
  ScreenEntry(
    '12.1',
    'Screen gallery',
    '/gallery',
    (_) => const GalleryScreen(),
  ),
];
