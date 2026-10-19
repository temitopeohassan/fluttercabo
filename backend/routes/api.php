<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\Driver;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\PublicController;
use App\Http\Controllers\Api\Rider;
use App\Http\Controllers\Api\SosController;
use App\Http\Controllers\Api\SupportController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public: no token needed.
    Route::get('config', [PublicController::class, 'config']);
    Route::get('ride-types', [PublicController::class, 'rideTypes']);
    Route::get('tour-categories', [PublicController::class, 'tourCategories']);
    Route::get('tours', [PublicController::class, 'tours']);
    Route::get('tours/{tour:slug}', [PublicController::class, 'tour']);
    Route::get('tours/{tour:slug}/slots', [PublicController::class, 'tourSlots']);
    Route::get('attractions', [PublicController::class, 'attractions']);
    Route::get('attractions/{attraction:slug}', [PublicController::class, 'attraction']);
    Route::post('waitlist', [PublicController::class, 'waitlist'])->middleware('throttle:10,1');

    // Shared endpoints for any signed-in rider or driver.
    $shared = function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
        Route::post('sos', [SosController::class, 'store']);
        Route::patch('sos/{alert}', [SosController::class, 'update']);
        Route::get('support/tickets', [SupportController::class, 'index']);
        Route::post('support/tickets', [SupportController::class, 'store']);
        Route::get('support/tickets/{ticket}', [SupportController::class, 'show']);
        Route::post('support/tickets/{ticket}/messages', [SupportController::class, 'reply']);
        Route::get('notifications', [NotificationController::class, 'index']);
        Route::post('notifications/read-all', [NotificationController::class, 'readAll']);
        Route::post('notifications/{notification}/read', [NotificationController::class, 'read']);
    };

    foreach (['rider', 'driver'] as $app) {
        Route::prefix("$app/auth")->middleware('throttle:6,1')->group(function () use ($app) {
            Route::post('otp', [AuthController::class, 'requestOtp'])->defaults('app', $app);
            Route::post('verify', [AuthController::class, 'verify'])->defaults('app', $app);
        });
    }

    // Rider app.
    Route::prefix('rider')->middleware(['auth:sanctum', 'abilities:rider'])->group(function () use ($shared) {
        $shared();

        Route::get('me', [Rider\ProfileController::class, 'show']);
        Route::patch('me', [Rider\ProfileController::class, 'update']);
        Route::delete('me', [Rider\ProfileController::class, 'destroy']);
        Route::get('emergency-contacts', [Rider\ProfileController::class, 'contacts']);
        Route::post('emergency-contacts', [Rider\ProfileController::class, 'storeContact']);
        Route::put('emergency-contacts/{contact}', [Rider\ProfileController::class, 'updateContact']);
        Route::delete('emergency-contacts/{contact}', [Rider\ProfileController::class, 'destroyContact']);
        Route::get('saved-places', [Rider\ProfileController::class, 'places']);
        Route::post('saved-places', [Rider\ProfileController::class, 'storePlace']);
        Route::put('saved-places/{place}', [Rider\ProfileController::class, 'updatePlace']);
        Route::delete('saved-places/{place}', [Rider\ProfileController::class, 'destroyPlace']);

        Route::post('fare-estimates', [Rider\TripController::class, 'estimate']);
        Route::get('trips', [Rider\TripController::class, 'index']);
        Route::post('trips', [Rider\TripController::class, 'store']);
        Route::get('trips/{trip}', [Rider\TripController::class, 'show']);
        Route::post('trips/{trip}/cancel', [Rider\TripController::class, 'cancel']);
        Route::post('trips/{trip}/stops', [Rider\TripController::class, 'addStop']);
        Route::post('trips/{trip}/rating', [Rider\TripController::class, 'rate']);
        Route::post('trips/{trip}/share', [Rider\TripController::class, 'share']);

        Route::post('shuttles/quote', [Rider\ShuttleController::class, 'quote']);
        Route::get('shuttles', [Rider\ShuttleController::class, 'index']);
        Route::post('shuttles', [Rider\ShuttleController::class, 'store']);
        Route::get('shuttles/{shuttle}', [Rider\ShuttleController::class, 'show']);
        Route::post('shuttles/{shuttle}/cancel', [Rider\ShuttleController::class, 'cancel']);

        Route::get('tour-bookings', [Rider\TourBookingController::class, 'index']);
        Route::post('tour-bookings', [Rider\TourBookingController::class, 'store']);
        Route::get('tour-bookings/{booking}', [Rider\TourBookingController::class, 'show']);
        Route::post('tour-bookings/{booking}/cancel', [Rider\TourBookingController::class, 'cancel']);
        Route::post('tour-bookings/{booking}/review', [Rider\TourBookingController::class, 'review']);

        Route::get('wishlist', [Rider\WishlistController::class, 'index']);
        Route::post('wishlist', [Rider\WishlistController::class, 'store']);
        Route::delete('wishlist/{item}', [Rider\WishlistController::class, 'destroy']);

        Route::get('wallet', [Rider\WalletController::class, 'show']);
        Route::post('wallet/top-up', [Rider\WalletController::class, 'topUp']);
        Route::get('wallet/transactions', [Rider\WalletController::class, 'transactions']);
        Route::post('promo-codes/validate', [Rider\WalletController::class, 'validatePromo']);
    });

    // Driver app.
    Route::prefix('driver')->middleware(['auth:sanctum', 'abilities:driver'])->group(function () use ($shared) {
        $shared();

        Route::get('me', [Driver\ProfileController::class, 'show']);
        Route::patch('me', [Driver\ProfileController::class, 'update']);
        Route::post('application/submit', [Driver\ProfileController::class, 'submit']);
        Route::get('documents', [Driver\ProfileController::class, 'documents']);
        Route::post('documents', [Driver\ProfileController::class, 'uploadDocument']);
        Route::get('vehicles', [Driver\ProfileController::class, 'vehicles']);
        Route::post('vehicles', [Driver\ProfileController::class, 'storeVehicle']);
        Route::post('vehicles/{vehicle}/activate', [Driver\ProfileController::class, 'activateVehicle']);
        Route::post('status', [Driver\ProfileController::class, 'status']);
        Route::post('location', [Driver\ProfileController::class, 'location']);

        Route::get('trips/available', [Driver\TripController::class, 'available']);
        Route::get('trips/current', [Driver\TripController::class, 'current']);
        Route::get('trips', [Driver\TripController::class, 'index']);
        Route::get('trips/{trip}', [Driver\TripController::class, 'show']);
        Route::post('trips/{trip}/accept', [Driver\TripController::class, 'accept']);
        Route::post('trips/{trip}/decline', [Driver\TripController::class, 'decline']);
        Route::post('trips/{trip}/arrive', [Driver\TripController::class, 'arrive']);
        Route::post('trips/{trip}/start', [Driver\TripController::class, 'start']);
        Route::post('trips/{trip}/complete', [Driver\TripController::class, 'complete']);
        Route::post('trips/{trip}/collect-cash', [Driver\TripController::class, 'collectCash']);
        Route::post('trips/{trip}/cancel', [Driver\TripController::class, 'cancel']);
        Route::post('trips/{trip}/rating', [Driver\TripController::class, 'rate']);

        Route::get('jobs/shuttles', [Driver\JobController::class, 'shuttles']);
        Route::post('jobs/shuttles/{shuttle}/claim', [Driver\JobController::class, 'claimShuttle']);
        Route::patch('jobs/shuttles/{shuttle}', [Driver\JobController::class, 'updateShuttle']);
        Route::get('jobs/tours', [Driver\JobController::class, 'tours']);
        Route::post('jobs/tours/check-in', [Driver\JobController::class, 'checkIn']);
        Route::post('jobs/tours/{slot}/complete', [Driver\JobController::class, 'completeTour']);

        Route::get('earnings', [Driver\EarningsController::class, 'summary']);
        Route::get('earnings/transactions', [Driver\EarningsController::class, 'transactions']);
        Route::get('payouts', [Driver\EarningsController::class, 'payouts']);
        Route::post('payouts/instant', [Driver\EarningsController::class, 'cashOut']);
    });
});
