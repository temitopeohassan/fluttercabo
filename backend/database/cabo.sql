-- Cabo: tables and sample data for the admin control panel and the rider and driver APIs.
--
-- Import into an empty MySQL 8 or MariaDB 10.6+ database:
--   mysql -u root -p -e "CREATE DATABASE cabo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
--   mysql -u root -p cabo < database/cabo.sql
-- Importing again replaces every table.
--
-- Admin sign-in: admin@caboapp.online / password123!  (change it before going live)
-- Regenerate with: php artisan migrate:fresh --seed && database/dump.sh
-- Money is stored in whole naira. Times are UTC; sample dates are relative to 2026-10-19, when this file was made.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET UNIQUE_CHECKS = 0;
SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone = '+00:00';


DROP TABLE IF EXISTS `admins`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `admins` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('super_admin','operations','support','finance') NOT NULL DEFAULT 'operations',
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `remember_token` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `admins_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `app_notifications`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `app_notifications` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `recipient_type` varchar(255) NOT NULL,
  `recipient_id` bigint(20) unsigned NOT NULL,
  `type` varchar(40) NOT NULL,
  `title` varchar(255) NOT NULL,
  `body` varchar(255) NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`data`)),
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `app_notifications_recipient_type_recipient_id_index` (`recipient_type`,`recipient_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `attractions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `attractions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `category` varchar(255) NOT NULL,
  `area` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `lat` decimal(10,7) NOT NULL,
  `lng` decimal(10,7) NOT NULL,
  `opening_hours` varchar(255) DEFAULT NULL,
  `entry_fee` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Naira, 0 for free',
  `visitor_tips` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`visitor_tips`)),
  `safety_notes` text DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `rating` decimal(3,2) DEFAULT NULL,
  `reviews_count` int(10) unsigned NOT NULL DEFAULT 0,
  `is_published` tinyint(1) NOT NULL DEFAULT 1,
  `last_reviewed_on` date DEFAULT NULL COMMENT 'Content is checked at least quarterly',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `attractions_slug_unique` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cache`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache` (
  `key` varchar(255) NOT NULL,
  `value` mediumtext NOT NULL,
  `expiration` bigint(20) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `cache_locks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `cache_locks` (
  `key` varchar(255) NOT NULL,
  `owner` varchar(255) NOT NULL,
  `expiration` bigint(20) NOT NULL,
  PRIMARY KEY (`key`),
  KEY `cache_locks_expiration_index` (`expiration`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `driver_documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `driver_documents` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `driver_id` bigint(20) unsigned NOT NULL,
  `vehicle_id` bigint(20) unsigned DEFAULT NULL,
  `type` enum('drivers_licence','national_id','proof_of_address','lasdri_card','state_permit','vehicle_licence','roadworthiness','insurance','vehicle_photo','selfie') NOT NULL,
  `label` varchar(255) DEFAULT NULL,
  `file_path` varchar(255) DEFAULT NULL,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `rejection_reason` varchar(255) DEFAULT NULL,
  `expires_at` date DEFAULT NULL,
  `reviewed_by` bigint(20) unsigned DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `driver_documents_driver_id_foreign` (`driver_id`),
  KEY `driver_documents_vehicle_id_foreign` (`vehicle_id`),
  KEY `driver_documents_reviewed_by_foreign` (`reviewed_by`),
  KEY `driver_documents_status_type_index` (`status`,`type`),
  CONSTRAINT `driver_documents_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `driver_documents_reviewed_by_foreign` FOREIGN KEY (`reviewed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL,
  CONSTRAINT `driver_documents_vehicle_id_foreign` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `drivers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `drivers` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(32) NOT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `date_of_birth` date DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `languages` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`languages`)),
  `driver_type` enum('independent','fleet') NOT NULL DEFAULT 'independent',
  `fleet_partner_id` bigint(20) unsigned DEFAULT NULL,
  `status` enum('applicant','pending_review','approved','suspended','rejected') NOT NULL DEFAULT 'applicant',
  `status_reason` varchar(255) DEFAULT NULL,
  `tier` enum('standard','premium') NOT NULL DEFAULT 'standard',
  `is_tour_guide` tinyint(1) NOT NULL DEFAULT 0,
  `training_completed` tinyint(1) NOT NULL DEFAULT 0,
  `background_check_consent` tinyint(1) NOT NULL DEFAULT 0,
  `inspection_at` timestamp NULL DEFAULT NULL,
  `inspection_location` varchar(255) DEFAULT NULL,
  `is_online` tinyint(1) NOT NULL DEFAULT 0,
  `current_lat` decimal(10,7) DEFAULT NULL,
  `current_lng` decimal(10,7) DEFAULT NULL,
  `location_updated_at` timestamp NULL DEFAULT NULL,
  `preferences` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Ride tiers, job types and destination filter' CHECK (json_valid(`preferences`)),
  `rating` decimal(3,2) DEFAULT NULL,
  `acceptance_rate` decimal(5,2) NOT NULL DEFAULT 100.00,
  `cancellation_rate` decimal(5,2) NOT NULL DEFAULT 0.00,
  `bank_name` varchar(255) DEFAULT NULL,
  `bank_account_number` varchar(20) DEFAULT NULL,
  `bank_account_name` varchar(255) DEFAULT NULL,
  `earnings_balance` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Naira, unpaid card earnings',
  `cash_commission_owed` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Naira, from cash trips',
  `referral_code` varchar(16) NOT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `drivers_phone_unique` (`phone`),
  UNIQUE KEY `drivers_referral_code_unique` (`referral_code`),
  UNIQUE KEY `drivers_email_unique` (`email`),
  KEY `drivers_fleet_partner_id_foreign` (`fleet_partner_id`),
  CONSTRAINT `drivers_fleet_partner_id_foreign` FOREIGN KEY (`fleet_partner_id`) REFERENCES `fleet_partners` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `emergency_contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `emergency_contacts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `rider_id` bigint(20) unsigned NOT NULL,
  `name` varchar(255) NOT NULL,
  `phone` varchar(32) NOT NULL,
  `relationship` varchar(255) DEFAULT NULL,
  `share_trips_automatically` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `emergency_contacts_rider_id_foreign` (`rider_id`),
  CONSTRAINT `emergency_contacts_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `failed_jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `failed_jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `uuid` varchar(255) NOT NULL,
  `connection` varchar(255) NOT NULL,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `exception` longtext NOT NULL,
  `failed_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `failed_jobs_uuid_unique` (`uuid`),
  KEY `failed_jobs_connection_queue_failed_at_index` (`connection`,`queue`,`failed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `fleet_partners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `fleet_partners` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `area` varchar(255) DEFAULT NULL,
  `contact_name` varchar(255) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `job_batches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `job_batches` (
  `id` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `total_jobs` int(11) NOT NULL,
  `pending_jobs` int(11) NOT NULL,
  `failed_jobs` int(11) NOT NULL,
  `failed_job_ids` longtext NOT NULL,
  `options` mediumtext DEFAULT NULL,
  `cancelled_at` int(11) DEFAULT NULL,
  `created_at` int(11) NOT NULL,
  `finished_at` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `jobs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `jobs` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `queue` varchar(255) NOT NULL,
  `payload` longtext NOT NULL,
  `attempts` smallint(5) unsigned NOT NULL,
  `reserved_at` int(10) unsigned DEFAULT NULL,
  `available_at` int(10) unsigned NOT NULL,
  `created_at` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jobs_queue_index` (`queue`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `migrations` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `migration` varchar(255) NOT NULL,
  `batch` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `otp_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `otp_codes` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `app` enum('rider','driver') NOT NULL,
  `identifier` varchar(255) NOT NULL COMMENT 'Phone number or email',
  `channel` enum('sms','email') NOT NULL,
  `code_hash` varchar(255) NOT NULL,
  `attempts` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `expires_at` timestamp NOT NULL,
  `used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `otp_codes_app_identifier_index` (`app`,`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `partners`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `partners` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `type` enum('tour_operator','guide','attraction','hotel') NOT NULL DEFAULT 'tour_operator',
  `contact_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `cac_number` varchar(32) DEFAULT NULL,
  `status` enum('pending','approved','suspended') NOT NULL DEFAULT 'pending',
  `commission_rate` decimal(5,2) NOT NULL DEFAULT 15.00,
  `bank_name` varchar(255) DEFAULT NULL,
  `bank_account_number` varchar(20) DEFAULT NULL,
  `bank_account_name` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `email` varchar(255) NOT NULL,
  `token` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `payouts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `payouts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `reference` varchar(20) NOT NULL,
  `driver_id` bigint(20) unsigned NOT NULL,
  `type` enum('weekly','instant') NOT NULL,
  `amount` int(10) unsigned NOT NULL COMMENT 'Naira paid to the driver',
  `fee` int(10) unsigned NOT NULL DEFAULT 0,
  `period_start` date DEFAULT NULL,
  `period_end` date DEFAULT NULL,
  `bank_name` varchar(255) NOT NULL,
  `bank_account_number` varchar(20) NOT NULL,
  `status` enum('pending','processing','paid','failed') NOT NULL DEFAULT 'pending',
  `processed_by` bigint(20) unsigned DEFAULT NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `payouts_reference_unique` (`reference`),
  KEY `payouts_driver_id_foreign` (`driver_id`),
  KEY `payouts_processed_by_foreign` (`processed_by`),
  CONSTRAINT `payouts_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE CASCADE,
  CONSTRAINT `payouts_processed_by_foreign` FOREIGN KEY (`processed_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `personal_access_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `personal_access_tokens` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tokenable_type` varchar(255) NOT NULL,
  `tokenable_id` bigint(20) unsigned NOT NULL,
  `name` text NOT NULL,
  `token` varchar(64) NOT NULL,
  `abilities` text DEFAULT NULL,
  `last_used_at` timestamp NULL DEFAULT NULL,
  `expires_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `personal_access_tokens_token_unique` (`token`),
  KEY `personal_access_tokens_tokenable_type_tokenable_id_index` (`tokenable_type`,`tokenable_id`),
  KEY `personal_access_tokens_expires_at_index` (`expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `promo_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `promo_codes` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `description` varchar(255) NOT NULL,
  `discount_type` enum('percent','fixed') NOT NULL,
  `value` int(10) unsigned NOT NULL COMMENT 'Percent or naira',
  `max_discount` int(10) unsigned DEFAULT NULL COMMENT 'Naira cap for percent codes',
  `applies_to` enum('all','ride','shuttle','tour') NOT NULL DEFAULT 'all',
  `first_booking_only` tinyint(1) NOT NULL DEFAULT 0,
  `usage_limit` int(10) unsigned DEFAULT NULL,
  `used_count` int(10) unsigned NOT NULL DEFAULT 0,
  `starts_at` timestamp NULL DEFAULT NULL,
  `ends_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `promo_codes_code_unique` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `reviews`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `reviews` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `rider_id` bigint(20) unsigned NOT NULL,
  `tour_id` bigint(20) unsigned NOT NULL,
  `tour_booking_id` bigint(20) unsigned NOT NULL,
  `rating` tinyint(3) unsigned NOT NULL,
  `comment` text DEFAULT NULL,
  `highlights` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`highlights`)),
  `is_visible` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `reviews_tour_booking_id_unique` (`tour_booking_id`),
  KEY `reviews_rider_id_foreign` (`rider_id`),
  KEY `reviews_tour_id_foreign` (`tour_id`),
  CONSTRAINT `reviews_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_tour_booking_id_foreign` FOREIGN KEY (`tour_booking_id`) REFERENCES `tour_bookings` (`id`) ON DELETE CASCADE,
  CONSTRAINT `reviews_tour_id_foreign` FOREIGN KEY (`tour_id`) REFERENCES `tours` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ride_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `ride_types` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(32) NOT NULL,
  `name` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `seats` tinyint(3) unsigned NOT NULL DEFAULT 4,
  `base_fare` int(10) unsigned NOT NULL COMMENT 'Naira',
  `per_km` int(10) unsigned NOT NULL COMMENT 'Naira',
  `per_minute` int(10) unsigned NOT NULL COMMENT 'Naira',
  `minimum_fare` int(10) unsigned NOT NULL COMMENT 'Naira',
  `sort_order` smallint(5) unsigned NOT NULL DEFAULT 0,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `ride_types_code_unique` (`code`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `riders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `riders` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `first_name` varchar(255) DEFAULT NULL,
  `last_name` varchar(255) DEFAULT NULL,
  `email` varchar(255) DEFAULT NULL,
  `phone` varchar(32) DEFAULT NULL,
  `photo_url` varchar(255) DEFAULT NULL,
  `nationality` varchar(255) DEFAULT NULL,
  `home_currency` char(3) NOT NULL DEFAULT 'NGN',
  `traveller_type` enum('international','domestic','resident') DEFAULT NULL,
  `language` varchar(8) NOT NULL DEFAULT 'en',
  `accessibility` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`accessibility`)),
  `wallet_balance` int(10) unsigned NOT NULL DEFAULT 0 COMMENT 'Naira',
  `loyalty_points` int(10) unsigned NOT NULL DEFAULT 0,
  `referral_code` varchar(16) NOT NULL,
  `referred_by_id` bigint(20) unsigned DEFAULT NULL,
  `status` enum('active','suspended') NOT NULL DEFAULT 'active',
  `rating` decimal(3,2) DEFAULT NULL,
  `last_active_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  `deleted_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `riders_referral_code_unique` (`referral_code`),
  UNIQUE KEY `riders_email_unique` (`email`),
  UNIQUE KEY `riders_phone_unique` (`phone`),
  KEY `riders_referred_by_id_foreign` (`referred_by_id`),
  CONSTRAINT `riders_referred_by_id_foreign` FOREIGN KEY (`referred_by_id`) REFERENCES `riders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `saved_places`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `saved_places` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `rider_id` bigint(20) unsigned NOT NULL,
  `label` varchar(255) NOT NULL,
  `address` varchar(255) NOT NULL,
  `lat` decimal(10,7) NOT NULL,
  `lng` decimal(10,7) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `saved_places_rider_id_foreign` (`rider_id`),
  CONSTRAINT `saved_places_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sessions` (
  `id` varchar(255) NOT NULL,
  `user_id` bigint(20) unsigned DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `payload` longtext NOT NULL,
  `last_activity` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `sessions_user_id_index` (`user_id`),
  KEY `sessions_last_activity_index` (`last_activity`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `settings` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `key` varchar(255) NOT NULL,
  `value` text NOT NULL,
  `label` varchar(255) NOT NULL,
  `group` varchar(255) NOT NULL DEFAULT 'general',
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `settings_key_unique` (`key`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `shuttle_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `shuttle_bookings` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `reference` varchar(20) NOT NULL,
  `rider_id` bigint(20) unsigned NOT NULL,
  `driver_id` bigint(20) unsigned DEFAULT NULL,
  `direction` enum('airport_pickup','airport_dropoff') NOT NULL,
  `airport` varchar(255) NOT NULL DEFAULT 'Murtala Muhammed International (LOS)',
  `terminal` varchar(255) DEFAULT NULL,
  `flight_number` varchar(12) DEFAULT NULL,
  `flight_time` timestamp NULL DEFAULT NULL COMMENT 'Scheduled arrival or departure',
  `flight_status` enum('scheduled','on_time','delayed','landed','cancelled') NOT NULL DEFAULT 'scheduled',
  `pickup_at` timestamp NOT NULL,
  `address` varchar(255) NOT NULL COMMENT 'Hotel or home end of the trip',
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `ride_type_id` bigint(20) unsigned NOT NULL,
  `passengers` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `large_bags` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `small_bags` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `price` int(10) unsigned NOT NULL COMMENT 'Fixed price in naira',
  `driver_payout` int(10) unsigned NOT NULL DEFAULT 0,
  `meeting_point` varchar(255) DEFAULT NULL,
  `name_board` varchar(255) DEFAULT NULL,
  `notes` varchar(255) DEFAULT NULL,
  `payment_method` enum('card','wallet','bank_transfer') NOT NULL DEFAULT 'card',
  `payment_status` enum('pending','paid','refunded') NOT NULL DEFAULT 'pending',
  `status` enum('confirmed','driver_assigned','in_progress','completed','cancelled') NOT NULL DEFAULT 'confirmed',
  `driver_assigned_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `shuttle_bookings_reference_unique` (`reference`),
  KEY `shuttle_bookings_rider_id_foreign` (`rider_id`),
  KEY `shuttle_bookings_driver_id_foreign` (`driver_id`),
  KEY `shuttle_bookings_ride_type_id_foreign` (`ride_type_id`),
  CONSTRAINT `shuttle_bookings_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `shuttle_bookings_ride_type_id_foreign` FOREIGN KEY (`ride_type_id`) REFERENCES `ride_types` (`id`),
  CONSTRAINT `shuttle_bookings_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sos_alerts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sos_alerts` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `raised_by_type` varchar(255) NOT NULL,
  `raised_by_id` bigint(20) unsigned NOT NULL,
  `trip_id` bigint(20) unsigned DEFAULT NULL,
  `lat` decimal(10,7) DEFAULT NULL,
  `lng` decimal(10,7) DEFAULT NULL,
  `address` varchar(255) DEFAULT NULL,
  `status` enum('open','acknowledged','resolved') NOT NULL DEFAULT 'open',
  `handled_by` bigint(20) unsigned DEFAULT NULL,
  `acknowledged_at` timestamp NULL DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sos_alerts_raised_by_type_raised_by_id_index` (`raised_by_type`,`raised_by_id`),
  KEY `sos_alerts_trip_id_foreign` (`trip_id`),
  KEY `sos_alerts_handled_by_foreign` (`handled_by`),
  CONSTRAINT `sos_alerts_handled_by_foreign` FOREIGN KEY (`handled_by`) REFERENCES `admins` (`id`) ON DELETE SET NULL,
  CONSTRAINT `sos_alerts_trip_id_foreign` FOREIGN KEY (`trip_id`) REFERENCES `trips` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `support_messages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `support_messages` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `support_ticket_id` bigint(20) unsigned NOT NULL,
  `sender_type` varchar(255) NOT NULL,
  `sender_id` bigint(20) unsigned NOT NULL,
  `body` text NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `support_messages_support_ticket_id_foreign` (`support_ticket_id`),
  KEY `support_messages_sender_type_sender_id_index` (`sender_type`,`sender_id`),
  CONSTRAINT `support_messages_support_ticket_id_foreign` FOREIGN KEY (`support_ticket_id`) REFERENCES `support_tickets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `support_tickets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `support_tickets` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `reference` varchar(20) NOT NULL,
  `requester_type` varchar(255) NOT NULL,
  `requester_id` bigint(20) unsigned NOT NULL,
  `subject_type` varchar(255) DEFAULT NULL,
  `subject_id` bigint(20) unsigned DEFAULT NULL,
  `category` enum('lost_item','overcharge','fare_dispute','refund','driver_behaviour','rider_behaviour','vehicle_damage','accident','payout','account','other') NOT NULL,
  `subject_line` varchar(255) NOT NULL,
  `status` enum('open','in_review','awaiting_user','resolved') NOT NULL DEFAULT 'open',
  `priority` enum('low','normal','high','urgent') NOT NULL DEFAULT 'normal',
  `assigned_admin_id` bigint(20) unsigned DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `support_tickets_reference_unique` (`reference`),
  KEY `support_tickets_requester_type_requester_id_index` (`requester_type`,`requester_id`),
  KEY `support_tickets_subject_type_subject_id_index` (`subject_type`,`subject_id`),
  KEY `support_tickets_assigned_admin_id_foreign` (`assigned_admin_id`),
  CONSTRAINT `support_tickets_assigned_admin_id_foreign` FOREIGN KEY (`assigned_admin_id`) REFERENCES `admins` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tour_bookings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tour_bookings` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `reference` varchar(20) NOT NULL,
  `rider_id` bigint(20) unsigned NOT NULL,
  `tour_id` bigint(20) unsigned NOT NULL,
  `tour_slot_id` bigint(20) unsigned NOT NULL,
  `guests` tinyint(3) unsigned NOT NULL,
  `subtotal` int(10) unsigned NOT NULL,
  `addons` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`addons`)),
  `addons_total` int(10) unsigned NOT NULL DEFAULT 0,
  `ride_addon_price` int(10) unsigned NOT NULL DEFAULT 0,
  `ride_trip_id` bigint(20) unsigned DEFAULT NULL,
  `promo_code_id` bigint(20) unsigned DEFAULT NULL,
  `discount` int(10) unsigned NOT NULL DEFAULT 0,
  `total` int(10) unsigned NOT NULL,
  `payment_method` enum('card','wallet','bank_transfer') NOT NULL,
  `payment_status` enum('pending','paid','refunded','partially_refunded') NOT NULL DEFAULT 'pending',
  `refund_amount` int(10) unsigned NOT NULL DEFAULT 0,
  `status` enum('confirmed','checked_in','completed','cancelled') NOT NULL DEFAULT 'confirmed',
  `qr_token` varchar(40) NOT NULL,
  `company_name` varchar(255) DEFAULT NULL,
  `checked_in_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tour_bookings_reference_unique` (`reference`),
  UNIQUE KEY `tour_bookings_qr_token_unique` (`qr_token`),
  KEY `tour_bookings_rider_id_foreign` (`rider_id`),
  KEY `tour_bookings_tour_id_foreign` (`tour_id`),
  KEY `tour_bookings_tour_slot_id_foreign` (`tour_slot_id`),
  KEY `tour_bookings_ride_trip_id_foreign` (`ride_trip_id`),
  KEY `tour_bookings_promo_code_id_foreign` (`promo_code_id`),
  CONSTRAINT `tour_bookings_promo_code_id_foreign` FOREIGN KEY (`promo_code_id`) REFERENCES `promo_codes` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tour_bookings_ride_trip_id_foreign` FOREIGN KEY (`ride_trip_id`) REFERENCES `trips` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tour_bookings_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tour_bookings_tour_id_foreign` FOREIGN KEY (`tour_id`) REFERENCES `tours` (`id`),
  CONSTRAINT `tour_bookings_tour_slot_id_foreign` FOREIGN KEY (`tour_slot_id`) REFERENCES `tour_slots` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=79 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tour_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tour_categories` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `sort_order` smallint(5) unsigned NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tour_categories_slug_unique` (`slug`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tour_slots`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tour_slots` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `tour_id` bigint(20) unsigned NOT NULL,
  `starts_at` timestamp NOT NULL,
  `capacity` tinyint(3) unsigned NOT NULL,
  `booked` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `guide_driver_id` bigint(20) unsigned DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tour_slots_tour_id_starts_at_unique` (`tour_id`,`starts_at`),
  KEY `tour_slots_guide_driver_id_foreign` (`guide_driver_id`),
  CONSTRAINT `tour_slots_guide_driver_id_foreign` FOREIGN KEY (`guide_driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `tour_slots_tour_id_foreign` FOREIGN KEY (`tour_id`) REFERENCES `tours` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=226 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `tours`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `tours` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `partner_id` bigint(20) unsigned NOT NULL,
  `tour_category_id` bigint(20) unsigned NOT NULL,
  `title` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `description` text NOT NULL,
  `area` varchar(255) NOT NULL,
  `meeting_point` varchar(255) NOT NULL,
  `meeting_lat` decimal(10,7) DEFAULT NULL,
  `meeting_lng` decimal(10,7) DEFAULT NULL,
  `duration_minutes` smallint(5) unsigned NOT NULL,
  `price` int(10) unsigned NOT NULL COMMENT 'Naira per person',
  `min_group_size` tinyint(3) unsigned NOT NULL DEFAULT 1,
  `max_group_size` tinyint(3) unsigned NOT NULL DEFAULT 10,
  `languages` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`languages`)),
  `itinerary` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`itinerary`)),
  `inclusions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`inclusions`)),
  `exclusions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`exclusions`)),
  `addons` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Partner add-ons: code, name, price' CHECK (json_valid(`addons`)),
  `cancellation_policy` varchar(255) DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `wheelchair_accessible` tinyint(1) NOT NULL DEFAULT 0,
  `rating` decimal(3,2) DEFAULT NULL,
  `reviews_count` int(10) unsigned NOT NULL DEFAULT 0,
  `is_featured` tinyint(1) NOT NULL DEFAULT 0,
  `is_published` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tours_slug_unique` (`slug`),
  KEY `tours_partner_id_foreign` (`partner_id`),
  KEY `tours_tour_category_id_foreign` (`tour_category_id`),
  CONSTRAINT `tours_partner_id_foreign` FOREIGN KEY (`partner_id`) REFERENCES `partners` (`id`) ON DELETE CASCADE,
  CONSTRAINT `tours_tour_category_id_foreign` FOREIGN KEY (`tour_category_id`) REFERENCES `tour_categories` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `transactions` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `reference` varchar(32) NOT NULL,
  `owner_type` varchar(255) DEFAULT NULL,
  `owner_id` bigint(20) unsigned DEFAULT NULL,
  `subject_type` varchar(255) DEFAULT NULL,
  `subject_id` bigint(20) unsigned DEFAULT NULL,
  `type` enum('charge','refund','wallet_topup','wallet_payment','tip','driver_earning','commission','payout','cash_settlement','referral_credit') NOT NULL,
  `direction` enum('credit','debit') NOT NULL,
  `amount` int(10) unsigned NOT NULL COMMENT 'Naira',
  `method` enum('card','wallet','bank_transfer','cash','system') NOT NULL DEFAULT 'system',
  `status` enum('pending','succeeded','failed') NOT NULL DEFAULT 'succeeded',
  `description` varchar(255) DEFAULT NULL,
  `meta` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`meta`)),
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `transactions_reference_unique` (`reference`),
  KEY `transactions_owner_type_owner_id_index` (`owner_type`,`owner_id`),
  KEY `transactions_subject_type_subject_id_index` (`subject_type`,`subject_id`)
) ENGINE=InnoDB AUTO_INCREMENT=287 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `trips`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `trips` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `reference` varchar(20) NOT NULL,
  `rider_id` bigint(20) unsigned NOT NULL,
  `driver_id` bigint(20) unsigned DEFAULT NULL,
  `vehicle_id` bigint(20) unsigned DEFAULT NULL,
  `ride_type_id` bigint(20) unsigned NOT NULL,
  `status` enum('scheduled','requested','accepted','arrived','in_progress','completed','cancelled','no_show') NOT NULL DEFAULT 'requested',
  `pickup_address` varchar(255) NOT NULL,
  `pickup_lat` decimal(10,7) NOT NULL,
  `pickup_lng` decimal(10,7) NOT NULL,
  `dropoff_address` varchar(255) NOT NULL,
  `dropoff_lat` decimal(10,7) NOT NULL,
  `dropoff_lng` decimal(10,7) NOT NULL,
  `stops` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`stops`)),
  `scheduled_at` timestamp NULL DEFAULT NULL,
  `pin` char(4) NOT NULL,
  `distance_km` decimal(6,2) NOT NULL,
  `duration_minutes` smallint(5) unsigned NOT NULL,
  `surge_multiplier` decimal(3,2) NOT NULL DEFAULT 1.00,
  `fare_base` int(10) unsigned NOT NULL DEFAULT 0,
  `fare_distance` int(10) unsigned NOT NULL DEFAULT 0,
  `fare_time` int(10) unsigned NOT NULL DEFAULT 0,
  `fare_stops` int(10) unsigned NOT NULL DEFAULT 0,
  `tolls` int(10) unsigned NOT NULL DEFAULT 0,
  `discount` int(10) unsigned NOT NULL DEFAULT 0,
  `fare_total` int(10) unsigned NOT NULL COMMENT 'Naira charged to the rider, before tip',
  `tip` int(10) unsigned NOT NULL DEFAULT 0,
  `commission` int(10) unsigned NOT NULL DEFAULT 0,
  `driver_earnings` int(10) unsigned NOT NULL DEFAULT 0,
  `cancellation_fee` int(10) unsigned NOT NULL DEFAULT 0,
  `promo_code_id` bigint(20) unsigned DEFAULT NULL,
  `payment_method` enum('card','wallet','bank_transfer','cash') NOT NULL DEFAULT 'card',
  `payment_status` enum('pending','authorised','paid','refunded','failed') NOT NULL DEFAULT 'pending',
  `cancelled_by` enum('rider','driver','admin') DEFAULT NULL,
  `cancellation_reason` varchar(255) DEFAULT NULL,
  `rider_rating` tinyint(3) unsigned DEFAULT NULL COMMENT 'Given by the driver',
  `driver_rating` tinyint(3) unsigned DEFAULT NULL COMMENT 'Given by the rider',
  `rider_feedback` varchar(255) DEFAULT NULL,
  `driver_feedback` varchar(255) DEFAULT NULL,
  `declined_driver_ids` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`declined_driver_ids`)),
  `share_token` varchar(32) DEFAULT NULL,
  `accepted_at` timestamp NULL DEFAULT NULL,
  `arrived_at` timestamp NULL DEFAULT NULL,
  `started_at` timestamp NULL DEFAULT NULL,
  `completed_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `trips_reference_unique` (`reference`),
  UNIQUE KEY `trips_share_token_unique` (`share_token`),
  KEY `trips_rider_id_foreign` (`rider_id`),
  KEY `trips_driver_id_foreign` (`driver_id`),
  KEY `trips_vehicle_id_foreign` (`vehicle_id`),
  KEY `trips_ride_type_id_foreign` (`ride_type_id`),
  KEY `trips_status_created_at_index` (`status`,`created_at`),
  CONSTRAINT `trips_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE SET NULL,
  CONSTRAINT `trips_ride_type_id_foreign` FOREIGN KEY (`ride_type_id`) REFERENCES `ride_types` (`id`),
  CONSTRAINT `trips_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE,
  CONSTRAINT `trips_vehicle_id_foreign` FOREIGN KEY (`vehicle_id`) REFERENCES `vehicles` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=94 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `vehicles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `vehicles` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `driver_id` bigint(20) unsigned NOT NULL,
  `make` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `year` smallint(5) unsigned NOT NULL,
  `colour` varchar(255) NOT NULL,
  `plate_number` varchar(16) NOT NULL,
  `seats` tinyint(3) unsigned NOT NULL DEFAULT 4,
  `ride_types` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'Ride type codes this vehicle qualifies for' CHECK (json_valid(`ride_types`)),
  `wheelchair_accessible` tinyint(1) NOT NULL DEFAULT 0,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `is_active` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `vehicles_plate_number_unique` (`plate_number`),
  KEY `vehicles_driver_id_foreign` (`driver_id`),
  CONSTRAINT `vehicles_driver_id_foreign` FOREIGN KEY (`driver_id`) REFERENCES `drivers` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `waitlist_signups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `waitlist_signups` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `source` varchar(32) NOT NULL DEFAULT 'website',
  `ip_address` varchar(45) DEFAULT NULL,
  `invited_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `waitlist_signups_email_unique` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `wishlist_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `wishlist_items` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `rider_id` bigint(20) unsigned NOT NULL,
  `item_type` varchar(255) NOT NULL,
  `item_id` bigint(20) unsigned NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `wishlist_items_rider_id_item_type_item_id_unique` (`rider_id`,`item_type`,`item_id`),
  KEY `wishlist_items_item_type_item_id_index` (`item_type`,`item_id`),
  CONSTRAINT `wishlist_items_rider_id_foreign` FOREIGN KEY (`rider_id`) REFERENCES `riders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `zones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `zones` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `center_lat` decimal(10,7) NOT NULL,
  `center_lng` decimal(10,7) NOT NULL,
  `radius_km` decimal(5,2) NOT NULL,
  `surge_multiplier` decimal(3,2) NOT NULL DEFAULT 1.00,
  `is_service_area` tinyint(1) NOT NULL DEFAULT 1,
  `is_active` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;





LOCK TABLES `admins` WRITE;
/*!40000 ALTER TABLE `admins` DISABLE KEYS */;
INSERT INTO `admins` VALUES (1,'Cabo Admin','admin@caboapp.online','$2y$12$.JvGeVDgN/fJGXuUFDd1huG.8Psf8EpIIpxtJtMML9eZwtS6heNZy','super_admin',1,NULL,NULL,'2026-10-19 16:15:19','2026-10-19 16:15:19');
INSERT INTO `admins` VALUES (2,'Ngozi Adeyemi','ops@caboapp.online','$2y$12$DyJXoxUshNMYI5wAyne7yuCf8ahbuvpeyiQT0tZwp0tpwaNBNxWIC','operations',1,NULL,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `admins` VALUES (3,'Kelechi Eze','support@caboapp.online','$2y$12$EQCDpOuVFZbwjbjSZwiw2uQC7VZa9zR/f4wIzyZOInc/NF8zZoPau','support',1,NULL,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `admins` VALUES (4,'Funke Balogun','finance@caboapp.online','$2y$12$TUcBfB1PGO/TVGubWJwhFefqfsS2Ard6GDkwW5CQ/iLECp3vRHLtq','finance',1,NULL,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `admins` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `app_notifications` WRITE;
/*!40000 ALTER TABLE `app_notifications` DISABLE KEYS */;
INSERT INTO `app_notifications` VALUES (1,'rider',1,'trip','Emeka is on the way','Silver Toyota Corolla · LND 482 KJ · arriving in 4 min',NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `app_notifications` VALUES (2,'rider',1,'shuttle','Airport pickup confirmed','BA75 arriving Thu 22 Oct at 16:35. Emeka will meet you at Pillar 3.',NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `app_notifications` VALUES (3,'rider',1,'promo','20% off your first tour','Use WELCOME20 at checkout. Up to ₦5,000 off.',NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `app_notifications` VALUES (4,'driver',1,'trip','New trip request','Pickup at Eko Hotel & Suites, Victoria Island',NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `app_notifications` VALUES (5,'driver',1,'payout','Weekly payout sent','Your weekly earnings have been paid to GTBank.',NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `app_notifications` VALUES (6,'driver',1,'document','Insurance expires soon','Upload your new insurance certificate before it expires.',NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `app_notifications` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `attractions` WRITE;
/*!40000 ALTER TABLE `attractions` DISABLE KEYS */;
INSERT INTO `attractions` VALUES (1,'Lekki Conservation Centre','lekki-conservation-centre','Nature','Lekki','A 78-hectare nature reserve with the longest canopy walkway in Africa, monkeys, crocodiles and wetland birds.','Km 19 Lekki–Epe Expressway',6.4413000,3.5357000,'8:00 – 17:00',3000,'[\"Arrive before 10:00 to beat the heat\",\"The canopy walkway costs extra and closes at 16:00\",\"Wear trainers, the boardwalk can be slippery\"]','Stay on the marked boardwalks. Do not feed the monkeys.','/images/places/lekki-conservation-centre.jpg',4.80,2300,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `attractions` VALUES (2,'Nike Art Gallery','nike-art-gallery','Art','Lekki','One of the largest art galleries in West Africa, with over 8,000 works across five floors.','2 Elegushi Road, Lekki Phase 1',6.4371000,3.4848000,'10:00 – 18:00',0,'[\"Entry is free, but prices for artworks are negotiable\",\"Ask about the adire textile workshop\"]','Keep bags closed in busy rooms.','/images/places/nike-art-gallery.jpg',4.70,1800,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `attractions` VALUES (3,'Tarkwa Bay Beach','tarkwa-bay-beach','Beaches','Lagos Harbour','A sheltered beach across the harbour, popular for swimming and surfing, reached only by boat.','Tarkwa Bay, reached by boat from Tarzan Jetty',6.4011000,3.3963000,'Open daily',2000,'[\"Boats leave from Tarzan Jetty in Victoria Island\",\"Bring cash for chairs and food\",\"Head back before 17:00\"]','Always wear a life jacket on the boat. Swim only where locals swim.','/images/places/tarkwa-bay.jpg',4.60,1100,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `attractions` VALUES (4,'Freedom Park','freedom-park','History','Lagos Island','A memorial and leisure park on the site of the old Broad Street colonial prison, with live music most evenings.','Broad Street, Lagos Island',6.4527000,3.3937000,'9:00 – 22:00',1000,'[\"Check the events board for live music nights\",\"The food court is good value\"]','Lagos Island traffic is heavy on weekdays; allow extra time.','/images/places/freedom-park.jpg',4.50,940,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `attractions` VALUES (5,'Lekki–Ikoyi Link Bridge','lekki-ikoyi-link-bridge','Landmarks','Ikoyi','A cable-stayed toll bridge linking Ikoyi and Lekki, best seen at sunset when it is lit up.','Lekki–Ikoyi Link Bridge',6.4449000,3.4395000,'Open daily',0,'[\"Pedestrians can walk the bridge early in the morning\",\"Sunset photos are best from the Ikoyi end\"]','Do not stop vehicles on the bridge.','/images/places/lekki-ikoyi-bridge.jpg',4.60,3100,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `attractions` VALUES (6,'Elegushi Beach','elegushi-beach','Beaches','Lekki','A private beach with music, food stalls, horse rides and a lively crowd at weekends.','Elegushi Royal Beach, Lekki Phase 1',6.4322000,3.4930000,'9:00 – 19:00',2000,'[\"Busiest on Sunday afternoons\",\"Agree prices for chairs and horse rides first\"]','Strong currents: do not swim far from the shore.',NULL,4.20,1500,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `attractions` VALUES (7,'Kalakuta Republic Museum','kalakuta-republic-museum','History','Ikeja','The former home of Afrobeat pioneer Fela Kuti, now a museum with his clothes, instruments and a rooftop bar.','7 Gbemisola Street, Ikeja',6.5915000,3.3517000,'10:00 – 18:00',2000,'[\"Combine with an evening at the New Afrika Shrine\"]',NULL,NULL,4.40,420,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `attractions` VALUES (8,'Terra Kulture','terra-kulture','Art','Victoria Island','An arts centre with a theatre, gallery, bookshop and Nigerian restaurant.','1376 Tiamiyu Savage Street, Victoria Island',6.4335000,3.4229000,'9:00 – 21:00',0,'[\"Book theatre tickets in advance\",\"Try the restaurant for lunch\"]',NULL,NULL,4.60,860,1,'2026-09-28','2026-10-19 16:15:21','2026-10-19 16:15:21');
/*!40000 ALTER TABLE `attractions` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `driver_documents` WRITE;
/*!40000 ALTER TABLE `driver_documents` DISABLE KEYS */;
INSERT INTO `driver_documents` VALUES (1,1,NULL,'drivers_licence','Driver\'s licence','documents/driver-1/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (2,1,NULL,'national_id','National ID (NIN)','documents/driver-1/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (3,1,NULL,'proof_of_address','Proof of address','documents/driver-1/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (4,1,NULL,'lasdri_card','LASDRI card','documents/driver-1/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (5,1,NULL,'selfie','Selfie','documents/driver-1/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (6,1,1,'vehicle_licence','Vehicle licence','documents/driver-1/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (7,1,1,'roadworthiness','Roadworthiness certificate','documents/driver-1/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (8,1,1,'insurance','Insurance certificate','documents/driver-1/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (9,1,1,'vehicle_photo','Vehicle photo','documents/driver-1/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (10,2,NULL,'drivers_licence','Driver\'s licence','documents/driver-2/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (11,2,NULL,'national_id','National ID (NIN)','documents/driver-2/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (12,2,NULL,'proof_of_address','Proof of address','documents/driver-2/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (13,2,NULL,'lasdri_card','LASDRI card','documents/driver-2/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (14,2,NULL,'selfie','Selfie','documents/driver-2/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (15,2,2,'vehicle_licence','Vehicle licence','documents/driver-2/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (16,2,2,'roadworthiness','Roadworthiness certificate','documents/driver-2/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (17,2,2,'insurance','Insurance certificate','documents/driver-2/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (18,2,2,'vehicle_photo','Vehicle photo','documents/driver-2/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (19,3,NULL,'drivers_licence','Driver\'s licence','documents/driver-3/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (20,3,NULL,'national_id','National ID (NIN)','documents/driver-3/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (21,3,NULL,'proof_of_address','Proof of address','documents/driver-3/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (22,3,NULL,'lasdri_card','LASDRI card','documents/driver-3/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (23,3,NULL,'selfie','Selfie','documents/driver-3/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (24,3,3,'vehicle_licence','Vehicle licence','documents/driver-3/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (25,3,3,'roadworthiness','Roadworthiness certificate','documents/driver-3/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (26,3,3,'insurance','Insurance certificate','documents/driver-3/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (27,3,3,'vehicle_photo','Vehicle photo','documents/driver-3/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (28,4,NULL,'drivers_licence','Driver\'s licence','documents/driver-4/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (29,4,NULL,'national_id','National ID (NIN)','documents/driver-4/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (30,4,NULL,'proof_of_address','Proof of address','documents/driver-4/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (31,4,NULL,'lasdri_card','LASDRI card','documents/driver-4/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (32,4,NULL,'selfie','Selfie','documents/driver-4/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (33,4,4,'vehicle_licence','Vehicle licence','documents/driver-4/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (34,4,4,'roadworthiness','Roadworthiness certificate','documents/driver-4/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (35,4,4,'insurance','Insurance certificate','documents/driver-4/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (36,4,4,'vehicle_photo','Vehicle photo','documents/driver-4/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (37,5,NULL,'drivers_licence','Driver\'s licence','documents/driver-5/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (38,5,NULL,'national_id','National ID (NIN)','documents/driver-5/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (39,5,NULL,'proof_of_address','Proof of address','documents/driver-5/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (40,5,NULL,'lasdri_card','LASDRI card','documents/driver-5/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (41,5,NULL,'selfie','Selfie','documents/driver-5/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (42,5,5,'vehicle_licence','Vehicle licence','documents/driver-5/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (43,5,5,'roadworthiness','Roadworthiness certificate','documents/driver-5/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (44,5,5,'insurance','Insurance certificate','documents/driver-5/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (45,5,5,'vehicle_photo','Vehicle photo','documents/driver-5/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (46,6,NULL,'drivers_licence','Driver\'s licence','documents/driver-6/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (47,6,NULL,'national_id','National ID (NIN)','documents/driver-6/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (48,6,NULL,'proof_of_address','Proof of address','documents/driver-6/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (49,6,NULL,'lasdri_card','LASDRI card','documents/driver-6/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (50,6,NULL,'selfie','Selfie','documents/driver-6/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (51,6,6,'vehicle_licence','Vehicle licence','documents/driver-6/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (52,6,6,'roadworthiness','Roadworthiness certificate','documents/driver-6/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (53,6,6,'insurance','Insurance certificate','documents/driver-6/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (54,6,6,'vehicle_photo','Vehicle photo','documents/driver-6/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (55,7,NULL,'drivers_licence','Driver\'s licence','documents/driver-7/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (56,7,NULL,'national_id','National ID (NIN)','documents/driver-7/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (57,7,NULL,'proof_of_address','Proof of address','documents/driver-7/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (58,7,NULL,'lasdri_card','LASDRI card','documents/driver-7/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (59,7,NULL,'selfie','Selfie','documents/driver-7/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (60,7,7,'vehicle_licence','Vehicle licence','documents/driver-7/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (61,7,7,'roadworthiness','Roadworthiness certificate','documents/driver-7/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (62,7,7,'insurance','Insurance certificate','documents/driver-7/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (63,7,7,'vehicle_photo','Vehicle photo','documents/driver-7/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (64,8,NULL,'drivers_licence','Driver\'s licence','documents/driver-8/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (65,8,NULL,'national_id','National ID (NIN)','documents/driver-8/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (66,8,NULL,'proof_of_address','Proof of address','documents/driver-8/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (67,8,NULL,'lasdri_card','LASDRI card','documents/driver-8/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (68,8,NULL,'selfie','Selfie','documents/driver-8/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (69,8,8,'vehicle_licence','Vehicle licence','documents/driver-8/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (70,8,8,'roadworthiness','Roadworthiness certificate','documents/driver-8/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (71,8,8,'insurance','Insurance certificate','documents/driver-8/insurance.jpg','approved',NULL,'2026-10-31',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (72,8,8,'vehicle_photo','Vehicle photo','documents/driver-8/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (73,9,NULL,'drivers_licence','Driver\'s licence','documents/driver-9/drivers_licence.jpg','pending',NULL,'2028-10-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (74,9,NULL,'national_id','National ID (NIN)','documents/driver-9/national_id.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (75,9,NULL,'proof_of_address','Proof of address','documents/driver-9/proof_of_address.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (76,9,NULL,'lasdri_card','LASDRI card','documents/driver-9/lasdri_card.jpg','pending',NULL,'2027-06-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (77,9,NULL,'selfie','Selfie','documents/driver-9/selfie.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (78,9,9,'vehicle_licence','Vehicle licence','documents/driver-9/vehicle_licence.jpg','pending',NULL,'2027-06-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (79,9,9,'roadworthiness','Roadworthiness certificate','documents/driver-9/roadworthiness.jpg','pending',NULL,'2027-06-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (80,9,9,'insurance','Insurance certificate','documents/driver-9/insurance.jpg','pending',NULL,'2027-08-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (81,9,9,'vehicle_photo','Vehicle photo','documents/driver-9/vehicle_photo.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (82,10,NULL,'drivers_licence','Driver\'s licence','documents/driver-10/drivers_licence.jpg','pending',NULL,'2028-10-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (83,10,NULL,'national_id','National ID (NIN)','documents/driver-10/national_id.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (84,10,NULL,'proof_of_address','Proof of address','documents/driver-10/proof_of_address.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (85,10,NULL,'lasdri_card','LASDRI card','documents/driver-10/lasdri_card.jpg','pending',NULL,'2027-06-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (86,10,NULL,'selfie','Selfie','documents/driver-10/selfie.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (87,10,10,'vehicle_licence','Vehicle licence','documents/driver-10/vehicle_licence.jpg','pending',NULL,'2027-06-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (88,10,10,'roadworthiness','Roadworthiness certificate','documents/driver-10/roadworthiness.jpg','rejected','The certificate photo is blurred. Please upload a clear photo of the whole page.','2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (89,10,10,'insurance','Insurance certificate','documents/driver-10/insurance.jpg','pending',NULL,'2027-08-19',NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (90,10,10,'vehicle_photo','Vehicle photo','documents/driver-10/vehicle_photo.jpg','pending',NULL,NULL,NULL,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (91,12,NULL,'drivers_licence','Driver\'s licence','documents/driver-12/drivers_licence.jpg','approved',NULL,'2028-10-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (92,12,NULL,'national_id','National ID (NIN)','documents/driver-12/national_id.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (93,12,NULL,'proof_of_address','Proof of address','documents/driver-12/proof_of_address.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (94,12,NULL,'lasdri_card','LASDRI card','documents/driver-12/lasdri_card.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (95,12,NULL,'selfie','Selfie','documents/driver-12/selfie.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (96,12,11,'vehicle_licence','Vehicle licence','documents/driver-12/vehicle_licence.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (97,12,11,'roadworthiness','Roadworthiness certificate','documents/driver-12/roadworthiness.jpg','approved',NULL,'2027-06-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (98,12,11,'insurance','Insurance certificate','documents/driver-12/insurance.jpg','approved',NULL,'2027-08-19',1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `driver_documents` VALUES (99,12,11,'vehicle_photo','Vehicle photo','documents/driver-12/vehicle_photo.jpg','approved',NULL,NULL,1,'2026-07-19 16:15:21','2026-10-19 16:15:21','2026-10-19 16:15:21');
/*!40000 ALTER TABLE `driver_documents` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `drivers` WRITE;
/*!40000 ALTER TABLE `drivers` DISABLE KEYS */;
INSERT INTO `drivers` VALUES (1,'Emeka','Nwosu','emeka.nwosu@example.com','+2348012345678',NULL,'1998-10-19','Surulere, Lagos','[\"English\",\"Yoruba\",\"Pidgin\"]','independent',NULL,'approved',NULL,'standard',1,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',1,6.4300000,3.4210000,'2026-10-19 16:14:21','{\"ride_types\":[\"economy\",\"comfort\"],\"jobs\":[\"rides\",\"shuttles\",\"tours\"],\"destination_filter\":null}',4.92,89.40,2.90,'GTBank','0123456789','EMEKA NWOSU',48500,500,'DRVEME01','2026-07-19 16:15:21','2026-06-19 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (2,'Bola','Ajayi','bola.ajayi@example.com','+2348012345679',NULL,'1997-10-02','Ikoyi, Lagos','[\"English\",\"Igbo\"]','independent',NULL,'approved',NULL,'premium',0,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',1,6.4540000,3.4350000,'2026-10-19 16:13:21','{\"ride_types\":[\"premium\",\"comfort\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',4.25,85.80,5.70,'Access Bank','0123457900','BOLA AJAYI',65000,1500,'DRVBOL02','2026-07-20 16:15:21','2026-06-24 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (3,'Chukwudi','Okeke','chukwudi.okeke@example.com','+2348012345680',NULL,'1996-09-15','Lekki, Lagos','[\"English\",\"Hausa\"]','independent',NULL,'approved',NULL,'standard',0,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',1,6.4470000,3.4730000,'2026-10-19 16:12:21','{\"ride_types\":[\"suv\",\"comfort\",\"economy\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',4.80,97.50,4.60,'First Bank','0123459011','CHUKWUDI OKEKE',32000,2500,'DRVCHU03','2026-07-21 16:15:21','2026-06-29 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (4,'Yusuf','Abdullahi','yusuf.abdullahi@example.com','+2348012345681',NULL,'1995-08-29','Yaba, Lagos','[\"English\",\"Yoruba\",\"Pidgin\"]','fleet',1,'approved',NULL,'standard',0,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',1,6.5090000,3.3710000,'2026-10-19 16:11:21','{\"ride_types\":[\"economy\",\"comfort\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',4.57,85.00,2.40,'Zenith Bank','0123460122','YUSUF ABDULLAHI',53000,4000,'DRVYUS04','2026-07-22 16:15:21','2026-07-04 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (5,'Kehinde','Ogunbiyi','kehinde.ogunbiyi@example.com','+2348012345682',NULL,'1994-08-12','Surulere, Lagos','[\"English\",\"Igbo\"]','independent',NULL,'approved',NULL,'standard',1,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',1,6.4970000,3.3480000,'2026-10-19 16:10:21','{\"ride_types\":[\"economy\",\"comfort\"],\"jobs\":[\"rides\",\"shuttles\",\"tours\"],\"destination_filter\":null}',4.14,90.90,1.30,'UBA','0123461233','KEHINDE OGUNBIYI',84000,0,'DRVKEH05','2026-07-23 16:15:21','2026-07-09 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (6,'Olumide','Fashola','olumide.fashola@example.com','+2348012345683',NULL,'1993-07-26','Victoria Island, Lagos','[\"English\",\"Hausa\"]','independent',NULL,'approved',NULL,'premium',0,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',1,6.4280000,3.4220000,'2026-10-19 16:09:21','{\"ride_types\":[\"premium\",\"suv\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',4.80,92.60,4.80,'Kuda','0123462344','OLUMIDE FASHOLA',33000,2500,'DRVOLU06','2026-07-24 16:15:21','2026-07-14 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (7,'Ifeanyi','Obi','ifeanyi.obi@example.com','+2348012345684',NULL,'1992-07-09','Ikoyi, Lagos','[\"English\",\"Yoruba\",\"Pidgin\"]','fleet',2,'approved',NULL,'standard',0,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',0,6.4550000,3.4340000,'2026-10-19 16:08:21','{\"ride_types\":[\"economy\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',4.57,85.60,5.30,'GTBank','0123463455','IFEANYI OBI',72000,6000,'DRVIFE07','2026-07-25 16:15:21','2026-07-19 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (8,'Halima','Sani','halima.sani@example.com','+2348012345685',NULL,'1991-06-22','Lekki, Lagos','[\"English\",\"Igbo\"]','independent',NULL,'approved',NULL,'standard',0,1,1,'2026-08-19 16:15:21','Cabo Driver Hub, 21 Ikorodu Road, Yaba',0,6.4480000,3.4710000,'2026-10-19 16:07:21','{\"ride_types\":[\"economy\",\"comfort\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',4.38,83.30,1.50,'Access Bank','0123464566','HALIMA SANI',72000,0,'DRVHAL08','2026-07-26 16:15:21','2026-07-24 16:15:21','2026-10-19 16:15:22',NULL);
INSERT INTO `drivers` VALUES (9,'Segun','Adeola','segun.adeola@example.com','+2348012345686',NULL,'1990-06-05','Yaba, Lagos','[\"English\",\"Hausa\"]','independent',NULL,'pending_review',NULL,'standard',0,0,1,'2026-10-21 10:00:00','Cabo Driver Hub, 21 Ikorodu Road, Yaba',0,NULL,NULL,NULL,'{\"ride_types\":[\"economy\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',NULL,100.00,0.00,'First Bank','0123465677','SEGUN ADEOLA',0,0,'DRVSEG09',NULL,'2026-07-29 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `drivers` VALUES (10,'Precious','Etim','precious.etim@example.com','+2348012345687',NULL,'1989-05-19','Surulere, Lagos','[\"English\",\"Yoruba\",\"Pidgin\"]','independent',NULL,'pending_review',NULL,'standard',0,0,1,'2026-10-21 10:00:00','Cabo Driver Hub, 21 Ikorodu Road, Yaba',0,NULL,NULL,NULL,'{\"ride_types\":[\"suv\",\"economy\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',NULL,100.00,0.00,'Zenith Bank','0123466788','PRECIOUS ETIM',0,0,'DRVPRE10',NULL,'2026-08-03 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `drivers` VALUES (11,'Musa','Ibrahim','musa.ibrahim@example.com','+2348012345688',NULL,'1988-05-02','Ikeja, Lagos','[\"English\",\"Igbo\"]','independent',NULL,'applicant',NULL,'standard',0,0,0,NULL,NULL,0,NULL,NULL,NULL,'{\"ride_types\":[],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',NULL,100.00,0.00,NULL,NULL,NULL,0,0,'DRVMUS11',NULL,'2026-08-08 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `drivers` VALUES (12,'Victor','Eze','victor.eze@example.com','+2348012345689',NULL,'1987-04-15','Ajah, Lagos','[\"English\",\"Hausa\"]','independent',NULL,'suspended','Repeated rider complaints about route deviation. Under review.','standard',0,1,1,NULL,'Cabo Driver Hub, 21 Ikorodu Road, Yaba',0,NULL,NULL,NULL,'{\"ride_types\":[\"economy\"],\"jobs\":[\"rides\",\"shuttles\"],\"destination_filter\":null}',4.21,90.00,5.20,'Kuda','0123469010','VICTOR EZE',0,23500,'DRVVIC12','2026-07-30 16:15:21','2026-08-13 16:15:21','2026-10-19 16:15:21',NULL);
/*!40000 ALTER TABLE `drivers` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `emergency_contacts` WRITE;
/*!40000 ALTER TABLE `emergency_contacts` DISABLE KEYS */;
INSERT INTO `emergency_contacts` VALUES (1,1,'Funmilayo Bakare','+447700900987','Sister',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `emergency_contacts` VALUES (2,1,'Kunle Bakare','+2348023456789','Cousin',0,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `emergency_contacts` VALUES (3,2,'Chinedu Okafor','+2348034445566','Husband',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
/*!40000 ALTER TABLE `emergency_contacts` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `fleet_partners` WRITE;
/*!40000 ALTER TABLE `fleet_partners` DISABLE KEYS */;
INSERT INTO `fleet_partners` VALUES (1,'Eko Fleet Services','Surulere','Bisi Lawal','+2348031110001','hello@ekofleet.ng',1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `fleet_partners` VALUES (2,'Island Wheels Ltd','Victoria Island','Chidi Obi','+2348031110002','ops@islandwheels.ng',1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `fleet_partners` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `migrations` WRITE;
/*!40000 ALTER TABLE `migrations` DISABLE KEYS */;
INSERT INTO `migrations` VALUES (1,'0001_01_01_000000_create_admins_table',1);
INSERT INTO `migrations` VALUES (2,'0001_01_01_000001_create_cache_table',1);
INSERT INTO `migrations` VALUES (3,'0001_01_01_000002_create_jobs_table',1);
INSERT INTO `migrations` VALUES (4,'2026_10_19_154311_create_personal_access_tokens_table',1);
INSERT INTO `migrations` VALUES (5,'2026_10_20_000001_create_rider_tables',1);
INSERT INTO `migrations` VALUES (6,'2026_10_20_000002_create_driver_tables',1);
INSERT INTO `migrations` VALUES (7,'2026_10_20_000003_create_pricing_and_trip_tables',1);
INSERT INTO `migrations` VALUES (8,'2026_10_20_000004_create_tour_and_explore_tables',1);
INSERT INTO `migrations` VALUES (9,'2026_10_20_000005_create_payment_and_support_tables',1);
/*!40000 ALTER TABLE `migrations` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `partners` WRITE;
/*!40000 ALTER TABLE `partners` DISABLE KEYS */;
INSERT INTO `partners` VALUES (1,'Eko Nature Trails','tour_operator','Adaeze Nwankwo','bookings@ekonaturetrails.ng','+2348021234501','RC 1456721','approved',15.00,'GTBank','0177777771','Eko Nature Trails','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `partners` VALUES (2,'Funmi Island Tours','tour_operator','Funmi Ogunleye','hello@funmiisland.ng','+2348021234502','RC 1622093','approved',15.00,'GTBank','0177777772','Funmi Island Tours','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `partners` VALUES (3,'Eko Heritage Tours','tour_operator','Segun Akinola','walks@ekoheritage.ng','+2348021234503','RC 1388410','approved',15.00,'GTBank','0177777773','Eko Heritage Tours','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `partners` VALUES (4,'Taste of Eko','tour_operator','Ifeoma Chukwu','eat@tasteofeko.ng','+2348021234504','RC 1709155','approved',15.00,'GTBank','0177777774','Taste of Eko','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `partners` VALUES (5,'Lagos After Dark','tour_operator','Tobi Bankole','nights@lagosafterdark.ng','+2348021234505','RC 1811902','approved',15.00,'GTBank','0177777775','Lagos After Dark','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `partners` VALUES (6,'Badagry Roots Guides','guide','Kunle Mobolaji','kunle@badagryroots.ng','+2348021234506',NULL,'pending',15.00,'GTBank','0177777776','Badagry Roots Guides','2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `partners` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `payouts` WRITE;
/*!40000 ALTER TABLE `payouts` DISABLE KEYS */;
INSERT INTO `payouts` VALUES (1,'PO-VGE48W',1,'weekly',127000,0,'2026-10-12','2026-10-18','GTBank','0123456789','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (2,'PO-8JQUS2',1,'weekly',77000,0,'2026-10-05','2026-10-11','GTBank','0123456789','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (3,'PO-ADDPLX',1,'weekly',81000,0,'2026-09-28','2026-10-04','GTBank','0123456789','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (4,'PO-B3IOQG',1,'weekly',130000,0,'2026-09-21','2026-09-27','GTBank','0123456789','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (5,'PO-FX9DBL',2,'weekly',110000,0,'2026-10-12','2026-10-18','Access Bank','0123457900','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (6,'PO-SGO0YS',2,'weekly',49000,0,'2026-10-05','2026-10-11','Access Bank','0123457900','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (7,'PO-JS1SOX',2,'weekly',86000,0,'2026-09-28','2026-10-04','Access Bank','0123457900','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (8,'PO-2O7H5M',2,'weekly',76000,0,'2026-09-21','2026-09-27','Access Bank','0123457900','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (9,'PO-ZH0NG8',3,'weekly',66000,0,'2026-10-12','2026-10-18','First Bank','0123459011','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (10,'PO-5Z7T3Y',3,'weekly',71000,0,'2026-10-05','2026-10-11','First Bank','0123459011','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (11,'PO-QWWEM7',3,'weekly',125000,0,'2026-09-28','2026-10-04','First Bank','0123459011','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (12,'PO-LRLEE6',3,'weekly',77000,0,'2026-09-21','2026-09-27','First Bank','0123459011','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (13,'PO-7K9ED7',4,'weekly',50000,0,'2026-10-12','2026-10-18','Zenith Bank','0123460122','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (14,'PO-4XWAQ6',4,'weekly',97000,0,'2026-10-05','2026-10-11','Zenith Bank','0123460122','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (15,'PO-UIMS1W',4,'weekly',76000,0,'2026-09-28','2026-10-04','Zenith Bank','0123460122','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (16,'PO-PUN0VZ',4,'weekly',114000,0,'2026-09-21','2026-09-27','Zenith Bank','0123460122','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (17,'PO-WDSI90',5,'weekly',100000,0,'2026-10-12','2026-10-18','UBA','0123461233','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (18,'PO-EGYIRO',5,'weekly',81000,0,'2026-10-05','2026-10-11','UBA','0123461233','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (19,'PO-NPADCQ',5,'weekly',114000,0,'2026-09-28','2026-10-04','UBA','0123461233','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (20,'PO-DCJD3S',5,'weekly',45000,0,'2026-09-21','2026-09-27','UBA','0123461233','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (21,'PO-3ZOIEH',6,'weekly',76000,0,'2026-10-12','2026-10-18','Kuda','0123462344','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (22,'PO-QGYRMR',6,'weekly',55000,0,'2026-10-05','2026-10-11','Kuda','0123462344','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (23,'PO-T9ZLRI',6,'weekly',84000,0,'2026-09-28','2026-10-04','Kuda','0123462344','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (24,'PO-UAERAY',6,'weekly',66000,0,'2026-09-21','2026-09-27','Kuda','0123462344','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (25,'PO-N1YUJA',7,'weekly',126000,0,'2026-10-12','2026-10-18','GTBank','0123463455','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (26,'PO-IFUUWD',7,'weekly',92000,0,'2026-10-05','2026-10-11','GTBank','0123463455','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (27,'PO-LUOVJ5',7,'weekly',46000,0,'2026-09-28','2026-10-04','GTBank','0123463455','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (28,'PO-SNDUOE',7,'weekly',55000,0,'2026-09-21','2026-09-27','GTBank','0123463455','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (29,'PO-TYBQRO',8,'weekly',93000,0,'2026-10-12','2026-10-18','Access Bank','0123464566','paid',4,'2026-10-20 10:00:00','2026-10-19 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (30,'PO-1QKORP',8,'weekly',104000,0,'2026-10-05','2026-10-11','Access Bank','0123464566','paid',4,'2026-10-13 10:00:00','2026-10-12 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (31,'PO-FS9G1N',8,'weekly',128000,0,'2026-09-28','2026-10-04','Access Bank','0123464566','paid',4,'2026-10-06 10:00:00','2026-10-05 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (32,'PO-CNVDYV',8,'weekly',88000,0,'2026-09-21','2026-09-27','Access Bank','0123464566','paid',4,'2026-09-29 10:00:00','2026-09-28 00:00:00','2026-10-19 16:15:22');
INSERT INTO `payouts` VALUES (33,'PO-6UQFAY',1,'instant',19700,300,NULL,NULL,'GTBank','0123456789','pending',NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `payouts` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `promo_codes` WRITE;
/*!40000 ALTER TABLE `promo_codes` DISABLE KEYS */;
INSERT INTO `promo_codes` VALUES (1,'WELCOME20','20% off your first booking, up to ₦5,000','percent',20,5000,'all',1,NULL,0,'2026-09-19 00:00:00','2027-04-19 23:59:59',1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `promo_codes` VALUES (2,'AIRPORT10','10% off airport shuttles','percent',10,3000,'shuttle',0,500,0,'2026-09-19 00:00:00','2027-04-19 23:59:59',1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `promo_codes` VALUES (3,'EKOTOURS','₦2,000 off any tour','fixed',2000,NULL,'tour',0,1000,0,'2026-09-19 00:00:00','2027-04-19 23:59:59',1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `promo_codes` VALUES (4,'RIDE500','₦500 off a ride','fixed',500,NULL,'ride',0,NULL,0,'2026-09-19 00:00:00','2027-04-19 23:59:59',1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `promo_codes` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `reviews` WRITE;
/*!40000 ALTER TABLE `reviews` DISABLE KEYS */;
INSERT INTO `reviews` VALUES (1,1,1,1,5,'Great value and a really friendly group.','[\"Safe\"]',1,'2026-10-09 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (2,3,1,2,4,'The highlight of my trip to Lagos.','[\"Well organised\"]',1,'2026-10-10 20:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (3,1,1,5,5,'The highlight of my trip to Lagos.','[\"Safe\"]',1,'2026-10-15 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (4,15,1,6,4,'Brilliant day out. Well organised and the driver was waiting when we finished.','[\"Good value\"]',1,'2026-10-16 20:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (5,6,1,7,4,'Loved every minute. Bring sunscreen.','[\"Good value\"]',1,'2026-10-18 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (6,16,2,18,4,'Good tour but it started 20 minutes late.','[\"Good value\"]',1,'2026-10-09 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (7,8,2,19,3,'Great value and a really friendly group.','[\"Good value\"]',1,'2026-10-12 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (8,12,2,20,4,'Great value and a really friendly group.','[\"Safe\"]',1,'2026-10-15 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (9,1,2,21,5,'The highlight of my trip to Lagos.','[\"Great guide\"]',1,'2026-10-18 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (10,12,3,27,5,'Great value and a really friendly group.','[\"Good value\"]',1,'2026-10-09 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (11,1,3,28,4,'The highlight of my trip to Lagos.','[\"Well organised\"]',1,'2026-10-12 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (12,1,3,29,4,'Good tour but it started 20 minutes late.','[\"Well organised\"]',1,'2026-10-15 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (13,14,3,30,5,'Loved every minute. Bring sunscreen.','[\"Well organised\"]',1,'2026-10-18 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (14,12,4,36,5,'Great value and a really friendly group.','[\"Safe\"]',1,'2026-10-09 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (15,1,4,37,3,'Great value and a really friendly group.','[\"Good value\"]',1,'2026-10-10 20:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (16,4,4,39,5,'Great value and a really friendly group.','[\"Good value\"]',1,'2026-10-13 20:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (17,5,4,40,5,'Good tour but it started 20 minutes late.','[\"Well organised\"]',1,'2026-10-15 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (18,14,4,43,5,'Good tour but it started 20 minutes late.','[\"Good value\"]',1,'2026-10-19 20:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (19,4,5,55,3,'Our guide knew every tree and monkey by name. The canopy walk is not for the faint-hearted!','[\"Safe\"]',1,'2026-10-15 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (20,3,5,56,4,'Our guide knew every tree and monkey by name. The canopy walk is not for the faint-hearted!','[\"Great guide\"]',1,'2026-10-18 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (21,1,6,62,3,'Loved every minute. Bring sunscreen.','[\"Safe\"]',1,'2026-10-09 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (22,2,6,63,5,'The highlight of my trip to Lagos.','[\"Good value\"]',1,'2026-10-10 20:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (23,8,6,64,5,'Great value and a really friendly group.','[\"Safe\"]',1,'2026-10-12 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (24,1,6,65,5,'Good tour but it started 20 minutes late.','[\"Well organised\"]',1,'2026-10-13 20:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (25,10,6,66,3,'The highlight of my trip to Lagos.','[\"Safe\"]',1,'2026-10-15 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (26,14,6,68,5,'Loved every minute. Bring sunscreen.','[\"Good value\"]',1,'2026-10-18 15:00:00','2026-10-19 16:15:22');
INSERT INTO `reviews` VALUES (27,1,6,69,4,'Great value and a really friendly group.','[\"Good value\"]',1,'2026-10-19 20:00:00','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `reviews` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `ride_types` WRITE;
/*!40000 ALTER TABLE `ride_types` DISABLE KEYS */;
INSERT INTO `ride_types` VALUES (1,'economy','Economy','Affordable everyday rides',4,700,120,20,1500,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `ride_types` VALUES (2,'comfort','Comfort','Newer cars with extra legroom',4,1000,170,28,2200,2,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `ride_types` VALUES (3,'suv','SUV','Room for six and their luggage',6,1500,240,38,3200,3,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `ride_types` VALUES (4,'premium','Premium','Top-rated drivers in executive cars',4,2200,360,55,4800,4,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `ride_types` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `riders` WRITE;
/*!40000 ALTER TABLE `riders` DISABLE KEYS */;
INSERT INTO `riders` VALUES (1,'Tunde','Bakare','tunde.bakare@example.co.uk','+447700900123',NULL,'British','GBP','international','en',NULL,25000,200,'TUND0001',NULL,'active',4.74,'2026-10-10 13:15:21','2026-08-20 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (2,'Amara','Okafor','amara.okafor@example.com','+2348031234567',NULL,'Nigerian','NGN','resident','en',NULL,8000,575,'AMAR0002',NULL,'active',5.00,'2026-10-16 10:15:21','2026-08-23 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (3,'Daniel','Kamau','daniel.kamau@example.co.ke','+254712345678',NULL,'Kenyan','USD','international','en',NULL,0,850,'DANI0003',NULL,'active',4.85,'2026-10-17 03:15:21','2026-08-26 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (4,'Tolu','Adebayo','tolu.adebayo@example.com','+2348099876543',NULL,'Nigerian','NGN','domestic','en',NULL,3500,0,'TOLU0004',NULL,'active',4.79,'2026-10-17 10:15:21','2026-08-29 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (5,'Sarah','Mitchell','sarah.mitchell@example.com','+14155550142',NULL,'American','USD','international','en',NULL,0,900,'SARA0005',NULL,'active',4.81,'2026-10-12 21:15:21','2026-09-01 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (6,'Kwame','Mensah','kwame.mensah@example.com.gh','+233244123456',NULL,'Ghanaian','USD','international','en',NULL,12000,850,'KWAM0006',NULL,'active',4.79,'2026-10-11 04:15:21','2026-09-04 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (7,'Chiamaka','Eze','chiamaka.eze@example.com','+2348055512345',NULL,'Nigerian','NGN','resident','en',NULL,0,275,'CHIA0007',NULL,'active',4.89,'2026-10-16 00:15:21','2026-09-07 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (8,'Oliver','Hughes','oliver.hughes@example.co.uk','+447700900456',NULL,'British','GBP','international','en',NULL,40000,950,'OLIV0008',NULL,'active',4.75,'2026-10-11 16:15:21','2026-09-10 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (9,'Aisha','Bello','aisha.bello@example.com','+2348066623456',NULL,'Nigerian','NGN','domestic','en',NULL,1500,900,'AISH0009',NULL,'active',4.66,'2026-10-17 15:15:21','2026-09-13 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (10,'Marie','Dubois','marie.dubois@example.fr','+33612345678',NULL,'French','EUR','international','fr',NULL,0,550,'MARI0010',NULL,'active',4.72,'2026-10-18 19:15:21','2026-09-16 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (11,'Femi','Oyelaran','femi.oyelaran@example.com','+2348077734567',NULL,'Nigerian','NGN','resident','en',NULL,6000,225,'FEMI0011',NULL,'active',4.70,'2026-10-10 11:15:21','2026-09-19 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (12,'Grace','Achieng','grace.achieng@example.co.ke','+254722987654',NULL,'Kenyan','USD','international','en','{\"wheelchair\":true,\"assistance\":\"Needs help with a folding wheelchair\"}',0,950,'GRAC0012',NULL,'active',4.83,'2026-10-17 22:15:21','2026-09-22 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (13,'Ibrahim','Musa','ibrahim.musa@example.com','+2348088845678',NULL,'Nigerian','NGN','domestic','en',NULL,0,125,'IBRA0013',NULL,'suspended',4.91,'2026-10-14 08:15:21','2026-09-25 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (14,'Emily','Carter','emily.carter@example.ca','+16475550199',NULL,'Canadian','USD','international','en',NULL,15000,775,'EMIL0014',NULL,'active',4.78,'2026-10-09 22:15:21','2026-09-28 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (15,'Ngozi','Umeh','ngozi.umeh@example.com','+2348099956789',NULL,'Nigerian','NGN','resident','en',NULL,2000,800,'NGOZ0015',NULL,'active',4.95,'2026-10-18 01:15:21','2026-10-01 16:15:21','2026-10-19 16:15:21',NULL);
INSERT INTO `riders` VALUES (16,'Samuel','Osei','samuel.osei@example.com.gh','+233201234567',NULL,'Ghanaian','USD','international','en',NULL,0,675,'SAMU0016',NULL,'active',4.87,'2026-10-19 07:15:21','2026-10-04 16:15:21','2026-10-19 16:15:21',NULL);
/*!40000 ALTER TABLE `riders` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `saved_places` WRITE;
/*!40000 ALTER TABLE `saved_places` DISABLE KEYS */;
INSERT INTO `saved_places` VALUES (1,1,'Hotel','Eko Hotel & Suites, Adetokunbo Ademola Street, Victoria Island',6.4268000,3.4290000,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `saved_places` VALUES (2,1,'Cousin','12 Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `saved_places` VALUES (3,1,'Work','Civic Centre, Ozumba Mbadiwe Avenue, Victoria Island',6.4352000,3.4136000,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `saved_places` VALUES (4,3,'Hotel','The Wheatbaker, 4 Onitolo Road, Ikoyi',6.4473000,3.4337000,'2026-10-19 16:15:21','2026-10-19 16:15:21');
/*!40000 ALTER TABLE `saved_places` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `settings` WRITE;
/*!40000 ALTER TABLE `settings` DISABLE KEYS */;
INSERT INTO `settings` VALUES (1,'commission_rate','20','Platform commission (%)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (2,'free_waiting_minutes','5','Free waiting time (minutes)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (3,'waiting_fee_per_minute','50','Waiting fee per minute after free time (₦)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (4,'airport_free_waiting_minutes','60','Airport pickup free waiting time (minutes)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (5,'stop_fee','300','Fee per extra stop (₦)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (6,'lekki_toll','250','Lekki toll gate charge (₦)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (7,'rider_cancellation_fee','500','Rider cancellation fee after driver accepts (₦)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (8,'free_cancellation_minutes','2','Free cancellation window after acceptance (minutes)','pricing','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (9,'cash_debt_limit','20000','Driver cash commission limit before going offline (₦)','drivers','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (10,'instant_cashout_fee_percent','1.5','Instant cash-out fee (%)','drivers','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (11,'minimum_cashout','5000','Minimum instant cash-out (₦)','drivers','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (12,'weekly_payout_day','Tuesday','Weekly payout day','drivers','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (13,'gbp_rate','2000','Display exchange rate: ₦ per £1','currency','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (14,'usd_rate','1550','Display exchange rate: ₦ per $1','currency','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (15,'eur_rate','1700','Display exchange rate: ₦ per €1','currency','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (16,'tour_free_cancellation_hours','24','Free tour cancellation up to (hours before)','tours','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (17,'tour_ride_addon_price','4000','Ride to the tour add-on (₦ per booking)','tours','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (18,'support_phone','+234 201 330 2226','Support phone','general','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (19,'support_email','help@caboapp.online','Support email','general','2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `settings` VALUES (20,'emergency_number','112','Emergency number shown in the safety centre','general','2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `settings` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `shuttle_bookings` WRITE;
/*!40000 ALTER TABLE `shuttle_bookings` DISABLE KEYS */;
INSERT INTO `shuttle_bookings` VALUES (1,'SH-4NZTKG',1,1,'airport_pickup','Murtala Muhammed International (LOS)','Terminal 2 (International)','BA75','2026-10-22 16:35:00','scheduled','2026-10-22 17:20:00','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,2,2,2,1,22000,17600,'Arrivals hall exit, by the Cabo sign at Pillar 3','BAKARE',NULL,'card','paid','driver_assigned','2026-10-18 16:15:22','2026-10-11 16:15:22','2026-10-19 16:15:22');
INSERT INTO `shuttle_bookings` VALUES (2,'SH-2X9NAS',3,NULL,'airport_dropoff','Murtala Muhammed International (LOS)','Terminal 2 (International)','KQ533','2026-10-24 23:15:00','scheduled','2026-10-24 19:15:00','The Wheatbaker, Ikoyi',6.4473000,3.4337000,2,1,1,1,22000,17600,NULL,NULL,NULL,'card','paid','confirmed',NULL,'2026-10-11 16:15:22','2026-10-19 16:15:22');
INSERT INTO `shuttle_bookings` VALUES (3,'SH-Q0AS3G',5,2,'airport_pickup','Murtala Muhammed International (LOS)','Terminal 2 (International)','DL54','2026-10-13 15:20:00','landed','2026-10-13 16:05:00','Lagos Continental Hotel, Victoria Island',6.4247000,3.4115000,1,1,2,0,18000,14400,'Arrivals hall exit, by the Cabo sign at Pillar 3','MITCHELL',NULL,'card','paid','completed','2026-10-18 16:15:22','2026-10-11 16:15:22','2026-10-19 16:15:22');
INSERT INTO `shuttle_bookings` VALUES (4,'SH-1KGILE',8,6,'airport_pickup','Murtala Muhammed International (LOS)','Terminal 2 (International)','VS411','2026-10-20 06:05:00','scheduled','2026-10-20 06:50:00','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,4,2,3,2,45000,36000,'Arrivals hall exit, by the Cabo sign at Pillar 3','HUGHES',NULL,'card','paid','driver_assigned','2026-10-18 16:15:22','2026-10-11 16:15:22','2026-10-19 16:15:22');
INSERT INTO `shuttle_bookings` VALUES (5,'SH-FJ38TN',6,NULL,'airport_dropoff','Murtala Muhammed International (LOS)','Domestic Terminal (MMA2)','AW124','2026-10-21 11:00:00','scheduled','2026-10-21 07:00:00','Radisson Blu Anchorage, Victoria Island',6.4337000,3.4167000,1,1,1,0,16000,12800,NULL,NULL,NULL,'card','paid','confirmed',NULL,'2026-10-11 16:15:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `shuttle_bookings` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `sos_alerts` WRITE;
/*!40000 ALTER TABLE `sos_alerts` DISABLE KEYS */;
INSERT INTO `sos_alerts` VALUES (1,'rider',7,57,6.4552000,3.4335000,'Falomo Bridge, Ikoyi','resolved',2,'2026-10-10 16:15:22','2026-10-10 16:33:22','Rider felt unwell. Driver took her to Reddington Hospital. Followed up next day; all fine.','2026-10-10 16:15:22','2026-10-19 16:15:22');
INSERT INTO `sos_alerts` VALUES (2,'driver',3,NULL,6.4410000,3.4920000,'Lekki–Epe Expressway near Chevron','open',NULL,NULL,NULL,NULL,'2026-10-19 16:09:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `sos_alerts` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `support_messages` WRITE;
/*!40000 ALTER TABLE `support_messages` DISABLE KEYS */;
INSERT INTO `support_messages` VALUES (1,1,'rider',1,'Hi, I think I left my Ray-Ban sunglasses on the back seat after my ride this afternoon.','2026-10-15 16:15:22','2026-10-19 16:15:22');
INSERT INTO `support_messages` VALUES (2,1,'admin',3,'Sorry to hear that, Tunde. We have messaged your driver and will update you within the hour.','2026-10-15 16:35:22','2026-10-19 16:15:22');
INSERT INTO `support_messages` VALUES (3,2,'rider',2,'My card was charged twice for the same trip to Ikoyi. Please refund one of them.','2026-10-16 15:15:22','2026-10-19 16:15:22');
INSERT INTO `support_messages` VALUES (4,3,'rider',10,'The tour was cancelled due to rain. When will I get my refund?','2026-10-17 14:15:22','2026-10-19 16:15:22');
INSERT INTO `support_messages` VALUES (5,3,'admin',3,'We have issued a full refund to your card. It can take 3–5 working days to appear.','2026-10-17 14:35:22','2026-10-19 16:15:22');
INSERT INTO `support_messages` VALUES (6,4,'driver',1,'I requested an instant cash-out of ₦19,700 but it has not arrived in my GTBank account.','2026-10-18 13:15:22','2026-10-19 16:15:22');
INSERT INTO `support_messages` VALUES (7,5,'driver',4,'A rider spilled a drink on my back seat last night.','2026-10-18 12:15:22','2026-10-19 16:15:22');
INSERT INTO `support_messages` VALUES (8,5,'admin',3,'Please send us photos of the damage and the receipt for cleaning.','2026-10-18 12:35:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `support_messages` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `support_tickets` WRITE;
/*!40000 ALTER TABLE `support_tickets` DISABLE KEYS */;
INSERT INTO `support_tickets` VALUES (1,'ST-NYZBO1','rider',1,'trip',86,'lost_item','Left my sunglasses in the car','in_review','normal',3,NULL,'2026-10-15 16:15:22','2026-10-19 16:15:22');
INSERT INTO `support_tickets` VALUES (2,'ST-FTCSYM','rider',2,NULL,NULL,'overcharge','Charged twice for one ride','open','high',NULL,NULL,'2026-10-16 15:15:22','2026-10-19 16:15:22');
INSERT INTO `support_tickets` VALUES (3,'ST-8RRTII','rider',10,NULL,NULL,'refund','Refund for cancelled tour','resolved','normal',3,'2026-10-17 16:15:22','2026-10-17 14:15:22','2026-10-19 16:15:22');
INSERT INTO `support_tickets` VALUES (4,'ST-F8VMUM','driver',1,NULL,NULL,'payout','Instant cash-out not received','open','normal',NULL,NULL,'2026-10-18 13:15:22','2026-10-19 16:15:22');
INSERT INTO `support_tickets` VALUES (5,'ST-TIRAEU','driver',4,NULL,NULL,'rider_behaviour','Rider damaged seat cover','awaiting_user','low',3,NULL,'2026-10-18 12:15:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `support_tickets` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `tour_bookings` WRITE;
/*!40000 ALTER TABLE `tour_bookings` DISABLE KEYS */;
INSERT INTO `tour_bookings` VALUES (1,'TR-RYFABO',1,1,1,3,45000,'[]',0,0,NULL,NULL,0,45000,'card','paid',0,'completed','useavnYP1CXURB6jAkBinqoRkC3xE5mw',NULL,'2026-10-09 08:50:00',NULL,'2026-10-02 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (2,'TR-WMO1TF',3,1,4,2,30000,'[]',0,0,NULL,NULL,0,30000,'card','paid',0,'completed','k8T6ZXPNhhWKld2tt0MTdLkmrdbxnTQF',NULL,'2026-10-10 13:50:00',NULL,'2026-10-01 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (3,'TR-ZBTC11',4,1,7,1,15000,'[]',0,0,NULL,NULL,0,15000,'bank_transfer','paid',0,'completed','Hhcpg1YsoPwQmssDlTevJ97BrijluBcW',NULL,'2026-10-12 08:50:00',NULL,'2026-10-07 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (4,'TR-JL2WHN',16,1,10,2,30000,'[]',0,0,NULL,NULL,0,30000,'bank_transfer','paid',0,'completed','NDC5MSJJ0VtKBj3ISKSjPpyNRksBy8z6',NULL,'2026-10-13 13:50:00',NULL,'2026-10-04 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (5,'TR-ACMBCD',1,1,13,2,30000,'[]',0,0,NULL,NULL,0,30000,'wallet','paid',0,'completed','xT0vaRoxlyHA4W0AsM3rn61ItuK2d3iH',NULL,'2026-10-15 08:50:00',NULL,'2026-10-11 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (6,'TR-HECGOU',15,1,16,1,15000,'[]',0,0,NULL,NULL,0,15000,'card','paid',0,'completed','2GNQinRbnPZUrsh2vcMAvrKMWjbVP8xd',NULL,'2026-10-16 13:50:00',NULL,'2026-10-11 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (7,'TR-ZGLAWO',6,1,19,1,15000,'[]',0,0,NULL,NULL,0,15000,'card','paid',0,'completed','60Pf2rfuZmSQJa1Vn2H9qHqaeCPnFQuf',NULL,'2026-10-18 08:50:00',NULL,'2026-10-10 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (8,'TR-ZR81HF',15,1,22,1,15000,'[]',0,0,NULL,NULL,0,15000,'card','paid',0,'completed','uIzAsfFEdUJTvNCTkwZjqF2Awpqtz1tU',NULL,'2026-10-19 13:50:00',NULL,'2026-10-15 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (9,'TR-OKYV0A',1,1,25,3,45000,'[]',0,0,NULL,NULL,0,45000,'card','paid',0,'confirmed','QLVhCIq0rrCcZC8mczniYLp9HqIBB5TY',NULL,NULL,NULL,'2026-10-19 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (10,'TR-ULNXUI',2,1,28,1,15000,'[]',0,0,NULL,NULL,0,15000,'bank_transfer','paid',0,'confirmed','SC0L1mIx2yH333TvGaBiF8LcDM0eVwu3',NULL,NULL,NULL,'2026-10-15 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (11,'TR-Y6POG0',5,1,31,2,30000,'[]',0,0,NULL,NULL,0,30000,'card','paid',0,'confirmed','0h2O5KTi4AnFhYzUXJcEtNpdUzY9Kn2N',NULL,NULL,NULL,'2026-10-20 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (12,'TR-ASQRJZ',15,1,34,3,45000,'[]',0,0,NULL,NULL,0,45000,'wallet','paid',0,'confirmed','UI5N9mYP430II3eh3ZtX1rmeDJIKRulT',NULL,NULL,NULL,'2026-10-19 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (13,'TR-5XIPF8',1,1,37,2,30000,'[]',0,0,NULL,NULL,0,30000,'wallet','paid',0,'confirmed','ZTzY9axlBCbelVGDBwo9745fq5jYKA3m',NULL,NULL,NULL,'2026-10-21 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (14,'TR-REQAOF',1,1,40,1,15000,'[]',0,0,NULL,NULL,0,15000,'bank_transfer','paid',0,'confirmed','0bK0QHSQwmLKb6JwnLboBxGxgROioR5N',NULL,NULL,NULL,'2026-10-25 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (15,'TR-GMCHLM',11,1,43,2,30000,'[]',0,0,NULL,NULL,0,30000,'bank_transfer','paid',0,'confirmed','KVlqoTtZu91GA0oz3wy1w2A0XbXRNVm8',NULL,NULL,NULL,'2026-10-25 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (16,'TR-UMODOB',3,1,46,3,45000,'[]',0,0,NULL,NULL,0,45000,'wallet','paid',0,'confirmed','i3HXMqQ7hZp4xkj7KMOWobhVjRox1GVu',NULL,NULL,NULL,'2026-10-29 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (17,'TR-LO7CIE',1,1,49,3,45000,'[]',0,0,NULL,NULL,0,45000,'wallet','paid',0,'confirmed','Nmw5FHFtIej32KqS5v9MWanzlbddLPYC',NULL,NULL,NULL,'2026-10-24 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (18,'TR-8NKXLB',16,2,51,2,50000,'[]',0,0,NULL,NULL,0,50000,'card','paid',0,'completed','fv2gfeg28uLwxP7iCglkm5OoGPQFhgUp',NULL,'2026-10-09 08:50:00',NULL,'2026-10-04 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (19,'TR-GJFTKG',8,2,54,3,75000,'[]',0,0,NULL,NULL,0,75000,'wallet','paid',0,'completed','0670jIki3PcQkuxznZM2YKyTYBTkf1XJ',NULL,'2026-10-12 08:50:00',NULL,'2026-10-07 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (20,'TR-1ZOPQF',12,2,57,2,50000,'[]',0,0,NULL,NULL,0,50000,'wallet','paid',0,'completed','RAd05oCKjQE1TO3N0NZ05Tf6GSXsENOl',NULL,'2026-10-15 08:50:00',NULL,'2026-10-09 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (21,'TR-GK7RQV',1,2,60,2,50000,'[]',0,0,NULL,NULL,0,50000,'card','paid',0,'completed','mFu6OnTAcAlhRi1R4foxP23B51WqHefm',NULL,'2026-10-18 08:50:00',NULL,'2026-10-15 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (22,'TR-RE2DXX',5,2,63,1,25000,'[]',0,0,NULL,NULL,0,25000,'card','paid',0,'confirmed','3pMpBACH70XY37naRGE3Df80Y7h0h4YK',NULL,NULL,NULL,'2026-10-12 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (23,'TR-INIQ3H',8,2,66,1,25000,'[]',0,0,NULL,NULL,0,25000,'wallet','paid',0,'confirmed','ARKvCwrfSGEJyNkXu2vsm9LiC8ItcNby',NULL,NULL,NULL,'2026-10-19 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (24,'TR-6KQKQ2',1,2,69,2,50000,'[]',0,0,NULL,NULL,0,50000,'card','paid',0,'confirmed','upj8OuziuGjnRx9jHqXTfetJdbhAw2vT',NULL,NULL,NULL,'2026-10-23 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (25,'TR-Y0YH4O',1,2,72,2,50000,'[]',0,0,NULL,NULL,0,50000,'wallet','paid',0,'confirmed','O56hTnVRWk9GBOPOwBWMXtwC1FUNmsBb',NULL,NULL,NULL,'2026-10-26 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (26,'TR-BOS39U',11,2,75,2,50000,'[]',0,0,NULL,NULL,0,50000,'bank_transfer','paid',0,'confirmed','9bOML0vcwxIil0qzAfAWs3PWLk1Jmm77',NULL,NULL,NULL,'2026-10-25 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (27,'TR-I6WXG9',12,3,76,1,18000,'[]',0,0,NULL,NULL,0,18000,'bank_transfer','paid',0,'completed','WBfQJWy2L852xoiidHPpovWwk46WYJEL',NULL,'2026-10-09 08:50:00',NULL,'2026-10-02 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (28,'TR-EKANIU',1,3,79,2,36000,'[]',0,0,NULL,NULL,0,36000,'wallet','paid',0,'completed','dx8Mer7kuXoNKmPDuFtBAzXiAAj763hy',NULL,'2026-10-12 08:50:00',NULL,'2026-10-07 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (29,'TR-PBSJ8A',1,3,82,3,54000,'[]',0,0,NULL,NULL,0,54000,'wallet','paid',0,'completed','NeZcJm2rn8A8r0PNm16Y9keqalFLNmVO',NULL,'2026-10-15 08:50:00',NULL,'2026-10-13 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (30,'TR-EUU8WO',14,3,85,1,18000,'[]',0,0,NULL,NULL,0,18000,'wallet','paid',0,'completed','YFMgJIsjSCWIEFaLfH3gqJUrcpqPAi6i',NULL,'2026-10-18 08:50:00',NULL,'2026-10-13 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (31,'TR-EOXYDG',8,3,88,3,54000,'[]',0,0,NULL,NULL,0,54000,'card','paid',0,'confirmed','ZtfjQxbf7D9fvb4LswfeyeghulDHe5qs',NULL,NULL,NULL,'2026-10-18 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (32,'TR-5BF5DS',8,3,91,1,18000,'[]',0,0,NULL,NULL,0,18000,'wallet','paid',0,'confirmed','DBj9N4oYf3jSu7dbSGFp4yvIrMIsGtLd',NULL,NULL,NULL,'2026-10-16 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (33,'TR-BM9RUI',1,3,94,1,18000,'[]',0,0,NULL,NULL,0,18000,'card','paid',0,'confirmed','f6Ex6UqrC5wiO4WeKTNG4PEVU3LiTj6s',NULL,NULL,NULL,'2026-10-23 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (34,'TR-H8OBRS',7,3,97,2,36000,'[]',0,0,NULL,NULL,0,36000,'wallet','paid',0,'confirmed','5q8sDmQYlkU5H4JrS1EVA9i8C5ZZ3GMZ',NULL,NULL,NULL,'2026-10-25 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (35,'TR-IWLHNF',6,3,100,3,54000,'[]',0,0,NULL,NULL,0,54000,'card','paid',0,'confirmed','pCWBoxqlNdGRnS5fr7je5mKOmyL3akax',NULL,NULL,NULL,'2026-10-24 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (36,'TR-WIBQHD',12,4,101,3,66000,'[]',0,0,NULL,NULL,0,66000,'card','paid',0,'completed','taQULrZMxqgq2IViBW5LVR4YHiGQommH',NULL,'2026-10-09 08:50:00',NULL,'2026-10-06 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (37,'TR-YCR13G',1,4,104,2,44000,'[]',0,0,NULL,NULL,0,44000,'bank_transfer','paid',0,'completed','UH8ircGlmVIr3zrjLK2ByZXobaIR0AIV',NULL,'2026-10-10 13:50:00',NULL,'2026-10-02 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (38,'TR-ZOW3KE',8,4,107,1,22000,'[]',0,0,NULL,NULL,0,22000,'bank_transfer','paid',0,'completed','RnduHsl8eXlXLXkMfad1F0DHAGRO9vnO',NULL,'2026-10-12 08:50:00',NULL,'2026-10-03 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (39,'TR-4DH1RK',4,4,110,1,22000,'[]',0,0,NULL,NULL,0,22000,'wallet','paid',0,'completed','MgiwJFfusE8mtQVewt8aZzCnmzH3ZXXK',NULL,'2026-10-13 13:50:00',NULL,'2026-10-10 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (40,'TR-469PPW',5,4,113,2,44000,'[]',0,0,NULL,NULL,0,44000,'wallet','paid',0,'completed','GuglZalDWRqbjs3zBiFChnn3UXzh4A6O',NULL,'2026-10-15 08:50:00',NULL,'2026-10-12 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (41,'TR-RL2CW6',1,4,116,1,22000,'[]',0,0,NULL,NULL,0,22000,'card','paid',0,'completed','DywuVS5aS8FYRrCr9EDQrOXRmRrWpRXQ',NULL,'2026-10-16 13:50:00',NULL,'2026-10-14 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (42,'TR-DAY3XY',11,4,119,3,66000,'[]',0,0,NULL,NULL,0,66000,'card','paid',0,'completed','XJHTKxj1UU90YBiiY8C19nbajCrfSJQQ',NULL,'2026-10-18 08:50:00',NULL,'2026-10-09 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (43,'TR-3VT4DF',14,4,122,3,66000,'[]',0,0,NULL,NULL,0,66000,'card','paid',0,'completed','gq7zGXBTfa8CwObMknjlHanE8Um3MC47',NULL,'2026-10-19 13:50:00',NULL,'2026-10-15 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (44,'TR-6NVLCR',2,4,125,1,22000,'[]',0,0,NULL,NULL,0,22000,'card','paid',0,'confirmed','Mz38CB800GG4XEeDZ33sFyvmRpcqPzK4',NULL,NULL,NULL,'2026-10-14 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (45,'TR-ZFG2ZP',1,4,128,1,22000,'[]',0,0,NULL,NULL,0,22000,'bank_transfer','paid',0,'confirmed','9tskjw1QUaY2A8Q6fLiiR2R0JN0wz9ap',NULL,NULL,NULL,'2026-10-13 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (46,'TR-QEGBP0',2,4,131,3,66000,'[]',0,0,NULL,NULL,0,66000,'wallet','paid',0,'confirmed','2MUsyWB8aCtiqHqeYVnNtc9u0ZrSyILc',NULL,NULL,NULL,'2026-10-20 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (47,'TR-RNOT7X',12,4,134,2,44000,'[]',0,0,NULL,NULL,0,44000,'wallet','paid',0,'confirmed','pTiwWShBs78PVGUOCfykyaR2fw2G11U4',NULL,NULL,NULL,'2026-10-20 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (48,'TR-258LTO',10,4,137,3,66000,'[]',0,0,NULL,NULL,0,66000,'card','paid',0,'confirmed','K29J6Hb1dy80jja4KWPc8yAqdaw1rAp7',NULL,NULL,NULL,'2026-10-22 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (49,'TR-O3SSDX',1,4,140,1,22000,'[]',0,0,NULL,NULL,0,22000,'card','paid',0,'confirmed','38HSPdTlQXCus0J1JujGrvW3ChKTWhxA',NULL,NULL,NULL,'2026-10-20 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (50,'TR-JRIEKX',14,4,143,3,66000,'[]',0,0,NULL,NULL,0,66000,'card','paid',0,'confirmed','5YGPnA5L6xU1v8ReSqD9IXj7EzwdaCgH',NULL,NULL,NULL,'2026-10-24 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (51,'TR-QJFCUN',6,4,146,1,22000,'[]',0,0,NULL,NULL,0,22000,'wallet','paid',0,'confirmed','FeDZ4utUNcshnik7ifXQ7zguVTMnPkAY',NULL,NULL,NULL,'2026-10-29 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (52,'TR-RHMVYT',9,4,149,1,22000,'[]',0,0,NULL,NULL,0,22000,'bank_transfer','paid',0,'confirmed','qvh46ncxze3V4CCf8NWcn1YztKQpplRG',NULL,NULL,NULL,'2026-10-26 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (53,'TR-MWEWRW',1,5,151,1,30000,'[]',0,0,NULL,NULL,0,30000,'bank_transfer','paid',0,'completed','eSwVeAUysuJYUGigu1LFWg4Q17jadwo9',NULL,'2026-10-09 08:50:00',NULL,'2026-10-02 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (54,'TR-MP6JWY',10,5,154,1,30000,'[]',0,0,NULL,NULL,0,30000,'wallet','paid',0,'completed','ZyGji0wPwcJRXRIgF6JkrGwZ9fWIalGG',NULL,'2026-10-12 08:50:00',NULL,'2026-10-03 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (55,'TR-4HNLF2',4,5,157,3,90000,'[]',0,0,NULL,NULL,0,90000,'card','paid',0,'completed','1pDWEUEjiHxdbRMlBPdKcgzKYsZFuEU9',NULL,'2026-10-15 08:50:00',NULL,'2026-10-09 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (56,'TR-NC0JMW',3,5,160,3,90000,'[]',0,0,NULL,NULL,0,90000,'wallet','paid',0,'completed','CRujSXbExpGx1k8vX86dGv7xbY8gqQwk',NULL,'2026-10-18 08:50:00',NULL,'2026-10-09 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (57,'TR-H9O1BY',1,5,163,3,90000,'[]',0,0,NULL,NULL,0,90000,'card','paid',0,'confirmed','S0ThOK9NKa7k3iLhl6xRDPAljcBlzPrH',NULL,NULL,NULL,'2026-10-19 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (58,'TR-JOXIH3',16,5,166,2,60000,'[]',0,0,NULL,NULL,0,60000,'card','paid',0,'confirmed','c0fdTxZxTgJq18O2b9pwCTi5u083B1kf',NULL,NULL,NULL,'2026-10-16 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (59,'TR-ZI0MYJ',7,5,169,2,60000,'[]',0,0,NULL,NULL,0,60000,'card','paid',0,'confirmed','Q2HnpfroVbszWCtPIw7R8Y9DkqYnq9wU',NULL,NULL,NULL,'2026-10-25 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (60,'TR-G5YVFC',8,5,172,3,90000,'[]',0,0,NULL,NULL,0,90000,'card','paid',0,'confirmed','BA7NpJAY1FzdmhkvsY5erJXitZLjiSnw',NULL,NULL,NULL,'2026-10-23 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (61,'TR-U4LMKL',1,5,175,2,60000,'[]',0,0,NULL,NULL,0,60000,'bank_transfer','paid',0,'confirmed','6NAGfmXlWScl3B6k1OwT6ExID3JocL70',NULL,NULL,NULL,'2026-10-25 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (62,'TR-FFAVD4',1,6,176,1,12000,'[]',0,0,NULL,NULL,0,12000,'wallet','paid',0,'completed','Qe5wyoI3B3RXhfh9qYPoKUES4GaHymaT',NULL,'2026-10-09 08:50:00',NULL,'2026-10-03 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (63,'TR-ZGTSNM',2,6,179,2,24000,'[]',0,0,NULL,NULL,0,24000,'bank_transfer','paid',0,'completed','P9vzOUtGUxIKW8dBl0RC9YCPx538dAmg',NULL,'2026-10-10 13:50:00',NULL,'2026-10-05 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (64,'TR-WWMAMR',8,6,182,2,24000,'[]',0,0,NULL,NULL,0,24000,'card','paid',0,'completed','LaZKdlUUpSZM69537cPzLDm0SJWZmhgU',NULL,'2026-10-12 08:50:00',NULL,'2026-10-06 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (65,'TR-0ZALYU',1,6,185,2,24000,'[]',0,0,NULL,NULL,0,24000,'wallet','paid',0,'completed','7Q48IX6yMwH6JFufUxVznEVknSOX4dAN',NULL,'2026-10-13 13:50:00',NULL,'2026-10-07 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (66,'TR-JNRRAZ',10,6,188,2,24000,'[]',0,0,NULL,NULL,0,24000,'bank_transfer','paid',0,'completed','b2ickBALC5tuJIYrCMBFIgDXcUAcXvXr',NULL,'2026-10-15 08:50:00',NULL,'2026-10-10 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (67,'TR-CVLQ5F',9,6,191,1,12000,'[]',0,0,NULL,NULL,0,12000,'bank_transfer','paid',0,'completed','N04uBW0a2t4oWikjWu6F5H9Vg4SQ1JFr',NULL,'2026-10-16 13:50:00',NULL,'2026-10-10 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (68,'TR-I2CFUU',14,6,194,2,24000,'[]',0,0,NULL,NULL,0,24000,'bank_transfer','paid',0,'completed','tNrnb8NgufmZVo0lODcb57PSQhxztfZ3',NULL,'2026-10-18 08:50:00',NULL,'2026-10-12 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (69,'TR-AQPEJC',1,6,197,1,12000,'[]',0,0,NULL,NULL,0,12000,'wallet','paid',0,'completed','N7yRfS3xehvueU9OXPbJwpM1ZsFEFTer',NULL,'2026-10-19 13:50:00',NULL,'2026-10-16 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (70,'TR-01ZHBI',5,6,200,2,24000,'[]',0,0,NULL,NULL,0,24000,'card','paid',0,'confirmed','OrIgnIjsDFRcqD2BY88orBjpUDkaUxYP',NULL,NULL,NULL,'2026-10-18 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (71,'TR-ECKL6B',6,6,203,3,36000,'[]',0,0,NULL,NULL,0,36000,'card','paid',0,'confirmed','J9MjfWRdDjilBo32e5pKEZlKUarD2z1y',NULL,NULL,NULL,'2026-10-19 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (72,'TR-DZABIF',15,6,206,2,24000,'[]',0,0,NULL,NULL,0,24000,'card','paid',0,'confirmed','VdvOrtqx62ZZZglkZawJrdfxbRZXof38',NULL,NULL,NULL,'2026-10-19 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (73,'TR-YGESE5',1,6,209,3,36000,'[]',0,0,NULL,NULL,0,36000,'card','paid',0,'confirmed','lHpQv6OYh1ADIF6jXIz48HpaajELaS3k',NULL,NULL,NULL,'2026-10-21 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (74,'TR-TSTKXQ',16,6,212,3,36000,'[]',0,0,NULL,NULL,0,36000,'bank_transfer','paid',0,'confirmed','qbvdMQSz3mzSCDGHCX7kGqe465C6DXm9',NULL,NULL,NULL,'2026-10-18 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (75,'TR-FXQLEF',15,6,215,2,24000,'[]',0,0,NULL,NULL,0,24000,'wallet','paid',0,'confirmed','iYugCf21gHuI5AbiU17zyhvqwzb7ures',NULL,NULL,NULL,'2026-10-21 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (76,'TR-0BM7HG',1,6,218,1,12000,'[]',0,0,NULL,NULL,0,12000,'card','paid',0,'confirmed','XoyOqk1NHZpZznfzl9QP5bviQH98V0ZH',NULL,NULL,NULL,'2026-10-21 09:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (77,'TR-TYDHKH',1,6,221,1,12000,'[]',0,0,NULL,NULL,0,12000,'bank_transfer','paid',0,'confirmed','TprVdDxfrKf37VdUcZjlsbQLwsB1123I',NULL,NULL,NULL,'2026-10-26 14:00:00','2026-10-19 16:15:22');
INSERT INTO `tour_bookings` VALUES (78,'TR-KPLWHK',14,6,224,1,12000,'[]',0,0,NULL,NULL,0,12000,'bank_transfer','paid',0,'confirmed','UoaNDpCwLcPqRpWysJfV49nRuCoqhV0k',NULL,NULL,NULL,'2026-10-26 09:00:00','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `tour_bookings` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `tour_categories` WRITE;
/*!40000 ALTER TABLE `tour_categories` DISABLE KEYS */;
INSERT INTO `tour_categories` VALUES (1,'Island Tours','island-tours','sailing',1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_categories` VALUES (2,'Cultural','cultural','museum',2,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_categories` VALUES (3,'City Tours','city-tours','location_city',3,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_categories` VALUES (4,'Nightlife','nightlife','nightlife',4,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_categories` VALUES (5,'Nature & Wildlife','nature-wildlife','forest',5,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_categories` VALUES (6,'Food','food','restaurant',6,'2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `tour_categories` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `tour_slots` WRITE;
/*!40000 ALTER TABLE `tour_slots` DISABLE KEYS */;
INSERT INTO `tour_slots` VALUES (1,1,'2026-10-09 09:00:00',10,3,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (2,1,'2026-10-09 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (3,1,'2026-10-10 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (4,1,'2026-10-10 14:00:00',10,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (5,1,'2026-10-11 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (6,1,'2026-10-11 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (7,1,'2026-10-12 09:00:00',10,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (8,1,'2026-10-12 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (9,1,'2026-10-13 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (10,1,'2026-10-13 14:00:00',10,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (11,1,'2026-10-14 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (12,1,'2026-10-14 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (13,1,'2026-10-15 09:00:00',10,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (14,1,'2026-10-15 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (15,1,'2026-10-16 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (16,1,'2026-10-16 14:00:00',10,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (17,1,'2026-10-17 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (18,1,'2026-10-17 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (19,1,'2026-10-18 09:00:00',10,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (20,1,'2026-10-18 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (21,1,'2026-10-19 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (22,1,'2026-10-19 14:00:00',10,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (23,1,'2026-10-20 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (24,1,'2026-10-20 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (25,1,'2026-10-21 09:00:00',10,3,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (26,1,'2026-10-21 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (27,1,'2026-10-22 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (28,1,'2026-10-22 14:00:00',10,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (29,1,'2026-10-23 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (30,1,'2026-10-23 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (31,1,'2026-10-24 09:00:00',10,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (32,1,'2026-10-24 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (33,1,'2026-10-25 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (34,1,'2026-10-25 14:00:00',10,3,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (35,1,'2026-10-26 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (36,1,'2026-10-26 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (37,1,'2026-10-27 09:00:00',10,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (38,1,'2026-10-27 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (39,1,'2026-10-28 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (40,1,'2026-10-28 14:00:00',10,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (41,1,'2026-10-29 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (42,1,'2026-10-29 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (43,1,'2026-10-30 09:00:00',10,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (44,1,'2026-10-30 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (45,1,'2026-10-31 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (46,1,'2026-10-31 14:00:00',10,3,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (47,1,'2026-11-01 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (48,1,'2026-11-01 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (49,1,'2026-11-02 09:00:00',10,3,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (50,1,'2026-11-02 14:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (51,2,'2026-10-09 09:00:00',12,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (52,2,'2026-10-10 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (53,2,'2026-10-11 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (54,2,'2026-10-12 09:00:00',12,3,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (55,2,'2026-10-13 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (56,2,'2026-10-14 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (57,2,'2026-10-15 09:00:00',12,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (58,2,'2026-10-16 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (59,2,'2026-10-17 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (60,2,'2026-10-18 09:00:00',12,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (61,2,'2026-10-19 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (62,2,'2026-10-20 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (63,2,'2026-10-21 09:00:00',12,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (64,2,'2026-10-22 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (65,2,'2026-10-23 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (66,2,'2026-10-24 09:00:00',12,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (67,2,'2026-10-25 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (68,2,'2026-10-26 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (69,2,'2026-10-27 09:00:00',12,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (70,2,'2026-10-28 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (71,2,'2026-10-29 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (72,2,'2026-10-30 09:00:00',12,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (73,2,'2026-10-31 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (74,2,'2026-11-01 09:00:00',12,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (75,2,'2026-11-02 09:00:00',12,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (76,3,'2026-10-09 09:00:00',10,1,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (77,3,'2026-10-10 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (78,3,'2026-10-11 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (79,3,'2026-10-12 09:00:00',10,2,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (80,3,'2026-10-13 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (81,3,'2026-10-14 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (82,3,'2026-10-15 09:00:00',10,3,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (83,3,'2026-10-16 09:00:00',10,0,NULL,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tour_slots` VALUES (84,3,'2026-10-17 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (85,3,'2026-10-18 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (86,3,'2026-10-19 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (87,3,'2026-10-20 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (88,3,'2026-10-21 09:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (89,3,'2026-10-22 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (90,3,'2026-10-23 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (91,3,'2026-10-24 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (92,3,'2026-10-25 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (93,3,'2026-10-26 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (94,3,'2026-10-27 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (95,3,'2026-10-28 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (96,3,'2026-10-29 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (97,3,'2026-10-30 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (98,3,'2026-10-31 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (99,3,'2026-11-01 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (100,3,'2026-11-02 09:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (101,4,'2026-10-09 09:00:00',8,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (102,4,'2026-10-09 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (103,4,'2026-10-10 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (104,4,'2026-10-10 14:00:00',8,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (105,4,'2026-10-11 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (106,4,'2026-10-11 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (107,4,'2026-10-12 09:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (108,4,'2026-10-12 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (109,4,'2026-10-13 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (110,4,'2026-10-13 14:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (111,4,'2026-10-14 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (112,4,'2026-10-14 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (113,4,'2026-10-15 09:00:00',8,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (114,4,'2026-10-15 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (115,4,'2026-10-16 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (116,4,'2026-10-16 14:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (117,4,'2026-10-17 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (118,4,'2026-10-17 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (119,4,'2026-10-18 09:00:00',8,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (120,4,'2026-10-18 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (121,4,'2026-10-19 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (122,4,'2026-10-19 14:00:00',8,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (123,4,'2026-10-20 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (124,4,'2026-10-20 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (125,4,'2026-10-21 09:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (126,4,'2026-10-21 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (127,4,'2026-10-22 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (128,4,'2026-10-22 14:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (129,4,'2026-10-23 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (130,4,'2026-10-23 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (131,4,'2026-10-24 09:00:00',8,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (132,4,'2026-10-24 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (133,4,'2026-10-25 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (134,4,'2026-10-25 14:00:00',8,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (135,4,'2026-10-26 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (136,4,'2026-10-26 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (137,4,'2026-10-27 09:00:00',8,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (138,4,'2026-10-27 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (139,4,'2026-10-28 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (140,4,'2026-10-28 14:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (141,4,'2026-10-29 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (142,4,'2026-10-29 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (143,4,'2026-10-30 09:00:00',8,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (144,4,'2026-10-30 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (145,4,'2026-10-31 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (146,4,'2026-10-31 14:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (147,4,'2026-11-01 09:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (148,4,'2026-11-01 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (149,4,'2026-11-02 09:00:00',8,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (150,4,'2026-11-02 14:00:00',8,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (151,5,'2026-10-09 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (152,5,'2026-10-10 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (153,5,'2026-10-11 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (154,5,'2026-10-12 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (155,5,'2026-10-13 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (156,5,'2026-10-14 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (157,5,'2026-10-15 09:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (158,5,'2026-10-16 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (159,5,'2026-10-17 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (160,5,'2026-10-18 09:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (161,5,'2026-10-19 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (162,5,'2026-10-20 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (163,5,'2026-10-21 09:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (164,5,'2026-10-22 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (165,5,'2026-10-23 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (166,5,'2026-10-24 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (167,5,'2026-10-25 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (168,5,'2026-10-26 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (169,5,'2026-10-27 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (170,5,'2026-10-28 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (171,5,'2026-10-29 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (172,5,'2026-10-30 09:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (173,5,'2026-10-31 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (174,5,'2026-11-01 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (175,5,'2026-11-02 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (176,6,'2026-10-09 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (177,6,'2026-10-09 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (178,6,'2026-10-10 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (179,6,'2026-10-10 14:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (180,6,'2026-10-11 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (181,6,'2026-10-11 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (182,6,'2026-10-12 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (183,6,'2026-10-12 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (184,6,'2026-10-13 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (185,6,'2026-10-13 14:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (186,6,'2026-10-14 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (187,6,'2026-10-14 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (188,6,'2026-10-15 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (189,6,'2026-10-15 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (190,6,'2026-10-16 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (191,6,'2026-10-16 14:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (192,6,'2026-10-17 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (193,6,'2026-10-17 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (194,6,'2026-10-18 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (195,6,'2026-10-18 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (196,6,'2026-10-19 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (197,6,'2026-10-19 14:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (198,6,'2026-10-20 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (199,6,'2026-10-20 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (200,6,'2026-10-21 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (201,6,'2026-10-21 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (202,6,'2026-10-22 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (203,6,'2026-10-22 14:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (204,6,'2026-10-23 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (205,6,'2026-10-23 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (206,6,'2026-10-24 09:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (207,6,'2026-10-24 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (208,6,'2026-10-25 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (209,6,'2026-10-25 14:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (210,6,'2026-10-26 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (211,6,'2026-10-26 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (212,6,'2026-10-27 09:00:00',10,3,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (213,6,'2026-10-27 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (214,6,'2026-10-28 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (215,6,'2026-10-28 14:00:00',10,2,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (216,6,'2026-10-29 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (217,6,'2026-10-29 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (218,6,'2026-10-30 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (219,6,'2026-10-30 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (220,6,'2026-10-31 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (221,6,'2026-10-31 14:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (222,6,'2026-11-01 09:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (223,6,'2026-11-01 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tour_slots` VALUES (224,6,'2026-11-02 09:00:00',10,1,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:22');
INSERT INTO `tour_slots` VALUES (225,6,'2026-11-02 14:00:00',10,0,NULL,'2026-10-19 16:15:21','2026-10-19 16:15:21');
/*!40000 ALTER TABLE `tour_slots` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `tours` WRITE;
/*!40000 ALTER TABLE `tours` DISABLE KEYS */;
INSERT INTO `tours` VALUES (1,1,5,'Lekki Conservation Centre','lekki-conservation-centre','Walk the longest canopy walkway in Africa, spot mona monkeys and crocodiles, and learn how the reserve protects Lagos wetlands with a naturalist guide.','Lekki','Lekki Conservation Centre main gate, Km 19 Lekki–Epe Expressway',6.4413000,3.5357000,240,15000,1,10,'[\"English\",\"Yoruba\"]','[\"Meet your guide at the main gate\",\"Nature trail and tree house\",\"Canopy walkway (401 m)\",\"Family park and picnic stop\"]','[\"Entry ticket\",\"Canopy walkway ticket\",\"Bottled water\",\"English-speaking guide\"]','[\"Lunch\",\"Hotel transfers\"]','[{\"code\":\"photo_pack\",\"name\":\"Photo pack (20 edited photos)\",\"price\":5000},{\"code\":\"lunch\",\"name\":\"Picnic lunch\",\"price\":6000}]','Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.','/images/places/lekki-conservation-centre.jpg',0,4.80,2300,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tours` VALUES (2,2,1,'Tarkwa Bay Boat Trip','tarkwa-bay-boat-trip','Cross the harbour by speedboat to a sheltered beach for swimming and grilled fish, with life jackets and a beach umbrella waiting for you.','Lagos Harbour','Tarzan Jetty, Maroko Road, Victoria Island',6.4268000,3.4291000,360,25000,2,12,'[\"English\",\"Yoruba\"]','[\"Board at Tarzan Jetty\",\"Speedboat across Lagos Harbour\",\"Free time on Tarkwa Bay\",\"Grilled fish lunch\",\"Return boat\"]','[\"Return boat ride\",\"Life jackets\",\"Beach umbrella and chairs\",\"Lunch\"]','[\"Drinks\",\"Water sports\"]','[{\"code\":\"photo_pack\",\"name\":\"Photo pack (20 edited photos)\",\"price\":5000},{\"code\":\"jet_ski\",\"name\":\"Jet ski (20 minutes)\",\"price\":15000}]','Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.','/images/places/tarkwa-bay.jpg',0,4.70,860,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tours` VALUES (3,3,2,'Lagos Island Heritage Walk','lagos-island-heritage-walk','Trace the city\'s story from the old colonial prison at Freedom Park to Brazilian Quarter houses, Tinubu Square and the Cathedral Church of Christ.','Lagos Island','Freedom Park, Broad Street, Lagos Island',6.4527000,3.3937000,300,18000,1,10,'[\"English\",\"Yoruba\"]','[\"Freedom Park\",\"Brazilian Quarter (Popo Aguda)\",\"Tinubu Square\",\"Cathedral Church of Christ\",\"Balogun Market edge\"]','[\"Historian guide\",\"Freedom Park entry\",\"Bottled water\",\"Small chops tasting\"]','[\"Hotel transfers\"]','[{\"code\":\"photo_pack\",\"name\":\"Photo pack (20 edited photos)\",\"price\":5000}]','Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.','/images/places/freedom-park.jpg',0,4.90,540,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `tours` VALUES (4,4,6,'Lagos Street Food Tour','lagos-street-food-tour','Taste suya, boli, amala, puff-puff and fresh zobo at the stalls locals swear by, with a guide who explains each dish and how spicy it really is.','Surulere','National Stadium main gate, Surulere',6.4997000,3.3647000,180,22000,1,8,'[\"English\",\"Yoruba\"]','[\"Suya spot\",\"Roadside boli and fish\",\"Amala joint\",\"Puff-puff and zobo\"]','[\"Six tastings\",\"Drinks\",\"Food guide\"]','[\"Hotel transfers\"]','[{\"code\":\"photo_pack\",\"name\":\"Photo pack (20 edited photos)\",\"price\":5000}]','Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.','/images/places/lagos-street-food.jpg',0,4.80,710,0,1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tours` VALUES (5,5,4,'Victoria Island Nightlife','victoria-island-nightlife','See Lagos after dark with a host: a rooftop sunset, Afrobeats live music and a well-known club, with a vetted Cabo ride between every stop.','Victoria Island','Eko Hotel roundabout, Victoria Island',6.4268000,3.4290000,300,30000,2,10,'[\"English\",\"Yoruba\"]','[\"Rooftop sunset drinks\",\"Live Afrobeats bar\",\"Club entry with table\",\"Cabo ride home\"]','[\"Host\",\"Two welcome drinks\",\"Club entry\",\"Rides between venues\"]','[\"Extra drinks\",\"Food\"]','[{\"code\":\"photo_pack\",\"name\":\"Photo pack (20 edited photos)\",\"price\":5000}]','Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.','/images/places/lagos-at-night.jpg',1,4.50,320,0,1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tours` VALUES (6,3,3,'Nike Art Gallery Visit','nike-art-gallery-visit','Explore five floors of Nigerian art, from adire textiles to contemporary painting, and meet artists in the studio if they are in.','Lekki','Nike Art Gallery, 2 Elegushi Road, Lekki Phase 1',6.4371000,3.4848000,120,12000,1,10,'[\"English\",\"Yoruba\"]','[\"Gallery tour (five floors)\",\"Adire textile demonstration\",\"Time in the shop\"]','[\"Guide\",\"Bottled water\"]','[\"Artwork purchases\"]','[{\"code\":\"photo_pack\",\"name\":\"Photo pack (20 edited photos)\",\"price\":5000},{\"code\":\"adire_class\",\"name\":\"Adire dyeing class (1 hour)\",\"price\":10000}]','Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.','/images/places/nike-art-gallery.jpg',1,4.70,1200,0,1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `tours` VALUES (7,6,2,'Badagry Slave Route Day Trip','badagry-slave-route-day-trip','A full day in Badagry: the Point of No Return, the Seriki Abass slave barracoon and the first storey building in Nigeria.','Badagry','Cabo pickup point, Ozumba Mbadiwe Avenue, Victoria Island',6.4321000,3.4190000,540,45000,2,12,'[\"English\",\"Yoruba\"]','[\"Drive to Badagry\",\"Seriki Abass barracoon\",\"Point of No Return\",\"First storey building\",\"Return drive\"]','[\"Transport\",\"Entry fees\",\"Lunch\",\"Guide\"]','[]','[]','Free cancellation up to 24 hours before the start. 50% refund within 24 hours. No refund for no-shows.',NULL,0,NULL,0,0,0,'2026-10-19 16:15:21','2026-10-19 16:15:21');
/*!40000 ALTER TABLE `tours` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `transactions` WRITE;
/*!40000 ALTER TABLE `transactions` DISABLE KEYS */;
INSERT INTO `transactions` VALUES (1,'TX-CA7GY3','rider',1,'trip',1,'charge','debit',5153,'wallet','succeeded','Ride CB-D5OGC2',NULL,'2026-10-14 21:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (2,'TX-X3QCMX','driver',1,'trip',1,'driver_earning','credit',4122,'system','succeeded','Earnings CB-D5OGC2',NULL,'2026-10-14 21:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (3,'TX-TVLSMC','rider',12,'trip',2,'charge','debit',3766,'card','succeeded','Ride CB-QPCV0P',NULL,'2026-10-10 19:05:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (4,'TX-P9TMIT','driver',5,'trip',2,'driver_earning','credit',3013,'system','succeeded','Earnings CB-QPCV0P',NULL,'2026-10-10 19:05:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (5,'TX-YTENWK','rider',9,'trip',3,'charge','debit',2400,'bank_transfer','succeeded','Ride CB-WYOYBO',NULL,'2026-10-18 22:14:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (6,'TX-UL8VX9','driver',1,'trip',3,'driver_earning','credit',1960,'system','succeeded','Earnings CB-WYOYBO',NULL,'2026-10-18 22:14:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (7,'TX-J8V594','rider',16,'trip',4,'charge','debit',3619,'card','succeeded','Ride CB-3RWEOD',NULL,'2026-10-18 19:04:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (8,'TX-5W0MC3','driver',4,'trip',4,'driver_earning','credit',2895,'system','succeeded','Earnings CB-3RWEOD',NULL,'2026-10-18 19:04:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (9,'TX-8M6KB0','rider',4,'trip',5,'charge','debit',2200,'card','succeeded','Ride CB-VZNTI9',NULL,'2026-10-08 21:00:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (10,'TX-YTJZ36','driver',1,'trip',5,'driver_earning','credit',1760,'system','succeeded','Earnings CB-VZNTI9',NULL,'2026-10-08 21:00:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (11,'TX-QZQTEO','rider',1,'trip',6,'charge','debit',2646,'card','succeeded','Ride CB-1AQ5BD',NULL,'2026-10-07 16:00:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (12,'TX-VDL4FO','driver',7,'trip',6,'driver_earning','credit',2157,'system','succeeded','Earnings CB-1AQ5BD',NULL,'2026-10-07 16:00:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (13,'TX-4NBLLT','rider',2,'trip',7,'charge','debit',3252,'cash','succeeded','Ride CB-BXKEYG',NULL,'2026-10-11 09:38:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (14,'TX-VOOI47','rider',3,'trip',8,'charge','debit',5095,'bank_transfer','succeeded','Ride CB-TLPHLO',NULL,'2026-09-27 19:52:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (15,'TX-CU0NLV','driver',8,'trip',8,'driver_earning','credit',4176,'system','succeeded','Earnings CB-TLPHLO',NULL,'2026-09-27 19:52:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (16,'TX-9BOJ1R','rider',2,'trip',9,'charge','debit',500,'wallet','succeeded','Cancellation fee CB-M25E77',NULL,'2026-09-29 11:58:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (17,'TX-U5C79K','rider',16,'trip',10,'charge','debit',500,'bank_transfer','succeeded','Cancellation fee CB-I6KTGR',NULL,'2026-10-15 09:16:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (18,'TX-N6YHDG','rider',1,'trip',11,'charge','debit',6305,'card','succeeded','Ride CB-T6M45P',NULL,'2026-10-15 18:30:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (19,'TX-KOMCIF','driver',5,'trip',11,'driver_earning','credit',5044,'system','succeeded','Earnings CB-T6M45P',NULL,'2026-10-15 18:30:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (20,'TX-QI3QVY','rider',16,'trip',12,'charge','debit',500,'wallet','succeeded','Cancellation fee CB-JDRFVK',NULL,'2026-09-29 10:53:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (21,'TX-ZNXIUY','rider',10,'trip',13,'charge','debit',1951,'card','succeeded','Ride CB-ICIQEO',NULL,'2026-10-03 06:46:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (22,'TX-6XQ2S3','driver',1,'trip',13,'driver_earning','credit',1561,'system','succeeded','Earnings CB-ICIQEO',NULL,'2026-10-03 06:46:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (23,'TX-GGPJN1','rider',10,'trip',14,'charge','debit',1590,'bank_transfer','succeeded','Ride CB-4E8GMY',NULL,'2026-10-14 21:58:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (24,'TX-WFVGJM','driver',5,'trip',14,'driver_earning','credit',1272,'system','succeeded','Earnings CB-4E8GMY',NULL,'2026-10-14 21:58:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (25,'TX-KCUDOY','rider',11,'trip',15,'charge','debit',1500,'wallet','succeeded','Ride CB-KTCZZ3',NULL,'2026-10-12 19:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (26,'TX-YE5JOJ','driver',7,'trip',15,'driver_earning','credit',1200,'system','succeeded','Earnings CB-KTCZZ3',NULL,'2026-10-12 19:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (27,'TX-I0OI6M','rider',1,'trip',16,'charge','debit',2215,'card','succeeded','Ride CB-WCUBPG',NULL,'2026-09-30 09:41:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (28,'TX-H8RWJA','driver',8,'trip',16,'driver_earning','credit',1772,'system','succeeded','Earnings CB-WCUBPG',NULL,'2026-09-30 09:41:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (29,'TX-FI6R40','rider',7,'trip',17,'charge','debit',2269,'card','succeeded','Ride CB-8ZZYEQ',NULL,'2026-09-21 06:40:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (30,'TX-T0UDA1','driver',1,'trip',17,'driver_earning','credit',1815,'system','succeeded','Earnings CB-8ZZYEQ',NULL,'2026-09-21 06:40:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (31,'TX-HJXPNX','rider',15,'trip',18,'charge','debit',3139,'bank_transfer','succeeded','Ride CB-73KQWR',NULL,'2026-09-29 15:19:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (32,'TX-TAT3QX','driver',1,'trip',18,'driver_earning','credit',2711,'system','succeeded','Earnings CB-73KQWR',NULL,'2026-09-29 15:19:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (33,'TX-YYNDN3','rider',9,'trip',19,'charge','debit',4609,'wallet','succeeded','Ride CB-4YSOVV',NULL,'2026-10-05 14:24:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (34,'TX-HCSQPN','driver',4,'trip',19,'driver_earning','credit',3687,'system','succeeded','Earnings CB-4YSOVV',NULL,'2026-10-05 14:24:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (35,'TX-FM87N9','rider',8,'trip',20,'charge','debit',1500,'wallet','succeeded','Ride CB-M1AMBN',NULL,'2026-10-15 16:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (36,'TX-HPDKPH','driver',7,'trip',20,'driver_earning','credit',1200,'system','succeeded','Earnings CB-M1AMBN',NULL,'2026-10-15 16:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (37,'TX-NZ16HU','rider',1,'trip',21,'charge','debit',3641,'card','succeeded','Ride CB-GVBVPU',NULL,'2026-10-09 11:07:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (38,'TX-Y8MCKR','driver',1,'trip',21,'driver_earning','credit',2913,'system','succeeded','Earnings CB-GVBVPU',NULL,'2026-10-09 11:07:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (39,'TX-L9LM7G','rider',12,'trip',22,'charge','debit',4628,'card','succeeded','Ride CB-UYOT7N',NULL,'2026-10-13 12:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (40,'TX-4LLAL0','driver',4,'trip',22,'driver_earning','credit',3802,'system','succeeded','Earnings CB-UYOT7N',NULL,'2026-10-13 12:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (41,'TX-AUOZVB','rider',16,'trip',23,'charge','debit',5837,'wallet','succeeded','Ride CB-CSVAIW',NULL,'2026-09-21 07:17:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (42,'TX-TSKOED','driver',3,'trip',23,'driver_earning','credit',4670,'system','succeeded','Earnings CB-CSVAIW',NULL,'2026-09-21 07:17:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (43,'TX-JSUJXN','rider',8,'trip',24,'charge','debit',5670,'wallet','succeeded','Ride CB-OTULDE',NULL,'2026-10-12 22:32:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (44,'TX-MRWM25','driver',4,'trip',24,'driver_earning','credit',4536,'system','succeeded','Earnings CB-OTULDE',NULL,'2026-10-12 22:32:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (45,'TX-VL7FS5','rider',8,'trip',25,'charge','debit',5837,'card','succeeded','Ride CB-7JHV9H',NULL,'2026-10-04 19:22:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (46,'TX-GGDPV6','driver',1,'trip',25,'driver_earning','credit',4670,'system','succeeded','Earnings CB-7JHV9H',NULL,'2026-10-04 19:22:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (47,'TX-UONDWZ','rider',1,'trip',26,'charge','debit',4514,'card','succeeded','Ride CB-X80QXG',NULL,'2026-10-11 07:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (48,'TX-W6TXG4','driver',6,'trip',26,'driver_earning','credit',3611,'system','succeeded','Earnings CB-X80QXG',NULL,'2026-10-11 07:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (49,'TX-NU1GDU','rider',8,'trip',27,'charge','debit',4660,'card','succeeded','Ride CB-UVSUQZ',NULL,'2026-10-15 13:06:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (50,'TX-BTGOHR','driver',7,'trip',27,'driver_earning','credit',3728,'system','succeeded','Earnings CB-UVSUQZ',NULL,'2026-10-15 13:06:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (51,'TX-0RVN68','rider',3,'trip',28,'charge','debit',5837,'wallet','succeeded','Ride CB-OCLFRL',NULL,'2026-09-23 21:05:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (52,'TX-JEQCIO','driver',2,'trip',28,'driver_earning','credit',4670,'system','succeeded','Earnings CB-OCLFRL',NULL,'2026-09-23 21:05:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (53,'TX-152VHO','rider',6,'trip',29,'charge','debit',2500,'card','succeeded','Ride CB-9K58LM',NULL,'2026-10-13 22:42:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (54,'TX-IAAIVZ','driver',1,'trip',29,'driver_earning','credit',2200,'system','succeeded','Earnings CB-9K58LM',NULL,'2026-10-13 22:42:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (55,'TX-ETEALL','rider',8,'trip',30,'charge','debit',4107,'card','succeeded','Ride CB-OWL13L',NULL,'2026-10-19 11:51:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (56,'TX-PXOYEG','driver',8,'trip',30,'driver_earning','credit',3286,'system','succeeded','Earnings CB-OWL13L',NULL,'2026-10-19 11:51:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (57,'TX-FVN089','rider',1,'trip',31,'charge','debit',5736,'card','succeeded','Ride CB-OBKOCG',NULL,'2026-10-10 15:20:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (58,'TX-WKYEMD','driver',1,'trip',31,'driver_earning','credit',4589,'system','succeeded','Earnings CB-OBKOCG',NULL,'2026-10-10 15:20:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (59,'TX-WG9DLQ','rider',10,'trip',32,'charge','debit',5050,'card','succeeded','Ride CB-EZFF5M',NULL,'2026-09-20 19:38:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (60,'TX-GFRIDN','driver',2,'trip',32,'driver_earning','credit',4040,'system','succeeded','Earnings CB-EZFF5M',NULL,'2026-09-20 19:38:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (61,'TX-8GXHZI','rider',1,'trip',33,'charge','debit',2200,'cash','succeeded','Ride CB-YL3G2U',NULL,'2026-10-03 10:28:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (62,'TX-PMJJZJ','rider',7,'trip',34,'charge','debit',1500,'wallet','succeeded','Ride CB-IRHO4I',NULL,'2026-10-05 12:41:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (63,'TX-KIFWXQ','driver',7,'trip',34,'driver_earning','credit',1200,'system','succeeded','Earnings CB-IRHO4I',NULL,'2026-10-05 12:41:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (64,'TX-BLRLQY','rider',9,'trip',35,'charge','debit',5249,'cash','succeeded','Ride CB-29MBPO',NULL,'2026-10-15 22:50:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (65,'TX-T9PNBQ','rider',1,'trip',36,'charge','debit',500,'wallet','succeeded','Cancellation fee CB-BUEYWI',NULL,'2026-10-07 07:11:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (66,'TX-Y3XTFB','rider',10,'trip',37,'charge','debit',5531,'card','succeeded','Ride CB-0JULSR',NULL,'2026-10-05 09:34:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (67,'TX-RBMHWY','driver',1,'trip',37,'driver_earning','credit',4625,'system','succeeded','Earnings CB-0JULSR',NULL,'2026-10-05 09:34:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (68,'TX-WYRUR6','rider',16,'trip',38,'charge','debit',3756,'bank_transfer','succeeded','Ride CB-RGJOAB',NULL,'2026-10-14 10:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (69,'TX-KV8UVD','driver',5,'trip',38,'driver_earning','credit',3105,'system','succeeded','Earnings CB-RGJOAB',NULL,'2026-10-14 10:37:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (70,'TX-IDMI3H','rider',15,'trip',39,'charge','debit',3030,'card','succeeded','Ride CB-N4TF2T',NULL,'2026-10-08 15:27:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (71,'TX-ZOSX9G','driver',8,'trip',39,'driver_earning','credit',2424,'system','succeeded','Earnings CB-N4TF2T',NULL,'2026-10-08 15:27:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (72,'TX-TIRII2','rider',1,'trip',40,'charge','debit',2200,'card','succeeded','Ride CB-LZJRT4',NULL,'2026-10-08 22:50:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (73,'TX-EVPWGA','driver',2,'trip',40,'driver_earning','credit',1760,'system','succeeded','Earnings CB-LZJRT4',NULL,'2026-10-08 22:50:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (74,'TX-9QLIST','rider',1,'trip',41,'charge','debit',500,'card','succeeded','Cancellation fee CB-NPP3TB',NULL,'2026-09-27 22:32:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (75,'TX-NVPSBR','rider',10,'trip',42,'charge','debit',1500,'card','succeeded','Ride CB-4FAN7M',NULL,'2026-09-20 14:49:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (76,'TX-ZOLLHG','driver',7,'trip',42,'driver_earning','credit',1200,'system','succeeded','Earnings CB-4FAN7M',NULL,'2026-09-20 14:49:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (77,'TX-8KYWCT','rider',10,'trip',43,'charge','debit',6514,'bank_transfer','succeeded','Ride CB-5SDA2Q',NULL,'2026-09-21 15:21:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (78,'TX-8AKMQN','driver',6,'trip',43,'driver_earning','credit',5211,'system','succeeded','Earnings CB-5SDA2Q',NULL,'2026-09-21 15:21:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (79,'TX-HW58IX','rider',7,'trip',44,'charge','debit',2730,'card','succeeded','Ride CB-LJXFLU',NULL,'2026-09-27 07:04:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (80,'TX-U6JKXU','driver',1,'trip',44,'driver_earning','credit',2384,'system','succeeded','Earnings CB-LJXFLU',NULL,'2026-09-27 07:04:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (81,'TX-Y357CO','rider',10,'trip',45,'charge','debit',5670,'card','succeeded','Ride CB-GQPOD5',NULL,'2026-10-05 15:01:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (82,'TX-F6GXBP','driver',1,'trip',45,'driver_earning','credit',4536,'system','succeeded','Earnings CB-GQPOD5',NULL,'2026-10-05 15:01:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (83,'TX-68722F','rider',1,'trip',46,'charge','debit',6268,'card','succeeded','Ride CB-NQLYIA',NULL,'2026-09-29 20:56:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (84,'TX-GNZTEP','driver',3,'trip',46,'driver_earning','credit',5014,'system','succeeded','Earnings CB-NQLYIA',NULL,'2026-09-29 20:56:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (85,'TX-HOIUH0','rider',1,'trip',47,'charge','debit',2400,'wallet','succeeded','Ride CB-0DPQDV',NULL,'2026-10-01 21:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (86,'TX-PTMIMV','driver',2,'trip',47,'driver_earning','credit',1960,'system','succeeded','Earnings CB-0DPQDV',NULL,'2026-10-01 21:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (87,'TX-GJVJYQ','rider',3,'trip',48,'charge','debit',3200,'wallet','succeeded','Ride CB-LKQALV',NULL,'2026-09-27 15:51:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (88,'TX-ZKSXKK','driver',6,'trip',48,'driver_earning','credit',2560,'system','succeeded','Earnings CB-LKQALV',NULL,'2026-09-27 15:51:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (89,'TX-NJAY17','rider',8,'trip',49,'charge','debit',2154,'bank_transfer','succeeded','Ride CB-9CBM78',NULL,'2026-10-13 22:38:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (90,'TX-PC2QFH','driver',1,'trip',49,'driver_earning','credit',1723,'system','succeeded','Earnings CB-9CBM78',NULL,'2026-10-13 22:38:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (91,'TX-EXCDZ0','rider',7,'trip',50,'charge','debit',1762,'cash','succeeded','Ride CB-QVJNJL',NULL,'2026-10-19 09:55:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (92,'TX-7CFVUP','rider',1,'trip',51,'charge','debit',3572,'cash','succeeded','Ride CB-CUV4YI',NULL,'2026-09-29 12:16:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (93,'TX-YHAZEZ','rider',9,'trip',52,'charge','debit',2000,'wallet','succeeded','Ride CB-03O2Y3',NULL,'2026-10-05 08:05:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (94,'TX-DDRRYV','driver',3,'trip',52,'driver_earning','credit',1700,'system','succeeded','Earnings CB-03O2Y3',NULL,'2026-10-05 08:05:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (95,'TX-SOL239','rider',5,'trip',53,'charge','debit',4194,'cash','succeeded','Ride CB-Z8NLWD',NULL,'2026-10-19 11:01:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (96,'TX-L3YDD2','rider',16,'trip',54,'charge','debit',4641,'card','succeeded','Ride CB-XLX1LG',NULL,'2026-09-20 18:42:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (97,'TX-3XUZNS','driver',4,'trip',54,'driver_earning','credit',3913,'system','succeeded','Earnings CB-XLX1LG',NULL,'2026-09-20 18:42:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (98,'TX-XWYYBP','rider',14,'trip',55,'charge','debit',2450,'bank_transfer','succeeded','Ride CB-DEPQRC',NULL,'2026-09-27 22:32:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (99,'TX-LZFA0D','driver',2,'trip',55,'driver_earning','credit',1960,'system','succeeded','Earnings CB-DEPQRC',NULL,'2026-09-27 22:32:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (100,'TX-NFXSIY','rider',1,'trip',56,'charge','debit',9642,'card','succeeded','Ride CB-LTEO2R',NULL,'2026-09-28 10:14:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (101,'TX-ORQJGL','driver',2,'trip',56,'driver_earning','credit',7714,'system','succeeded','Earnings CB-LTEO2R',NULL,'2026-09-28 10:14:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (102,'TX-HONL1R','rider',7,'trip',57,'charge','debit',3052,'card','succeeded','Ride CB-S26CKY',NULL,'2026-10-03 07:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (103,'TX-PHQT5A','driver',1,'trip',57,'driver_earning','credit',2442,'system','succeeded','Earnings CB-S26CKY',NULL,'2026-10-03 07:59:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (104,'TX-CD4YSM','rider',4,'trip',58,'charge','debit',1500,'cash','succeeded','Ride CB-PGUUXU',NULL,'2026-10-09 19:53:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (105,'TX-GTYABL','rider',10,'trip',59,'charge','debit',4609,'card','succeeded','Ride CB-LQGUC3',NULL,'2026-09-29 10:42:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (106,'TX-SELIAX','driver',1,'trip',59,'driver_earning','credit',3687,'system','succeeded','Earnings CB-LQGUC3',NULL,'2026-09-29 10:42:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (107,'TX-10FMS3','rider',2,'trip',60,'charge','debit',3052,'bank_transfer','succeeded','Ride CB-NXP27R',NULL,'2026-10-16 20:28:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (108,'TX-U5QDOH','driver',4,'trip',60,'driver_earning','credit',2442,'system','succeeded','Earnings CB-NXP27R',NULL,'2026-10-16 20:28:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (109,'TX-B8BKCP','rider',1,'trip',61,'charge','debit',2215,'bank_transfer','succeeded','Ride CB-XL0BPP',NULL,'2026-09-28 21:32:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (110,'TX-SHHXX6','driver',1,'trip',61,'driver_earning','credit',1772,'system','succeeded','Earnings CB-XL0BPP',NULL,'2026-09-28 21:32:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (111,'TX-P2EJSV','rider',7,'trip',62,'charge','debit',1650,'cash','succeeded','Ride CB-XIC5SM',NULL,'2026-10-16 22:04:00','2026-10-19 16:15:21');
INSERT INTO `transactions` VALUES (112,'TX-49KNQL','rider',14,'trip',63,'charge','debit',2501,'bank_transfer','succeeded','Ride CB-M5PCZ9',NULL,'2026-09-20 07:33:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (113,'TX-9WSS46','driver',8,'trip',63,'driver_earning','credit',2001,'system','succeeded','Earnings CB-M5PCZ9',NULL,'2026-09-20 07:33:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (114,'TX-UE3QL8','rider',1,'trip',64,'charge','debit',2200,'card','succeeded','Ride CB-FZN8DS',NULL,'2026-10-05 10:27:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (115,'TX-5FWNPB','driver',8,'trip',64,'driver_earning','credit',1760,'system','succeeded','Earnings CB-FZN8DS',NULL,'2026-10-05 10:27:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (116,'TX-2BYNIC','rider',2,'trip',65,'charge','debit',2700,'card','succeeded','Ride CB-9TRMWM',NULL,'2026-10-18 16:40:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (117,'TX-WTJHKI','driver',1,'trip',65,'driver_earning','credit',2260,'system','succeeded','Earnings CB-9TRMWM',NULL,'2026-10-18 16:40:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (118,'TX-I8X4UL','rider',1,'trip',66,'charge','debit',10776,'cash','succeeded','Ride CB-1TENQT',NULL,'2026-09-21 16:01:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (119,'TX-0KCZ4S','rider',5,'trip',67,'charge','debit',8915,'card','succeeded','Ride CB-F36ROL',NULL,'2026-09-25 23:17:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (120,'TX-2NDVHL','driver',6,'trip',67,'driver_earning','credit',7132,'system','succeeded','Earnings CB-F36ROL',NULL,'2026-09-25 23:17:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (121,'TX-W1LRTB','rider',11,'trip',68,'charge','debit',5653,'cash','succeeded','Ride CB-NEOFD2',NULL,'2026-10-16 21:02:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (122,'TX-IGG0UO','rider',2,'trip',69,'charge','debit',3619,'cash','succeeded','Ride CB-DJ3LKY',NULL,'2026-09-28 17:17:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (123,'TX-PAFVPQ','rider',14,'trip',70,'charge','debit',3732,'cash','succeeded','Ride CB-EOD4UW',NULL,'2026-10-16 21:18:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (124,'TX-I0XXCJ','rider',1,'trip',71,'charge','debit',2462,'card','succeeded','Ride CB-V3JZDE',NULL,'2026-10-16 16:14:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (125,'TX-9VKKP8','driver',5,'trip',71,'driver_earning','credit',1970,'system','succeeded','Earnings CB-V3JZDE',NULL,'2026-10-16 16:14:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (126,'TX-CWWOTX','rider',15,'trip',72,'charge','debit',1510,'card','succeeded','Ride CB-G6UKYA',NULL,'2026-10-07 17:28:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (127,'TX-BECCOA','driver',5,'trip',72,'driver_earning','credit',1208,'system','succeeded','Earnings CB-G6UKYA',NULL,'2026-10-07 17:28:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (128,'TX-YEHJ8P','rider',9,'trip',73,'charge','debit',3256,'card','succeeded','Ride CB-MGCYIP',NULL,'2026-09-27 19:15:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (129,'TX-9DUTDB','driver',1,'trip',73,'driver_earning','credit',2605,'system','succeeded','Earnings CB-MGCYIP',NULL,'2026-09-27 19:15:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (130,'TX-0YDCIQ','rider',6,'trip',74,'charge','debit',1500,'card','succeeded','Ride CB-YARHXI',NULL,'2026-09-30 15:13:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (131,'TX-8AEPA4','driver',5,'trip',74,'driver_earning','credit',1200,'system','succeeded','Earnings CB-YARHXI',NULL,'2026-09-30 15:13:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (132,'TX-5OZ8WU','rider',5,'trip',75,'charge','debit',1700,'wallet','succeeded','Ride CB-QTRZGD',NULL,'2026-09-20 22:18:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (133,'TX-QZQNK7','driver',4,'trip',75,'driver_earning','credit',1400,'system','succeeded','Earnings CB-QTRZGD',NULL,'2026-09-20 22:18:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (134,'TX-OYSQE7','rider',1,'trip',76,'charge','debit',10054,'card','succeeded','Ride CB-MNOJ8I',NULL,'2026-10-03 00:02:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (135,'TX-OTHUSA','driver',3,'trip',76,'driver_earning','credit',8243,'system','succeeded','Earnings CB-MNOJ8I',NULL,'2026-10-03 00:02:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (136,'TX-VT9TFR','rider',7,'trip',77,'charge','debit',1902,'bank_transfer','succeeded','Ride CB-AZXIEW',NULL,'2026-10-08 19:28:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (137,'TX-LOKHNL','driver',1,'trip',77,'driver_earning','credit',1522,'system','succeeded','Earnings CB-AZXIEW',NULL,'2026-10-08 19:28:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (138,'TX-PXAOXW','rider',8,'trip',78,'charge','debit',11944,'card','succeeded','Ride CB-VGDCK5',NULL,'2026-10-09 23:37:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (139,'TX-P9VFWB','driver',6,'trip',78,'driver_earning','credit',9555,'system','succeeded','Earnings CB-VGDCK5',NULL,'2026-10-09 23:37:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (140,'TX-NXDVE8','rider',11,'trip',79,'charge','debit',1591,'bank_transfer','succeeded','Ride CB-LTUYGC',NULL,'2026-10-14 22:19:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (141,'TX-UN99HR','driver',3,'trip',79,'driver_earning','credit',1273,'system','succeeded','Earnings CB-LTUYGC',NULL,'2026-10-14 22:19:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (142,'TX-LCLKZS','rider',8,'trip',80,'charge','debit',2542,'card','succeeded','Ride CB-UC2FM1',NULL,'2026-10-16 13:29:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (143,'TX-GB80PK','driver',4,'trip',80,'driver_earning','credit',2074,'system','succeeded','Earnings CB-UC2FM1',NULL,'2026-10-16 13:29:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (144,'TX-HVT8U2','rider',1,'trip',81,'charge','debit',6118,'wallet','succeeded','Ride CB-Y3VHQY',NULL,'2026-09-23 12:26:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (145,'TX-3R8GRS','driver',1,'trip',81,'driver_earning','credit',4994,'system','succeeded','Earnings CB-Y3VHQY',NULL,'2026-09-23 12:26:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (146,'TX-OYEPVA','rider',2,'trip',82,'charge','debit',2005,'card','succeeded','Ride CB-U16D4M',NULL,'2026-09-22 12:59:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (147,'TX-F8RIIM','driver',8,'trip',82,'driver_earning','credit',1604,'system','succeeded','Earnings CB-U16D4M',NULL,'2026-09-22 12:59:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (148,'TX-SOTYRA','rider',15,'trip',83,'charge','debit',4082,'wallet','succeeded','Ride CB-PSBSSC',NULL,'2026-09-24 11:44:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (149,'TX-IQGYUR','driver',7,'trip',83,'driver_earning','credit',3266,'system','succeeded','Earnings CB-PSBSSC',NULL,'2026-09-24 11:44:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (150,'TX-5IAD8H','rider',4,'trip',84,'charge','debit',6167,'card','succeeded','Ride CB-RJ66OW',NULL,'2026-10-04 21:41:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (151,'TX-OZERBT','driver',8,'trip',84,'driver_earning','credit',4934,'system','succeeded','Earnings CB-RJ66OW',NULL,'2026-10-04 21:41:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (152,'TX-OKL4JC','rider',3,'trip',85,'charge','debit',2608,'card','succeeded','Ride CB-D8RRB2',NULL,'2026-10-08 10:38:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (153,'TX-UA1TNM','driver',1,'trip',85,'driver_earning','credit',2086,'system','succeeded','Earnings CB-D8RRB2',NULL,'2026-10-08 10:38:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (154,'TX-2TUSEM','rider',1,'trip',86,'charge','debit',4660,'card','succeeded','Ride CB-YPKU5G',NULL,'2026-10-18 19:22:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (155,'TX-ULZQAJ','driver',1,'trip',86,'driver_earning','credit',3728,'system','succeeded','Earnings CB-YPKU5G',NULL,'2026-10-18 19:22:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (156,'TX-EAWWTZ','rider',16,'trip',87,'charge','debit',3247,'cash','succeeded','Ride CB-TUVTO9',NULL,'2026-09-29 07:02:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (157,'TX-BCXFAB','rider',9,'trip',88,'charge','debit',3732,'bank_transfer','succeeded','Ride CB-ZUPFBF',NULL,'2026-09-30 08:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (158,'TX-4ZGYVB','driver',8,'trip',88,'driver_earning','credit',2986,'system','succeeded','Earnings CB-ZUPFBF',NULL,'2026-09-30 08:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (159,'TX-VSVCOK','rider',15,'trip',89,'charge','debit',2200,'bank_transfer','succeeded','Ride CB-VBCZCQ',NULL,'2026-10-15 11:21:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (160,'TX-MPAX6D','driver',1,'trip',89,'driver_earning','credit',1760,'system','succeeded','Earnings CB-VBCZCQ',NULL,'2026-10-15 11:21:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (161,'TX-CQNURK','rider',15,'trip',90,'charge','debit',2262,'bank_transfer','succeeded','Ride CB-GFGJBG',NULL,'2026-09-21 18:38:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (162,'TX-P6VXQB','driver',8,'trip',90,'driver_earning','credit',1910,'system','succeeded','Earnings CB-GFGJBG',NULL,'2026-09-21 18:38:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (163,'TX-TYL2SG','rider',1,'shuttle_booking',1,'charge','debit',22000,'card','succeeded','Airport shuttle SH-4NZTKG',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (164,'TX-XJGUPA','rider',3,'shuttle_booking',2,'charge','debit',22000,'card','succeeded','Airport shuttle SH-2X9NAS',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (165,'TX-BHVM9O','rider',5,'shuttle_booking',3,'charge','debit',18000,'card','succeeded','Airport shuttle SH-Q0AS3G',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (166,'TX-5UHSVZ','rider',8,'shuttle_booking',4,'charge','debit',45000,'card','succeeded','Airport shuttle SH-1KGILE',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (167,'TX-YXUMXW','rider',6,'shuttle_booking',5,'charge','debit',16000,'card','succeeded','Airport shuttle SH-FJ38TN',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (168,'TX-9OFELH','rider',1,'tour_booking',1,'charge','debit',45000,'card','succeeded','Tour TR-RYFABO',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (169,'TX-ZJUHTX','rider',3,'tour_booking',2,'charge','debit',30000,'card','succeeded','Tour TR-WMO1TF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (170,'TX-NYXIKM','rider',4,'tour_booking',3,'charge','debit',15000,'bank_transfer','succeeded','Tour TR-ZBTC11',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (171,'TX-DAL0CN','rider',16,'tour_booking',4,'charge','debit',30000,'bank_transfer','succeeded','Tour TR-JL2WHN',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (172,'TX-MFHHIY','rider',1,'tour_booking',5,'wallet_payment','debit',30000,'wallet','succeeded','Tour TR-ACMBCD',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (173,'TX-9T4EFS','rider',15,'tour_booking',6,'charge','debit',15000,'card','succeeded','Tour TR-HECGOU',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (174,'TX-HIL98Q','rider',6,'tour_booking',7,'charge','debit',15000,'card','succeeded','Tour TR-ZGLAWO',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (175,'TX-IAUTDQ','rider',15,'tour_booking',8,'charge','debit',15000,'card','succeeded','Tour TR-ZR81HF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (176,'TX-CX70OE','rider',1,'tour_booking',9,'charge','debit',45000,'card','succeeded','Tour TR-OKYV0A',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (177,'TX-3RHZKM','rider',2,'tour_booking',10,'charge','debit',15000,'bank_transfer','succeeded','Tour TR-ULNXUI',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (178,'TX-F6LIUL','rider',5,'tour_booking',11,'charge','debit',30000,'card','succeeded','Tour TR-Y6POG0',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (179,'TX-YTTHXD','rider',15,'tour_booking',12,'wallet_payment','debit',45000,'wallet','succeeded','Tour TR-ASQRJZ',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (180,'TX-BNEMOV','rider',1,'tour_booking',13,'wallet_payment','debit',30000,'wallet','succeeded','Tour TR-5XIPF8',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (181,'TX-UWCCU4','rider',1,'tour_booking',14,'charge','debit',15000,'bank_transfer','succeeded','Tour TR-REQAOF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (182,'TX-ZFAC7H','rider',11,'tour_booking',15,'charge','debit',30000,'bank_transfer','succeeded','Tour TR-GMCHLM',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (183,'TX-YBBXQL','rider',3,'tour_booking',16,'wallet_payment','debit',45000,'wallet','succeeded','Tour TR-UMODOB',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (184,'TX-I4DIV4','rider',1,'tour_booking',17,'wallet_payment','debit',45000,'wallet','succeeded','Tour TR-LO7CIE',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (185,'TX-PQOE45','rider',16,'tour_booking',18,'charge','debit',50000,'card','succeeded','Tour TR-8NKXLB',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (186,'TX-OQXSAU','rider',8,'tour_booking',19,'wallet_payment','debit',75000,'wallet','succeeded','Tour TR-GJFTKG',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (187,'TX-E6OTQP','rider',12,'tour_booking',20,'wallet_payment','debit',50000,'wallet','succeeded','Tour TR-1ZOPQF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (188,'TX-DVDSOU','rider',1,'tour_booking',21,'charge','debit',50000,'card','succeeded','Tour TR-GK7RQV',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (189,'TX-H8PTIH','rider',5,'tour_booking',22,'charge','debit',25000,'card','succeeded','Tour TR-RE2DXX',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (190,'TX-6FJQR4','rider',8,'tour_booking',23,'wallet_payment','debit',25000,'wallet','succeeded','Tour TR-INIQ3H',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (191,'TX-MHP6IJ','rider',1,'tour_booking',24,'charge','debit',50000,'card','succeeded','Tour TR-6KQKQ2',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (192,'TX-NBMCB7','rider',1,'tour_booking',25,'wallet_payment','debit',50000,'wallet','succeeded','Tour TR-Y0YH4O',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (193,'TX-QMOAY9','rider',11,'tour_booking',26,'charge','debit',50000,'bank_transfer','succeeded','Tour TR-BOS39U',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (194,'TX-YXLPSV','rider',12,'tour_booking',27,'charge','debit',18000,'bank_transfer','succeeded','Tour TR-I6WXG9',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (195,'TX-L9RNJC','rider',1,'tour_booking',28,'wallet_payment','debit',36000,'wallet','succeeded','Tour TR-EKANIU',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (196,'TX-L5Q16X','rider',1,'tour_booking',29,'wallet_payment','debit',54000,'wallet','succeeded','Tour TR-PBSJ8A',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (197,'TX-3U9NOR','rider',14,'tour_booking',30,'wallet_payment','debit',18000,'wallet','succeeded','Tour TR-EUU8WO',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (198,'TX-7DUATL','rider',8,'tour_booking',31,'charge','debit',54000,'card','succeeded','Tour TR-EOXYDG',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (199,'TX-L5CTLN','rider',8,'tour_booking',32,'wallet_payment','debit',18000,'wallet','succeeded','Tour TR-5BF5DS',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (200,'TX-BTVTI2','rider',1,'tour_booking',33,'charge','debit',18000,'card','succeeded','Tour TR-BM9RUI',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (201,'TX-BTDTOQ','rider',7,'tour_booking',34,'wallet_payment','debit',36000,'wallet','succeeded','Tour TR-H8OBRS',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (202,'TX-PCREVB','rider',6,'tour_booking',35,'charge','debit',54000,'card','succeeded','Tour TR-IWLHNF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (203,'TX-QEMS6Z','rider',12,'tour_booking',36,'charge','debit',66000,'card','succeeded','Tour TR-WIBQHD',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (204,'TX-S23REZ','rider',1,'tour_booking',37,'charge','debit',44000,'bank_transfer','succeeded','Tour TR-YCR13G',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (205,'TX-Z2K1TZ','rider',8,'tour_booking',38,'charge','debit',22000,'bank_transfer','succeeded','Tour TR-ZOW3KE',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (206,'TX-OL0QXM','rider',4,'tour_booking',39,'wallet_payment','debit',22000,'wallet','succeeded','Tour TR-4DH1RK',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (207,'TX-CH58CN','rider',5,'tour_booking',40,'wallet_payment','debit',44000,'wallet','succeeded','Tour TR-469PPW',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (208,'TX-3XABHT','rider',1,'tour_booking',41,'charge','debit',22000,'card','succeeded','Tour TR-RL2CW6',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (209,'TX-ELI8HR','rider',11,'tour_booking',42,'charge','debit',66000,'card','succeeded','Tour TR-DAY3XY',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (210,'TX-5V9ZVK','rider',14,'tour_booking',43,'charge','debit',66000,'card','succeeded','Tour TR-3VT4DF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (211,'TX-9ALKKN','rider',2,'tour_booking',44,'charge','debit',22000,'card','succeeded','Tour TR-6NVLCR',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (212,'TX-UBEYL5','rider',1,'tour_booking',45,'charge','debit',22000,'bank_transfer','succeeded','Tour TR-ZFG2ZP',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (213,'TX-2RZYTY','rider',2,'tour_booking',46,'wallet_payment','debit',66000,'wallet','succeeded','Tour TR-QEGBP0',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (214,'TX-1GYTEK','rider',12,'tour_booking',47,'wallet_payment','debit',44000,'wallet','succeeded','Tour TR-RNOT7X',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (215,'TX-DI6ATQ','rider',10,'tour_booking',48,'charge','debit',66000,'card','succeeded','Tour TR-258LTO',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (216,'TX-U3HTTG','rider',1,'tour_booking',49,'charge','debit',22000,'card','succeeded','Tour TR-O3SSDX',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (217,'TX-W1KUNS','rider',14,'tour_booking',50,'charge','debit',66000,'card','succeeded','Tour TR-JRIEKX',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (218,'TX-WUKYAT','rider',6,'tour_booking',51,'wallet_payment','debit',22000,'wallet','succeeded','Tour TR-QJFCUN',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (219,'TX-1SZLIM','rider',9,'tour_booking',52,'charge','debit',22000,'bank_transfer','succeeded','Tour TR-RHMVYT',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (220,'TX-7GILUH','rider',1,'tour_booking',53,'charge','debit',30000,'bank_transfer','succeeded','Tour TR-MWEWRW',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (221,'TX-N9OVQC','rider',10,'tour_booking',54,'wallet_payment','debit',30000,'wallet','succeeded','Tour TR-MP6JWY',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (222,'TX-9BKTF4','rider',4,'tour_booking',55,'charge','debit',90000,'card','succeeded','Tour TR-4HNLF2',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (223,'TX-TX2N3N','rider',3,'tour_booking',56,'wallet_payment','debit',90000,'wallet','succeeded','Tour TR-NC0JMW',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (224,'TX-BAD61R','rider',1,'tour_booking',57,'charge','debit',90000,'card','succeeded','Tour TR-H9O1BY',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (225,'TX-K5HWWN','rider',16,'tour_booking',58,'charge','debit',60000,'card','succeeded','Tour TR-JOXIH3',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (226,'TX-F501FN','rider',7,'tour_booking',59,'charge','debit',60000,'card','succeeded','Tour TR-ZI0MYJ',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (227,'TX-VE4Y4Q','rider',8,'tour_booking',60,'charge','debit',90000,'card','succeeded','Tour TR-G5YVFC',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (228,'TX-7GY1WR','rider',1,'tour_booking',61,'charge','debit',60000,'bank_transfer','succeeded','Tour TR-U4LMKL',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (229,'TX-QNBGUB','rider',1,'tour_booking',62,'wallet_payment','debit',12000,'wallet','succeeded','Tour TR-FFAVD4',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (230,'TX-NVOVD1','rider',2,'tour_booking',63,'charge','debit',24000,'bank_transfer','succeeded','Tour TR-ZGTSNM',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (231,'TX-4NGXOG','rider',8,'tour_booking',64,'charge','debit',24000,'card','succeeded','Tour TR-WWMAMR',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (232,'TX-0Z7TWY','rider',1,'tour_booking',65,'wallet_payment','debit',24000,'wallet','succeeded','Tour TR-0ZALYU',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (233,'TX-UIJQZE','rider',10,'tour_booking',66,'charge','debit',24000,'bank_transfer','succeeded','Tour TR-JNRRAZ',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (234,'TX-ALXA2U','rider',9,'tour_booking',67,'charge','debit',12000,'bank_transfer','succeeded','Tour TR-CVLQ5F',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (235,'TX-B0AND2','rider',14,'tour_booking',68,'charge','debit',24000,'bank_transfer','succeeded','Tour TR-I2CFUU',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (236,'TX-LTIUST','rider',1,'tour_booking',69,'wallet_payment','debit',12000,'wallet','succeeded','Tour TR-AQPEJC',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (237,'TX-TPGN6I','rider',5,'tour_booking',70,'charge','debit',24000,'card','succeeded','Tour TR-01ZHBI',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (238,'TX-HFAG9D','rider',6,'tour_booking',71,'charge','debit',36000,'card','succeeded','Tour TR-ECKL6B',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (239,'TX-ASXFE5','rider',15,'tour_booking',72,'charge','debit',24000,'card','succeeded','Tour TR-DZABIF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (240,'TX-UDAOO3','rider',1,'tour_booking',73,'charge','debit',36000,'card','succeeded','Tour TR-YGESE5',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (241,'TX-QBJXAF','rider',16,'tour_booking',74,'charge','debit',36000,'bank_transfer','succeeded','Tour TR-TSTKXQ',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (242,'TX-KBC7ZV','rider',15,'tour_booking',75,'wallet_payment','debit',24000,'wallet','succeeded','Tour TR-FXQLEF',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (243,'TX-LMKSFR','rider',1,'tour_booking',76,'charge','debit',12000,'card','succeeded','Tour TR-0BM7HG',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (244,'TX-XXGGTF','rider',1,'tour_booking',77,'charge','debit',12000,'bank_transfer','succeeded','Tour TR-TYDHKH',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (245,'TX-YI3WEG','rider',14,'tour_booking',78,'charge','debit',12000,'bank_transfer','succeeded','Tour TR-KPLWHK',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (246,'TX-OTR3VO','driver',1,'payout',1,'payout','debit',127000,'bank_transfer','succeeded','Weekly payout PO-VGE48W',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (247,'TX-ATGSJX','driver',1,'payout',2,'payout','debit',77000,'bank_transfer','succeeded','Weekly payout PO-8JQUS2',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (248,'TX-5CPK5S','driver',1,'payout',3,'payout','debit',81000,'bank_transfer','succeeded','Weekly payout PO-ADDPLX',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (249,'TX-S99WMH','driver',1,'payout',4,'payout','debit',130000,'bank_transfer','succeeded','Weekly payout PO-B3IOQG',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (250,'TX-9YLCHM','driver',2,'payout',5,'payout','debit',110000,'bank_transfer','succeeded','Weekly payout PO-FX9DBL',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (251,'TX-OMMDL0','driver',2,'payout',6,'payout','debit',49000,'bank_transfer','succeeded','Weekly payout PO-SGO0YS',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (252,'TX-91Z86Z','driver',2,'payout',7,'payout','debit',86000,'bank_transfer','succeeded','Weekly payout PO-JS1SOX',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (253,'TX-N7LH58','driver',2,'payout',8,'payout','debit',76000,'bank_transfer','succeeded','Weekly payout PO-2O7H5M',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (254,'TX-R7H4PL','driver',3,'payout',9,'payout','debit',66000,'bank_transfer','succeeded','Weekly payout PO-ZH0NG8',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (255,'TX-AMS1HN','driver',3,'payout',10,'payout','debit',71000,'bank_transfer','succeeded','Weekly payout PO-5Z7T3Y',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (256,'TX-B1BQSV','driver',3,'payout',11,'payout','debit',125000,'bank_transfer','succeeded','Weekly payout PO-QWWEM7',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (257,'TX-LXDQIZ','driver',3,'payout',12,'payout','debit',77000,'bank_transfer','succeeded','Weekly payout PO-LRLEE6',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (258,'TX-ZMYAFG','driver',4,'payout',13,'payout','debit',50000,'bank_transfer','succeeded','Weekly payout PO-7K9ED7',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (259,'TX-BCZMGU','driver',4,'payout',14,'payout','debit',97000,'bank_transfer','succeeded','Weekly payout PO-4XWAQ6',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (260,'TX-ORDZDR','driver',4,'payout',15,'payout','debit',76000,'bank_transfer','succeeded','Weekly payout PO-UIMS1W',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (261,'TX-CH1WNW','driver',4,'payout',16,'payout','debit',114000,'bank_transfer','succeeded','Weekly payout PO-PUN0VZ',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (262,'TX-OG85DG','driver',5,'payout',17,'payout','debit',100000,'bank_transfer','succeeded','Weekly payout PO-WDSI90',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (263,'TX-FYA6BU','driver',5,'payout',18,'payout','debit',81000,'bank_transfer','succeeded','Weekly payout PO-EGYIRO',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (264,'TX-ONOCEK','driver',5,'payout',19,'payout','debit',114000,'bank_transfer','succeeded','Weekly payout PO-NPADCQ',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (265,'TX-QJI15D','driver',5,'payout',20,'payout','debit',45000,'bank_transfer','succeeded','Weekly payout PO-DCJD3S',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (266,'TX-1BW6QC','driver',6,'payout',21,'payout','debit',76000,'bank_transfer','succeeded','Weekly payout PO-3ZOIEH',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (267,'TX-UAXDQH','driver',6,'payout',22,'payout','debit',55000,'bank_transfer','succeeded','Weekly payout PO-QGYRMR',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (268,'TX-SD37R1','driver',6,'payout',23,'payout','debit',84000,'bank_transfer','succeeded','Weekly payout PO-T9ZLRI',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (269,'TX-YYMHEK','driver',6,'payout',24,'payout','debit',66000,'bank_transfer','succeeded','Weekly payout PO-UAERAY',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (270,'TX-X8F9XP','driver',7,'payout',25,'payout','debit',126000,'bank_transfer','succeeded','Weekly payout PO-N1YUJA',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (271,'TX-XJW8R3','driver',7,'payout',26,'payout','debit',92000,'bank_transfer','succeeded','Weekly payout PO-IFUUWD',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (272,'TX-KRQXQH','driver',7,'payout',27,'payout','debit',46000,'bank_transfer','succeeded','Weekly payout PO-LUOVJ5',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (273,'TX-0WBPBB','driver',7,'payout',28,'payout','debit',55000,'bank_transfer','succeeded','Weekly payout PO-SNDUOE',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (274,'TX-2WJSTK','driver',8,'payout',29,'payout','debit',93000,'bank_transfer','succeeded','Weekly payout PO-TYBQRO',NULL,'2026-10-20 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (275,'TX-ZFW0CC','driver',8,'payout',30,'payout','debit',104000,'bank_transfer','succeeded','Weekly payout PO-1QKORP',NULL,'2026-10-13 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (276,'TX-4S6MJL','driver',8,'payout',31,'payout','debit',128000,'bank_transfer','succeeded','Weekly payout PO-FS9G1N',NULL,'2026-10-06 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (277,'TX-YFKUWZ','driver',8,'payout',32,'payout','debit',88000,'bank_transfer','succeeded','Weekly payout PO-CNVDYV',NULL,'2026-09-29 10:00:00','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (278,'TX-EDT5VX','rider',1,NULL,NULL,'wallet_topup','credit',35000,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (279,'TX-SYXEDF','rider',2,NULL,NULL,'wallet_topup','credit',18000,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (280,'TX-ZEPWCZ','rider',4,NULL,NULL,'wallet_topup','credit',13500,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (281,'TX-FQ3V0X','rider',6,NULL,NULL,'wallet_topup','credit',22000,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (282,'TX-WPNXPU','rider',8,NULL,NULL,'wallet_topup','credit',50000,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (283,'TX-EF3AXN','rider',9,NULL,NULL,'wallet_topup','credit',11500,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (284,'TX-LUOHB4','rider',11,NULL,NULL,'wallet_topup','credit',16000,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (285,'TX-OSTIRA','rider',14,NULL,NULL,'wallet_topup','credit',25000,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `transactions` VALUES (286,'TX-CAIV34','rider',15,NULL,NULL,'wallet_topup','credit',12000,'card','succeeded','Wallet top-up',NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `transactions` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `trips` WRITE;
/*!40000 ALTER TABLE `trips` DISABLE KEYS */;
INSERT INTO `trips` VALUES (1,'CB-D5OGC2',1,1,1,2,'completed','Terra Kulture, Victoria Island',6.4335000,3.4229000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'2039',13.28,37,1.20,1000,2258,1036,0,0,0,5153,0,1031,4122,0,NULL,'wallet','paid',NULL,NULL,5,5,NULL,'Emeka was very friendly and the car was spotless.',NULL,NULL,'2026-10-14 20:52:00','2026-10-14 20:58:00','2026-10-14 21:00:00','2026-10-14 21:37:00',NULL,'2026-10-14 20:51:00','2026-10-14 20:51:00');
INSERT INTO `trips` VALUES (2,'CB-QPCV0P',12,5,5,2,'completed','Terra Kulture, Victoria Island',6.4335000,3.4229000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'3420',7.73,22,1.20,1000,1314,616,0,250,0,3766,0,753,3013,0,NULL,'card','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-10 18:35:00','2026-10-10 18:41:00','2026-10-10 18:43:00','2026-10-10 19:05:00',NULL,'2026-10-10 18:34:00','2026-10-10 18:34:00');
INSERT INTO `trips` VALUES (3,'CB-WYOYBO',9,1,1,2,'completed','Tarzan Jetty, Victoria Island',6.4268000,3.4291000,'Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,NULL,NULL,'3038',0.50,3,1.20,1000,85,84,0,0,0,2200,200,440,1960,0,NULL,'bank_transfer','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-10-18 22:03:00','2026-10-18 22:09:00','2026-10-18 22:11:00','2026-10-18 22:14:00',NULL,'2026-10-18 22:02:00','2026-10-18 22:02:00');
INSERT INTO `trips` VALUES (4,'CB-3RWEOD',16,4,4,1,'completed','Lekki Conservation Centre, Lekki',6.4413000,3.5357000,'The Wheatbaker, Ikoyi',6.4473000,3.4337000,NULL,NULL,'7110',15.24,42,1.00,700,1829,840,0,250,0,3619,0,724,2895,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-18 18:14:00','2026-10-18 18:20:00','2026-10-18 18:22:00','2026-10-18 19:04:00',NULL,'2026-10-18 18:13:00','2026-10-18 18:13:00');
INSERT INTO `trips` VALUES (5,'CB-VZNTI9',4,1,1,2,'completed','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'Terra Kulture, Victoria Island',6.4335000,3.4229000,NULL,NULL,'2198',1.36,4,1.20,1000,231,112,0,0,0,2200,0,440,1760,0,NULL,'card','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-10-08 20:48:00','2026-10-08 20:54:00','2026-10-08 20:56:00','2026-10-08 21:00:00',NULL,'2026-10-08 20:47:00','2026-10-08 20:47:00');
INSERT INTO `trips` VALUES (6,'CB-1AQ5BD',1,7,7,1,'completed','Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,'Nike Art Gallery, Lekki Phase 1',6.4371000,3.4848000,NULL,NULL,'9291',8.47,24,1.00,700,1016,480,0,250,0,2446,200,489,2157,0,NULL,'card','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-10-07 15:28:00','2026-10-07 15:34:00','2026-10-07 15:36:00','2026-10-07 16:00:00',NULL,'2026-10-07 15:27:00','2026-10-07 15:27:00');
INSERT INTO `trips` VALUES (7,'CB-BXKEYG',2,2,2,2,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'2811',8.28,23,1.00,1000,1408,644,0,0,0,3052,200,610,2642,0,NULL,'cash','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-11 09:07:00','2026-10-11 09:13:00','2026-10-11 09:15:00','2026-10-11 09:38:00',NULL,'2026-10-11 09:06:00','2026-10-11 09:06:00');
INSERT INTO `trips` VALUES (8,'CB-TLPHLO',3,8,8,2,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Tarzan Jetty, Victoria Island',6.4268000,3.4291000,NULL,NULL,'3629',14.56,40,1.00,1000,2475,1120,0,0,0,4595,500,919,4176,0,NULL,'bank_transfer','paid',NULL,NULL,5,4,NULL,NULL,NULL,NULL,'2026-09-27 19:04:00','2026-09-27 19:10:00','2026-09-27 19:12:00','2026-09-27 19:52:00',NULL,'2026-09-27 19:03:00','2026-09-27 19:03:00');
INSERT INTO `trips` VALUES (9,'CB-M25E77',2,1,1,1,'cancelled','Freedom Park, Lagos Island',6.4527000,3.3937000,'Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,NULL,NULL,'3623',5.42,15,1.00,700,650,300,0,0,0,0,0,0,0,500,NULL,'wallet','paid','rider','Plans changed',NULL,NULL,NULL,NULL,NULL,NULL,'2026-09-29 11:55:00',NULL,NULL,NULL,'2026-09-29 11:58:00','2026-09-29 11:54:00','2026-09-29 11:54:00');
INSERT INTO `trips` VALUES (10,'CB-I6KTGR',16,2,2,2,'cancelled','The Palms Shopping Mall, Lekki',6.4359000,3.4510000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'4437',16.04,44,1.00,1000,2727,1232,0,0,0,0,0,0,0,500,NULL,'bank_transfer','paid','rider','Plans changed',NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-15 09:13:00',NULL,NULL,NULL,'2026-10-15 09:16:00','2026-10-15 09:12:00','2026-10-15 09:12:00');
INSERT INTO `trips` VALUES (11,'CB-T6M45P',1,5,5,2,'completed','Yaba Tech, Yaba',6.5180000,3.3740000,'Nike Art Gallery, Lekki Phase 1',6.4371000,3.4848000,NULL,NULL,'5245',20.51,56,1.00,1000,3487,1568,0,250,0,6305,0,1261,5044,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-15 17:26:00','2026-10-15 17:32:00','2026-10-15 17:34:00','2026-10-15 18:30:00',NULL,'2026-10-15 17:25:00','2026-10-15 17:25:00');
INSERT INTO `trips` VALUES (12,'CB-JDRFVK',16,5,5,1,'cancelled','National Stadium, Surulere',6.4997000,3.3647000,'Terra Kulture, Victoria Island',6.4335000,3.4229000,NULL,NULL,'4696',13.20,36,1.00,700,1584,720,0,0,0,0,0,0,0,500,NULL,'wallet','paid','rider','Plans changed',NULL,NULL,NULL,NULL,NULL,NULL,'2026-09-29 10:50:00',NULL,NULL,NULL,'2026-09-29 10:53:00','2026-09-29 10:49:00','2026-09-29 10:49:00');
INSERT INTO `trips` VALUES (13,'CB-ICIQEO',10,1,1,1,'completed','Terra Kulture, Victoria Island',6.4335000,3.4229000,'Freedom Park, Lagos Island',6.4527000,3.3937000,NULL,NULL,'4665',5.22,15,1.20,700,626,300,0,0,0,1951,0,390,1561,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-03 06:23:00','2026-10-03 06:29:00','2026-10-03 06:31:00','2026-10-03 06:46:00',NULL,'2026-10-03 06:22:00','2026-10-03 06:22:00');
INSERT INTO `trips` VALUES (14,'CB-4E8GMY',10,5,5,1,'completed','Landmark Beach, Oniru',6.4210000,3.4430000,'Terra Kulture, Victoria Island',6.4335000,3.4229000,NULL,NULL,'4345',3.54,10,1.20,700,425,200,0,0,0,1590,0,318,1272,0,NULL,'bank_transfer','paid',NULL,NULL,5,3,NULL,NULL,NULL,NULL,'2026-10-14 21:40:00','2026-10-14 21:46:00','2026-10-14 21:48:00','2026-10-14 21:58:00',NULL,'2026-10-14 21:39:00','2026-10-14 21:39:00');
INSERT INTO `trips` VALUES (15,'CB-KTCZZ3',11,7,7,1,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'1613',1.53,5,1.00,700,184,100,0,0,0,1500,0,300,1200,0,NULL,'wallet','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-10-12 19:24:00','2026-10-12 19:30:00','2026-10-12 19:32:00','2026-10-12 19:37:00',NULL,'2026-10-12 19:23:00','2026-10-12 19:23:00');
INSERT INTO `trips` VALUES (16,'CB-WCUBPG',1,8,8,1,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'Tarzan Jetty, Victoria Island',6.4268000,3.4291000,NULL,NULL,'5510',7.21,20,1.00,700,865,400,0,250,0,2215,0,443,1772,0,NULL,'card','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-09-30 09:13:00','2026-09-30 09:19:00','2026-09-30 09:21:00','2026-09-30 09:41:00',NULL,'2026-09-30 09:12:00','2026-09-30 09:12:00');
INSERT INTO `trips` VALUES (17,'CB-8ZZYEQ',7,1,1,1,'completed','The Palms Shopping Mall, Lekki',6.4359000,3.4510000,'Freedom Park, Lagos Island',6.4527000,3.3937000,NULL,NULL,'7924',8.91,25,1.00,700,1069,500,0,0,0,2269,0,454,1815,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-09-21 06:07:00','2026-09-21 06:13:00','2026-09-21 06:15:00','2026-09-21 06:40:00',NULL,'2026-09-21 06:06:00','2026-09-21 06:06:00');
INSERT INTO `trips` VALUES (18,'CB-73KQWR',15,1,1,1,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'1437',8.16,23,1.00,700,979,460,0,0,0,2139,1000,428,2711,0,NULL,'bank_transfer','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-09-29 14:48:00','2026-09-29 14:54:00','2026-09-29 14:56:00','2026-09-29 15:19:00',NULL,'2026-09-29 14:47:00','2026-09-29 14:47:00');
INSERT INTO `trips` VALUES (19,'CB-4YSOVV',9,4,4,2,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'Tarzan Jetty, Victoria Island',6.4268000,3.4291000,NULL,NULL,'7753',14.64,40,1.00,1000,2489,1120,0,0,0,4609,0,922,3687,0,NULL,'wallet','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-10-05 13:36:00','2026-10-05 13:42:00','2026-10-05 13:44:00','2026-10-05 14:24:00',NULL,'2026-10-05 13:35:00','2026-10-05 13:35:00');
INSERT INTO `trips` VALUES (20,'CB-M1AMBN',8,7,7,1,'completed','The Palms Shopping Mall, Lekki',6.4359000,3.4510000,'Landmark Beach, Oniru',6.4210000,3.4430000,NULL,NULL,'1905',2.54,7,1.00,700,305,140,0,0,0,1500,0,300,1200,0,NULL,'wallet','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-15 16:22:00','2026-10-15 16:28:00','2026-10-15 16:30:00','2026-10-15 16:37:00',NULL,'2026-10-15 16:21:00','2026-10-15 16:21:00');
INSERT INTO `trips` VALUES (21,'CB-GVBVPU',1,1,1,1,'completed','Terra Kulture, Victoria Island',6.4335000,3.4229000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'4160',13.28,37,1.20,700,1594,740,0,0,0,3641,0,728,2913,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-09 10:22:00','2026-10-09 10:28:00','2026-10-09 10:30:00','2026-10-09 11:07:00',NULL,'2026-10-09 10:21:00','2026-10-09 10:21:00');
INSERT INTO `trips` VALUES (22,'CB-UYOT7N',12,4,4,1,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,NULL,'5784',18.15,50,1.00,700,2178,1000,0,250,0,4128,500,826,3802,0,NULL,'card','paid',NULL,NULL,NULL,3,NULL,NULL,NULL,NULL,'2026-10-13 12:01:00','2026-10-13 12:07:00','2026-10-13 12:09:00','2026-10-13 12:59:00',NULL,'2026-10-13 12:00:00','2026-10-13 12:00:00');
INSERT INTO `trips` VALUES (23,'CB-CSVAIW',16,3,3,2,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'2536',18.58,51,1.00,1000,3159,1428,0,250,0,5837,0,1167,4670,0,NULL,'wallet','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-09-21 06:18:00','2026-09-21 06:24:00','2026-09-21 06:26:00','2026-09-21 07:17:00',NULL,'2026-09-21 06:17:00','2026-09-21 06:17:00');
INSERT INTO `trips` VALUES (24,'CB-OTULDE',8,4,4,2,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'0101',17.93,49,1.00,1000,3048,1372,0,250,0,5670,0,1134,4536,0,NULL,'wallet','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-12 21:35:00','2026-10-12 21:41:00','2026-10-12 21:43:00','2026-10-12 22:32:00',NULL,'2026-10-12 21:34:00','2026-10-12 21:34:00');
INSERT INTO `trips` VALUES (25,'CB-7JHV9H',8,1,1,2,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'7934',18.58,51,1.00,1000,3159,1428,0,250,0,5837,0,1167,4670,0,NULL,'card','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-04 18:23:00','2026-10-04 18:29:00','2026-10-04 18:31:00','2026-10-04 19:22:00',NULL,'2026-10-04 18:22:00','2026-10-04 18:22:00');
INSERT INTO `trips` VALUES (26,'CB-X80QXG',1,6,6,3,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'Landmark Beach, Oniru',6.4210000,3.4430000,NULL,NULL,'9066',8.76,24,1.00,1500,2102,912,0,0,0,4514,0,903,3611,0,NULL,'card','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-11 07:27:00','2026-10-11 07:33:00','2026-10-11 07:35:00','2026-10-11 07:59:00',NULL,'2026-10-11 07:26:00','2026-10-11 07:26:00');
INSERT INTO `trips` VALUES (27,'CB-UVSUQZ',8,7,7,1,'completed','Lekki Conservation Centre, Lekki',6.4413000,3.5357000,'Freedom Park, Lagos Island',6.4527000,3.3937000,NULL,NULL,'7236',21.25,58,1.00,700,2550,1160,0,250,0,4660,0,932,3728,0,NULL,'card','paid',NULL,NULL,4,NULL,NULL,NULL,NULL,NULL,'2026-10-15 12:00:00','2026-10-15 12:06:00','2026-10-15 12:08:00','2026-10-15 13:06:00',NULL,'2026-10-15 11:59:00','2026-10-15 11:59:00');
INSERT INTO `trips` VALUES (28,'CB-OCLFRL',3,2,2,2,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'0944',18.58,51,1.00,1000,3159,1428,0,250,0,5837,0,1167,4670,0,NULL,'wallet','paid',NULL,NULL,5,4,NULL,NULL,NULL,NULL,'2026-09-23 20:06:00','2026-09-23 20:12:00','2026-09-23 20:14:00','2026-09-23 21:05:00',NULL,'2026-09-23 20:05:00','2026-09-23 20:05:00');
INSERT INTO `trips` VALUES (29,'CB-9K58LM',6,1,1,1,'completed','Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,'The Wheatbaker, Ikoyi',6.4473000,3.4337000,NULL,NULL,'7904',0.90,3,1.00,700,108,60,0,0,0,1500,1000,300,2200,0,NULL,'card','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-13 22:31:00','2026-10-13 22:37:00','2026-10-13 22:39:00','2026-10-13 22:42:00',NULL,'2026-10-13 22:30:00','2026-10-13 22:30:00');
INSERT INTO `trips` VALUES (30,'CB-OWL13L',8,8,8,2,'completed','Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'5220',12.51,35,1.00,1000,2127,980,0,0,0,4107,0,821,3286,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-19 11:08:00','2026-10-19 11:14:00','2026-10-19 11:16:00','2026-10-19 11:51:00',NULL,'2026-10-19 11:07:00','2026-10-19 11:07:00');
INSERT INTO `trips` VALUES (31,'CB-OBKOCG',1,1,1,2,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,NULL,'0151',18.15,50,1.00,1000,3086,1400,0,250,0,5736,0,1147,4589,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-10 14:22:00','2026-10-10 14:28:00','2026-10-10 14:30:00','2026-10-10 15:20:00',NULL,'2026-10-10 14:21:00','2026-10-10 14:21:00');
INSERT INTO `trips` VALUES (32,'CB-EZFF5M',10,2,2,4,'completed','The Palms Shopping Mall, Lekki',6.4359000,3.4510000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'2592',3.68,11,1.00,2200,1325,605,0,250,0,5050,0,1010,4040,0,NULL,'card','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-09-20 19:19:00','2026-09-20 19:25:00','2026-09-20 19:27:00','2026-09-20 19:38:00',NULL,'2026-09-20 19:18:00','2026-09-20 19:18:00');
INSERT INTO `trips` VALUES (33,'CB-YL3G2U',1,1,1,2,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'3934',1.53,5,1.00,1000,260,140,0,0,0,2200,0,440,1760,0,NULL,'cash','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-10-03 10:15:00','2026-10-03 10:21:00','2026-10-03 10:23:00','2026-10-03 10:28:00',NULL,'2026-10-03 10:14:00','2026-10-03 10:14:00');
INSERT INTO `trips` VALUES (34,'CB-IRHO4I',7,7,7,1,'completed','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'Terra Kulture, Victoria Island',6.4335000,3.4229000,NULL,NULL,'5359',1.36,4,1.20,700,163,80,0,0,0,1500,0,300,1200,0,NULL,'wallet','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-10-05 12:29:00','2026-10-05 12:35:00','2026-10-05 12:37:00','2026-10-05 12:41:00',NULL,'2026-10-05 12:28:00','2026-10-05 12:28:00');
INSERT INTO `trips` VALUES (35,'CB-29MBPO',9,2,2,2,'completed','Lekki Conservation Centre, Lekki',6.4413000,3.5357000,'Landmark Beach, Oniru',6.4210000,3.4430000,NULL,NULL,'0016',14.16,39,1.00,1000,2407,1092,0,250,0,4749,500,950,4299,0,NULL,'cash','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-15 22:03:00','2026-10-15 22:09:00','2026-10-15 22:11:00','2026-10-15 22:50:00',NULL,'2026-10-15 22:02:00','2026-10-15 22:02:00');
INSERT INTO `trips` VALUES (36,'CB-BUEYWI',1,1,1,1,'cancelled','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'Terra Kulture, Victoria Island',6.4335000,3.4229000,NULL,NULL,'0398',1.36,4,1.20,700,163,80,0,0,0,0,0,0,0,500,NULL,'wallet','paid','rider','Plans changed',NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-07 07:08:00',NULL,NULL,NULL,'2026-10-07 07:11:00','2026-10-07 07:07:00','2026-10-07 07:07:00');
INSERT INTO `trips` VALUES (37,'CB-0JULSR',10,1,1,1,'completed','Yaba Tech, Yaba',6.5180000,3.3740000,'Nike Art Gallery, Lekki Phase 1',6.4371000,3.4848000,NULL,NULL,'6505',20.51,56,1.00,700,2461,1120,0,250,0,4531,1000,906,4625,0,NULL,'card','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-10-05 08:30:00','2026-10-05 08:36:00','2026-10-05 08:38:00','2026-10-05 09:34:00',NULL,'2026-10-05 08:29:00','2026-10-05 08:29:00');
INSERT INTO `trips` VALUES (38,'CB-RGJOAB',16,5,5,1,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,NULL,NULL,'6193',14.63,40,1.00,700,1756,800,0,0,0,3256,500,651,3105,0,NULL,'bank_transfer','paid',NULL,NULL,5,3,NULL,NULL,NULL,NULL,'2026-10-14 09:49:00','2026-10-14 09:55:00','2026-10-14 09:57:00','2026-10-14 10:37:00',NULL,'2026-10-14 09:48:00','2026-10-14 09:48:00');
INSERT INTO `trips` VALUES (39,'CB-N4TF2T',15,8,8,1,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'Freedom Park, Lagos Island',6.4527000,3.3937000,NULL,NULL,'7473',11.83,33,1.00,700,1420,660,0,250,0,3030,0,606,2424,0,NULL,'card','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-08 14:46:00','2026-10-08 14:52:00','2026-10-08 14:54:00','2026-10-08 15:27:00',NULL,'2026-10-08 14:45:00','2026-10-08 14:45:00');
INSERT INTO `trips` VALUES (40,'CB-LZJRT4',1,2,2,2,'completed','The Wheatbaker, Ikoyi',6.4473000,3.4337000,'Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,NULL,NULL,'3161',0.90,3,1.00,1000,153,84,0,0,0,2200,0,440,1760,0,NULL,'card','paid',NULL,NULL,5,3,NULL,NULL,NULL,NULL,'2026-10-08 22:39:00','2026-10-08 22:45:00','2026-10-08 22:47:00','2026-10-08 22:50:00',NULL,'2026-10-08 22:38:00','2026-10-08 22:38:00');
INSERT INTO `trips` VALUES (41,'CB-NPP3TB',1,1,1,1,'cancelled','Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,'Nike Art Gallery, Lekki Phase 1',6.4371000,3.4848000,NULL,NULL,'5865',8.47,24,1.00,700,1016,480,0,250,0,0,0,0,0,500,NULL,'card','paid','rider','Plans changed',NULL,NULL,NULL,NULL,NULL,NULL,'2026-09-27 22:29:00',NULL,NULL,NULL,'2026-09-27 22:32:00','2026-09-27 22:28:00','2026-09-27 22:28:00');
INSERT INTO `trips` VALUES (42,'CB-4FAN7M',10,7,7,1,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'0659',1.53,5,1.00,700,184,100,0,0,0,1500,0,300,1200,0,NULL,'card','paid',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-09-20 14:36:00','2026-09-20 14:42:00','2026-09-20 14:44:00','2026-09-20 14:49:00',NULL,'2026-09-20 14:35:00','2026-09-20 14:35:00');
INSERT INTO `trips` VALUES (43,'CB-5SDA2Q',10,6,6,3,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Tarzan Jetty, Victoria Island',6.4268000,3.4291000,NULL,NULL,'6062',14.56,40,1.00,1500,3494,1520,0,0,0,6514,0,1303,5211,0,NULL,'bank_transfer','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-09-21 14:33:00','2026-09-21 14:39:00','2026-09-21 14:41:00','2026-09-21 15:21:00',NULL,'2026-09-21 14:32:00','2026-09-21 14:32:00');
INSERT INTO `trips` VALUES (44,'CB-LJXFLU',7,1,1,1,'completed','Landmark Beach, Oniru',6.4210000,3.4430000,'The Wheatbaker, Ikoyi',6.4473000,3.4337000,NULL,NULL,'2735',4.18,12,1.20,700,502,240,0,0,0,1730,1000,346,2384,0,NULL,'card','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-09-27 06:44:00','2026-09-27 06:50:00','2026-09-27 06:52:00','2026-09-27 07:04:00',NULL,'2026-09-27 06:43:00','2026-09-27 06:43:00');
INSERT INTO `trips` VALUES (45,'CB-GQPOD5',10,1,1,2,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'6378',17.93,49,1.00,1000,3048,1372,0,250,0,5670,0,1134,4536,0,NULL,'card','paid',NULL,NULL,4,NULL,NULL,NULL,NULL,NULL,'2026-10-05 14:04:00','2026-10-05 14:10:00','2026-10-05 14:12:00','2026-10-05 15:01:00',NULL,'2026-10-05 14:03:00','2026-10-05 14:03:00');
INSERT INTO `trips` VALUES (46,'CB-NQLYIA',1,3,3,3,'completed','The Wheatbaker, Ikoyi',6.4473000,3.4337000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,NULL,'1889',13.85,38,1.00,1500,3324,1444,0,0,0,6268,0,1254,5014,0,NULL,'card','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-09-29 20:10:00','2026-09-29 20:16:00','2026-09-29 20:18:00','2026-09-29 20:56:00',NULL,'2026-09-29 20:09:00','2026-09-29 20:09:00');
INSERT INTO `trips` VALUES (47,'CB-0DPQDV',1,2,2,2,'completed','Tarzan Jetty, Victoria Island',6.4268000,3.4291000,'Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,NULL,NULL,'9287',0.50,3,1.20,1000,85,84,0,0,0,2200,200,440,1960,0,NULL,'wallet','paid',NULL,NULL,5,4,NULL,NULL,NULL,NULL,'2026-10-01 21:48:00','2026-10-01 21:54:00','2026-10-01 21:56:00','2026-10-01 21:59:00',NULL,'2026-10-01 21:47:00','2026-10-01 21:47:00');
INSERT INTO `trips` VALUES (48,'CB-LKQALV',3,6,6,3,'completed','Yaba Tech, Yaba',6.5180000,3.3740000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'5041',3.08,9,1.00,1500,739,342,0,0,0,3200,0,640,2560,0,NULL,'wallet','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-09-27 15:34:00','2026-09-27 15:40:00','2026-09-27 15:42:00','2026-09-27 15:51:00',NULL,'2026-09-27 15:33:00','2026-09-27 15:33:00');
INSERT INTO `trips` VALUES (49,'CB-9CBM78',8,1,1,1,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'6002',8.28,23,1.00,700,994,460,0,0,0,2154,0,431,1723,0,NULL,'bank_transfer','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-13 22:07:00','2026-10-13 22:13:00','2026-10-13 22:15:00','2026-10-13 22:38:00',NULL,'2026-10-13 22:06:00','2026-10-13 22:06:00');
INSERT INTO `trips` VALUES (50,'CB-QVJNJL',7,1,1,1,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'The Wheatbaker, Ikoyi',6.4473000,3.4337000,NULL,NULL,'2400',6.02,17,1.00,700,722,340,0,0,0,1762,0,352,1410,0,NULL,'cash','paid',NULL,NULL,NULL,3,NULL,NULL,NULL,NULL,'2026-10-19 09:30:00','2026-10-19 09:36:00','2026-10-19 09:38:00','2026-10-19 09:55:00',NULL,'2026-10-19 09:29:00','2026-10-19 09:29:00');
INSERT INTO `trips` VALUES (51,'CB-CUV4YI',1,5,5,1,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'The Palms Shopping Mall, Lekki',6.4359000,3.4510000,NULL,NULL,'3023',16.43,45,1.00,700,1972,900,0,0,0,3572,0,714,2858,0,NULL,'cash','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-09-29 11:23:00','2026-09-29 11:29:00','2026-09-29 11:31:00','2026-09-29 12:16:00',NULL,'2026-09-29 11:22:00','2026-09-29 11:22:00');
INSERT INTO `trips` VALUES (52,'CB-03O2Y3',9,3,3,1,'completed','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'Landmark Beach, Oniru',6.4210000,3.4430000,NULL,NULL,'3091',2.26,7,1.20,700,271,140,0,0,0,1500,500,300,1700,0,NULL,'wallet','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-10-05 07:50:00','2026-10-05 07:56:00','2026-10-05 07:58:00','2026-10-05 08:05:00',NULL,'2026-10-05 07:49:00','2026-10-05 07:49:00');
INSERT INTO `trips` VALUES (53,'CB-Z8NLWD',5,1,1,1,'completed','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,NULL,'2422',15.96,44,1.20,700,1915,880,0,0,0,4194,0,839,3355,0,NULL,'cash','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-19 10:09:00','2026-10-19 10:15:00','2026-10-19 10:17:00','2026-10-19 11:01:00',NULL,'2026-10-19 10:08:00','2026-10-19 10:08:00');
INSERT INTO `trips` VALUES (54,'CB-XLX1LG',16,4,4,1,'completed','Terra Kulture, Victoria Island',6.4335000,3.4229000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'2804',13.28,37,1.20,700,1594,740,0,0,0,3641,1000,728,3913,0,NULL,'card','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-09-20 17:57:00','2026-09-20 18:03:00','2026-09-20 18:05:00','2026-09-20 18:42:00',NULL,'2026-09-20 17:56:00','2026-09-20 17:56:00');
INSERT INTO `trips` VALUES (55,'CB-DEPQRC',14,2,2,2,'completed','The Palms Shopping Mall, Lekki',6.4359000,3.4510000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'7043',3.68,11,1.00,1000,626,308,0,250,0,2450,0,490,1960,0,NULL,'bank_transfer','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-09-27 22:13:00','2026-09-27 22:19:00','2026-09-27 22:21:00','2026-09-27 22:32:00',NULL,'2026-09-27 22:12:00','2026-09-27 22:12:00');
INSERT INTO `trips` VALUES (56,'CB-LTEO2R',1,2,2,4,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Tarzan Jetty, Victoria Island',6.4268000,3.4291000,NULL,NULL,'3440',14.56,40,1.00,2200,5242,2200,0,0,0,9642,0,1928,7714,0,NULL,'card','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-09-28 09:26:00','2026-09-28 09:32:00','2026-09-28 09:34:00','2026-09-28 10:14:00',NULL,'2026-09-28 09:25:00','2026-09-28 09:25:00');
INSERT INTO `trips` VALUES (57,'CB-S26CKY',7,1,1,2,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'1445',8.28,23,1.00,1000,1408,644,0,0,0,3052,0,610,2442,0,NULL,'card','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-10-03 07:28:00','2026-10-03 07:34:00','2026-10-03 07:36:00','2026-10-03 07:59:00',NULL,'2026-10-03 07:27:00','2026-10-03 07:27:00');
INSERT INTO `trips` VALUES (58,'CB-PGUUXU',4,7,7,1,'completed','Landmark Beach, Oniru',6.4210000,3.4430000,'Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,NULL,NULL,'6043',2.26,7,1.20,700,271,140,0,0,0,1500,0,300,1200,0,NULL,'cash','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-09 19:38:00','2026-10-09 19:44:00','2026-10-09 19:46:00','2026-10-09 19:53:00',NULL,'2026-10-09 19:37:00','2026-10-09 19:37:00');
INSERT INTO `trips` VALUES (59,'CB-LQGUC3',10,1,1,2,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'Tarzan Jetty, Victoria Island',6.4268000,3.4291000,NULL,NULL,'2330',14.64,40,1.00,1000,2489,1120,0,0,0,4609,0,922,3687,0,NULL,'card','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-09-29 09:54:00','2026-09-29 10:00:00','2026-09-29 10:02:00','2026-09-29 10:42:00',NULL,'2026-09-29 09:53:00','2026-09-29 09:53:00');
INSERT INTO `trips` VALUES (60,'CB-NXP27R',2,4,4,2,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Freedom Park, Lagos Island',6.4527000,3.3937000,NULL,NULL,'0661',8.28,23,1.00,1000,1408,644,0,0,0,3052,0,610,2442,0,NULL,'bank_transfer','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-16 19:57:00','2026-10-16 20:03:00','2026-10-16 20:05:00','2026-10-16 20:28:00',NULL,'2026-10-16 19:56:00','2026-10-16 19:56:00');
INSERT INTO `trips` VALUES (61,'CB-XL0BPP',1,1,1,1,'completed','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'Freedom Park, Lagos Island',6.4527000,3.3937000,NULL,NULL,'7685',6.55,18,1.20,700,786,360,0,0,0,2215,0,443,1772,0,NULL,'bank_transfer','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-09-28 21:06:00','2026-09-28 21:12:00','2026-09-28 21:14:00','2026-09-28 21:32:00',NULL,'2026-09-28 21:05:00','2026-09-28 21:05:00');
INSERT INTO `trips` VALUES (62,'CB-XIC5SM',7,3,3,1,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,NULL,NULL,'0728',5.42,15,1.00,700,650,300,0,0,0,1650,0,330,1320,0,NULL,'cash','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-16 21:41:00','2026-10-16 21:47:00','2026-10-16 21:49:00','2026-10-16 22:04:00',NULL,'2026-10-16 21:40:00','2026-10-16 21:40:00');
INSERT INTO `trips` VALUES (63,'CB-M5PCZ9',14,8,8,2,'completed','Nike Art Gallery, Lekki Phase 1',6.4371000,3.4848000,'The Palms Shopping Mall, Lekki',6.4359000,3.4510000,NULL,NULL,'7162',5.05,14,1.00,1000,859,392,0,250,0,2501,0,500,2001,0,NULL,'bank_transfer','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-09-20 07:11:00','2026-09-20 07:17:00','2026-09-20 07:19:00','2026-09-20 07:33:00',NULL,'2026-09-20 07:10:00','2026-09-20 07:10:00');
INSERT INTO `trips` VALUES (64,'CB-FZN8DS',1,8,8,2,'completed','The Wheatbaker, Ikoyi',6.4473000,3.4337000,'Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,NULL,NULL,'4315',0.90,3,1.00,1000,153,84,0,0,0,2200,0,440,1760,0,NULL,'card','paid',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-05 10:16:00','2026-10-05 10:22:00','2026-10-05 10:24:00','2026-10-05 10:27:00',NULL,'2026-10-05 10:15:00','2026-10-05 10:15:00');
INSERT INTO `trips` VALUES (65,'CB-9TRMWM',2,1,1,2,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,NULL,'6903',3.08,9,1.00,1000,524,252,0,0,0,2200,500,440,2260,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-18 16:23:00','2026-10-18 16:29:00','2026-10-18 16:31:00','2026-10-18 16:40:00',NULL,'2026-10-18 16:22:00','2026-10-18 16:22:00');
INSERT INTO `trips` VALUES (66,'CB-1TENQT',1,6,6,4,'completed','Lekki Conservation Centre, Lekki',6.4413000,3.5357000,'Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,NULL,NULL,'7862',15.85,44,1.00,2200,5706,2420,0,250,0,10576,200,2115,8661,0,NULL,'cash','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-09-21 15:09:00','2026-09-21 15:15:00','2026-09-21 15:17:00','2026-09-21 16:01:00',NULL,'2026-09-21 15:08:00','2026-09-21 15:08:00');
INSERT INTO `trips` VALUES (67,'CB-F36ROL',5,6,6,3,'completed','Nike Art Gallery, Lekki Phase 1',6.4371000,3.4848000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'2195',20.83,57,1.00,1500,4999,2166,0,250,0,8915,0,1783,7132,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-09-25 22:12:00','2026-09-25 22:18:00','2026-09-25 22:20:00','2026-09-25 23:17:00',NULL,'2026-09-25 22:11:00','2026-09-25 22:11:00');
INSERT INTO `trips` VALUES (68,'CB-NEOFD2',11,1,1,2,'completed','The Palms Shopping Mall, Lekki',6.4359000,3.4510000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,NULL,'6166',16.85,46,1.00,1000,2865,1288,0,0,0,5153,500,1031,4622,0,NULL,'cash','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-10-16 20:08:00','2026-10-16 20:14:00','2026-10-16 20:16:00','2026-10-16 21:02:00',NULL,'2026-10-16 20:07:00','2026-10-16 20:07:00');
INSERT INTO `trips` VALUES (69,'CB-DJ3LKY',2,1,1,1,'completed','The Wheatbaker, Ikoyi',6.4473000,3.4337000,'Lekki Conservation Centre, Lekki',6.4413000,3.5357000,NULL,NULL,'9854',15.24,42,1.00,700,1829,840,0,250,0,3619,0,724,2895,0,NULL,'cash','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-09-28 16:27:00','2026-09-28 16:33:00','2026-09-28 16:35:00','2026-09-28 17:17:00',NULL,'2026-09-28 16:26:00','2026-09-28 16:26:00');
INSERT INTO `trips` VALUES (70,'CB-EOD4UW',14,7,7,1,'completed','Terra Kulture, Victoria Island',6.4335000,3.4229000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'7930',7.73,22,1.20,700,928,440,0,250,0,2732,1000,546,3186,0,NULL,'cash','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-10-16 20:48:00','2026-10-16 20:54:00','2026-10-16 20:56:00','2026-10-16 21:18:00',NULL,'2026-10-16 20:47:00','2026-10-16 20:47:00');
INSERT INTO `trips` VALUES (71,'CB-V3JZDE',1,5,5,2,'completed','Terra Kulture, Victoria Island',6.4335000,3.4229000,'The Palms Shopping Mall, Lekki',6.4359000,3.4510000,NULL,NULL,'4702',4.21,12,1.20,1000,716,336,0,0,0,2462,0,492,1970,0,NULL,'card','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-16 15:54:00','2026-10-16 16:00:00','2026-10-16 16:02:00','2026-10-16 16:14:00',NULL,'2026-10-16 15:53:00','2026-10-16 15:53:00');
INSERT INTO `trips` VALUES (72,'CB-G6UKYA',15,5,5,1,'completed','Tarzan Jetty, Victoria Island',6.4268000,3.4291000,'The Wheatbaker, Ikoyi',6.4473000,3.4337000,NULL,NULL,'1089',3.15,9,1.20,700,378,180,0,0,0,1510,0,302,1208,0,NULL,'card','paid',NULL,NULL,NULL,3,NULL,NULL,NULL,NULL,'2026-10-07 17:11:00','2026-10-07 17:17:00','2026-10-07 17:19:00','2026-10-07 17:28:00',NULL,'2026-10-07 17:10:00','2026-10-07 17:10:00');
INSERT INTO `trips` VALUES (73,'CB-MGCYIP',9,1,1,1,'completed','Yaba Tech, Yaba',6.5180000,3.3740000,'Terra Kulture, Victoria Island',6.4335000,3.4229000,NULL,NULL,'6355',14.63,40,1.00,700,1756,800,0,0,0,3256,0,651,2605,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-09-27 18:27:00','2026-09-27 18:33:00','2026-09-27 18:35:00','2026-09-27 19:15:00',NULL,'2026-09-27 18:26:00','2026-09-27 18:26:00');
INSERT INTO `trips` VALUES (74,'CB-YARHXI',6,5,5,1,'completed','Landmark Beach, Oniru',6.4210000,3.4430000,'The Palms Shopping Mall, Lekki',6.4359000,3.4510000,NULL,NULL,'0002',2.54,7,1.20,700,305,140,0,0,0,1500,0,300,1200,0,NULL,'card','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-09-30 14:58:00','2026-09-30 15:04:00','2026-09-30 15:06:00','2026-09-30 15:13:00',NULL,'2026-09-30 14:57:00','2026-09-30 14:57:00');
INSERT INTO `trips` VALUES (75,'CB-QTRZGD',5,4,4,1,'completed','Tarzan Jetty, Victoria Island',6.4268000,3.4291000,'Terra Kulture, Victoria Island',6.4335000,3.4229000,NULL,NULL,'4087',1.37,4,1.20,700,164,80,0,0,0,1500,200,300,1400,0,NULL,'wallet','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-09-20 22:06:00','2026-09-20 22:12:00','2026-09-20 22:14:00','2026-09-20 22:18:00',NULL,'2026-09-20 22:05:00','2026-09-20 22:05:00');
INSERT INTO `trips` VALUES (76,'CB-MNOJ8I',1,3,3,3,'completed','Lekki Conservation Centre, Lekki',6.4413000,3.5357000,'Freedom Park, Lagos Island',6.4527000,3.3937000,NULL,NULL,'6161',21.25,58,1.00,1500,5100,2204,0,250,0,9054,1000,1811,8243,0,NULL,'card','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-02 22:56:00','2026-10-02 23:02:00','2026-10-02 23:04:00','2026-10-03 00:02:00',NULL,'2026-10-02 22:55:00','2026-10-02 22:55:00');
INSERT INTO `trips` VALUES (77,'CB-AZXIEW',7,1,1,1,'completed','Landmark Beach, Oniru',6.4210000,3.4430000,'Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,NULL,NULL,'5253',5.04,14,1.20,700,605,280,0,0,0,1902,0,380,1522,0,NULL,'bank_transfer','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-08 19:06:00','2026-10-08 19:12:00','2026-10-08 19:14:00','2026-10-08 19:28:00',NULL,'2026-10-08 19:05:00','2026-10-08 19:05:00');
INSERT INTO `trips` VALUES (78,'CB-VGDCK5',8,6,6,4,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'3452',18.58,51,1.00,2200,6689,2805,0,250,0,11944,0,2389,9555,0,NULL,'card','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-09 22:38:00','2026-10-09 22:44:00','2026-10-09 22:46:00','2026-10-09 23:37:00',NULL,'2026-10-09 22:37:00','2026-10-09 22:37:00');
INSERT INTO `trips` VALUES (79,'CB-LTUYGC',11,3,3,1,'completed','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'The Palms Shopping Mall, Lekki',6.4359000,3.4510000,NULL,NULL,'2351',3.55,10,1.20,700,426,200,0,0,0,1591,0,318,1273,0,NULL,'bank_transfer','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-14 22:01:00','2026-10-14 22:07:00','2026-10-14 22:09:00','2026-10-14 22:19:00',NULL,'2026-10-14 22:00:00','2026-10-14 22:00:00');
INSERT INTO `trips` VALUES (80,'CB-UC2FM1',8,4,4,2,'completed','Tarzan Jetty, Victoria Island',6.4268000,3.4291000,'Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,NULL,NULL,'7779',3.79,11,1.20,1000,644,308,0,0,0,2342,200,468,2074,0,NULL,'card','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-16 13:10:00','2026-10-16 13:16:00','2026-10-16 13:18:00','2026-10-16 13:29:00',NULL,'2026-10-16 13:09:00','2026-10-16 13:09:00');
INSERT INTO `trips` VALUES (81,'CB-Y3VHQY',1,1,1,1,'completed','Yaba Tech, Yaba',6.5180000,3.3740000,'Lekki Conservation Centre, Lekki',6.4413000,3.5357000,NULL,NULL,'8200',26.73,73,1.00,700,3208,1460,0,250,0,5618,500,1124,4994,0,NULL,'wallet','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-09-23 11:05:00','2026-09-23 11:11:00','2026-09-23 11:13:00','2026-09-23 12:26:00',NULL,'2026-09-23 11:04:00','2026-09-23 11:04:00');
INSERT INTO `trips` VALUES (82,'CB-U16D4M',2,8,8,1,'completed','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'Landmark Beach, Oniru',6.4210000,3.4430000,NULL,NULL,'0973',5.96,17,1.00,700,715,340,0,250,0,2005,0,401,1604,0,NULL,'card','paid',NULL,NULL,4,5,NULL,NULL,NULL,NULL,'2026-09-22 12:34:00','2026-09-22 12:40:00','2026-09-22 12:42:00','2026-09-22 12:59:00',NULL,'2026-09-22 12:33:00','2026-09-22 12:33:00');
INSERT INTO `trips` VALUES (83,'CB-PSBSSC',15,7,7,1,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'7640',17.93,49,1.00,700,2152,980,0,250,0,4082,0,816,3266,0,NULL,'wallet','paid',NULL,NULL,4,4,NULL,NULL,NULL,NULL,'2026-09-24 10:47:00','2026-09-24 10:53:00','2026-09-24 10:55:00','2026-09-24 11:44:00',NULL,'2026-09-24 10:46:00','2026-09-24 10:46:00');
INSERT INTO `trips` VALUES (84,'CB-RJ66OW',4,8,8,2,'completed','Landmark Beach, Oniru',6.4210000,3.4430000,'Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,NULL,NULL,'4661',16.77,46,1.20,1000,2851,1288,0,0,0,6167,0,1233,4934,0,NULL,'card','paid',NULL,NULL,5,3,NULL,NULL,NULL,NULL,'2026-10-04 20:47:00','2026-10-04 20:53:00','2026-10-04 20:55:00','2026-10-04 21:41:00',NULL,'2026-10-04 20:46:00','2026-10-04 20:46:00');
INSERT INTO `trips` VALUES (85,'CB-D8RRB2',3,1,1,1,'completed','Tarzan Jetty, Victoria Island',6.4268000,3.4291000,'Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,NULL,NULL,'6430',7.21,20,1.20,700,865,400,0,250,0,2608,0,522,2086,0,NULL,'card','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-10-08 10:10:00','2026-10-08 10:16:00','2026-10-08 10:18:00','2026-10-08 10:38:00',NULL,'2026-10-08 10:09:00','2026-10-08 10:09:00');
INSERT INTO `trips` VALUES (86,'CB-YPKU5G',1,1,1,1,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'Lekki Conservation Centre, Lekki',6.4413000,3.5357000,NULL,NULL,'0594',21.25,58,1.00,700,2550,1160,0,250,0,4660,0,932,3728,0,NULL,'card','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-10-18 18:16:00','2026-10-18 18:22:00','2026-10-18 18:24:00','2026-10-18 19:22:00',NULL,'2026-10-18 18:15:00','2026-10-18 18:15:00');
INSERT INTO `trips` VALUES (87,'CB-TUVTO9',16,8,8,1,'completed','National Stadium, Surulere',6.4997000,3.3647000,'Tarzan Jetty, Victoria Island',6.4268000,3.4291000,NULL,NULL,'2333',14.56,40,1.00,700,1747,800,0,0,0,3247,0,649,2598,0,NULL,'cash','paid',NULL,NULL,NULL,4,NULL,NULL,NULL,NULL,'2026-09-29 06:14:00','2026-09-29 06:20:00','2026-09-29 06:22:00','2026-09-29 07:02:00',NULL,'2026-09-29 06:13:00','2026-09-29 06:13:00');
INSERT INTO `trips` VALUES (88,'CB-ZUPFBF',9,8,8,1,'completed','Ikoyi Club 1938, Ikoyi',6.4520000,3.4300000,'Lekki Conservation Centre, Lekki',6.4413000,3.5357000,NULL,NULL,'0118',15.85,44,1.00,700,1902,880,0,250,0,3732,0,746,2986,0,NULL,'bank_transfer','paid',NULL,NULL,5,NULL,NULL,NULL,NULL,NULL,'2026-09-30 07:08:00','2026-09-30 07:14:00','2026-09-30 07:16:00','2026-09-30 08:00:00',NULL,'2026-09-30 07:07:00','2026-09-30 07:07:00');
INSERT INTO `trips` VALUES (89,'CB-VBCZCQ',15,1,1,2,'completed','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,NULL,'2671',4.53,13,1.00,1000,770,364,0,0,0,2200,0,440,1760,0,NULL,'bank_transfer','paid',NULL,NULL,NULL,5,NULL,NULL,NULL,NULL,'2026-10-15 11:00:00','2026-10-15 11:06:00','2026-10-15 11:08:00','2026-10-15 11:21:00',NULL,'2026-10-15 10:59:00','2026-10-15 10:59:00');
INSERT INTO `trips` VALUES (90,'CB-GFGJBG',15,8,8,1,'completed','Freedom Park, Lagos Island',6.4527000,3.3937000,'The Wheatbaker, Ikoyi',6.4473000,3.4337000,NULL,NULL,'3093',6.02,17,1.00,700,722,340,0,0,0,1762,500,352,1910,0,NULL,'bank_transfer','paid',NULL,NULL,5,5,NULL,NULL,NULL,NULL,'2026-09-21 18:13:00','2026-09-21 18:19:00','2026-09-21 18:21:00','2026-09-21 18:38:00',NULL,'2026-09-21 18:12:00','2026-09-21 18:12:00');
INSERT INTO `trips` VALUES (91,'CB-HKT1EN',1,1,1,2,'accepted','Eko Hotel & Suites, Victoria Island',6.4268000,3.4290000,'Nike Art Gallery, Lekki Phase 1',6.4371000,3.4848000,NULL,NULL,'4821',8.47,24,1.20,1000,1440,672,0,250,0,3984,0,797,3187,0,NULL,'card','authorised',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'xobYtrlBCZpQPIuWmJgb3PkL','2026-10-19 16:13:22',NULL,NULL,NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `trips` VALUES (92,'CB-DZFNEH',2,NULL,NULL,1,'requested','Admiralty Way, Lekki Phase 1',6.4474000,3.4728000,'National Stadium, Surulere',6.4997000,3.3647000,NULL,NULL,'4295',17.93,49,1.00,700,2152,980,0,250,0,4082,0,0,0,0,NULL,'card','pending',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
INSERT INTO `trips` VALUES (93,'CB-N5T7SY',3,NULL,NULL,1,'scheduled','Shoprite Surulere, Adeniran Ogunsanya',6.4930000,3.3570000,'Yaba Tech, Yaba',6.5180000,3.3740000,NULL,'2026-10-20 07:30:00','2090',4.53,13,1.00,700,544,260,0,0,0,1504,0,0,0,0,NULL,'card','pending',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2026-10-19 16:15:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `trips` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `vehicles` WRITE;
/*!40000 ALTER TABLE `vehicles` DISABLE KEYS */;
INSERT INTO `vehicles` VALUES (1,1,'Toyota','Corolla',2019,'Silver','LND 482 KJ',4,'[\"economy\",\"comfort\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (2,2,'Mercedes-Benz','E-Class',2021,'Black','LSR 118 AA',4,'[\"premium\",\"comfort\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (3,3,'Toyota','Highlander',2018,'Grey','KJA 903 XC',6,'[\"suv\",\"comfort\",\"economy\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (4,4,'Honda','Accord',2017,'Blue','EKY 552 BD',4,'[\"economy\",\"comfort\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (5,5,'Toyota','Camry',2020,'White','APP 731 GH',4,'[\"economy\",\"comfort\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (6,6,'Lexus','RX 350',2022,'Black','LND 207 PR',4,'[\"premium\",\"suv\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (7,7,'Kia','Rio',2019,'Red','FST 664 KL',4,'[\"economy\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (8,8,'Hyundai','Elantra',2020,'Silver','IKD 318 MN',4,'[\"economy\",\"comfort\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (9,9,'Toyota','Corolla',2016,'Gold','AGL 425 TU',4,'[\"economy\"]',0,'pending',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (10,10,'Toyota','Sienna',2015,'Blue','LSD 836 QW',7,'[\"suv\",\"economy\"]',1,'pending',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
INSERT INTO `vehicles` VALUES (11,12,'Nissan','Almera',2014,'White','MUS 109 ZX',4,'[\"economy\"]',0,'approved',1,'2026-10-19 16:15:21','2026-10-19 16:15:21');
/*!40000 ALTER TABLE `vehicles` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `waitlist_signups` WRITE;
/*!40000 ALTER TABLE `waitlist_signups` DISABLE KEYS */;
INSERT INTO `waitlist_signups` VALUES (1,'Chloe Adams','chloe.adams@example.co.uk','website',NULL,'2026-10-14 16:15:22','2026-09-29 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (2,'Jide Martins','jide.martins@example.com','website',NULL,'2026-10-14 16:15:22','2026-09-30 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (3,'Hannah Schmidt','hannah.schmidt@example.de','website',NULL,'2026-10-14 16:15:22','2026-10-01 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (4,'Uche Nnamdi','uche.nnamdi@example.com','website',NULL,NULL,'2026-10-02 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (5,'Priya Patel','priya.patel@example.co.uk','website',NULL,NULL,'2026-10-03 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (6,'Tomiwa Ade','tomiwa.ade@example.com','website',NULL,NULL,'2026-10-04 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (7,'Lucas Silva','lucas.silva@example.com.br','website',NULL,NULL,'2026-10-05 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (8,'Zainab Yusuf','zainab.yusuf@example.com','website',NULL,NULL,'2026-10-06 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (9,'James O\'Neill','james.oneill@example.ie','website',NULL,NULL,'2026-10-07 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (10,'Efua Asante','efua.asante@example.com.gh','website',NULL,NULL,'2026-10-08 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (11,'Kemi Coker','kemi.coker@example.com','website',NULL,NULL,'2026-10-09 16:15:22','2026-10-19 16:15:22');
INSERT INTO `waitlist_signups` VALUES (12,'Driver Lead','drive.with.cabo@example.com','driver',NULL,NULL,'2026-10-10 16:15:22','2026-10-19 16:15:22');
/*!40000 ALTER TABLE `waitlist_signups` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `wishlist_items` WRITE;
/*!40000 ALTER TABLE `wishlist_items` DISABLE KEYS */;
/*!40000 ALTER TABLE `wishlist_items` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `zones` WRITE;
/*!40000 ALTER TABLE `zones` DISABLE KEYS */;
INSERT INTO `zones` VALUES (1,'Victoria Island',6.4281000,3.4219000,3.00,1.20,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `zones` VALUES (2,'Ikoyi',6.4549000,3.4346000,3.00,1.00,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `zones` VALUES (3,'Lekki',6.4474000,3.4728000,6.00,1.00,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `zones` VALUES (4,'Yaba',6.5095000,3.3711000,3.00,1.00,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `zones` VALUES (5,'Surulere',6.4969000,3.3481000,3.50,1.00,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
INSERT INTO `zones` VALUES (6,'Murtala Muhammed Airport',6.5774000,3.3212000,2.50,1.00,1,1,'2026-10-19 16:15:20','2026-10-19 16:15:20');
/*!40000 ALTER TABLE `zones` ENABLE KEYS */;
UNLOCK TABLES;



SET FOREIGN_KEY_CHECKS = 1;
SET UNIQUE_CHECKS = 1;
