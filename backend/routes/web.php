<?php

use App\Http\Controllers\Admin;
use App\Models\Trip;
use Illuminate\Support\Facades\Route;

Route::redirect('/', '/admin');

// Live trip page opened from a rider's "Share trip" link.
Route::get('trip/{token}', function (string $token) {
    $trip = Trip::where('share_token', $token)->with('driver:id,first_name,rating,current_lat,current_lng', 'vehicle:id,make,model,colour,plate_number')->firstOrFail();

    return view('share-trip', compact('trip'));
})->name('trip.share');

Route::prefix('admin')->name('admin.')->group(function () {
    Route::middleware('guest:web')->group(function () {
        Route::get('login', [Admin\AuthController::class, 'show'])->name('login');
        Route::post('login', [Admin\AuthController::class, 'login'])->middleware('throttle:20,1');
    });

    Route::middleware('auth:web')->group(function () {
        Route::post('logout', [Admin\AuthController::class, 'logout'])->name('logout');
        Route::get('/', Admin\DashboardController::class)->name('dashboard');
        Route::get('account', [Admin\AccountController::class, 'edit'])->name('account');
        Route::put('account', [Admin\AccountController::class, 'update']);

        // Read-only pages for every admin role.
        Route::get('riders', [Admin\RiderController::class, 'index'])->name('riders.index');
        Route::get('riders/{rider}', [Admin\RiderController::class, 'show'])->name('riders.show');
        Route::get('drivers', [Admin\DriverController::class, 'index'])->name('drivers.index');
        Route::get('drivers/{driver}', [Admin\DriverController::class, 'show'])->name('drivers.show');
        Route::get('documents', [Admin\DriverController::class, 'documents'])->name('documents.index');
        Route::get('documents/{document}/file', [Admin\DriverController::class, 'downloadDocument'])->name('documents.file');
        Route::get('trips', [Admin\TripController::class, 'index'])->name('trips.index');
        Route::get('trips/{trip}', [Admin\TripController::class, 'show'])->name('trips.show');
        Route::get('shuttles', [Admin\ShuttleController::class, 'index'])->name('shuttles.index');
        Route::get('shuttles/{shuttle}', [Admin\ShuttleController::class, 'show'])->name('shuttles.show');
        Route::get('tours', [Admin\TourController::class, 'index'])->name('tours.index');
        Route::get('tour-bookings', [Admin\TourBookingController::class, 'index'])->name('tour-bookings.index');
        Route::get('tour-bookings/{booking}', [Admin\TourBookingController::class, 'show'])->name('tour-bookings.show');
        Route::get('partners', [Admin\PartnerController::class, 'index'])->name('partners.index');
        Route::get('attractions', [Admin\AttractionController::class, 'index'])->name('attractions.index');
        Route::get('pricing', [Admin\PricingController::class, 'index'])->name('pricing.index');
        Route::get('promo-codes', [Admin\PromoCodeController::class, 'index'])->name('promo-codes.index');
        Route::get('payouts', [Admin\PayoutController::class, 'index'])->name('payouts.index');
        Route::get('transactions', [Admin\PayoutController::class, 'transactions'])->name('transactions.index');
        Route::get('support', [Admin\SupportController::class, 'index'])->name('support.index');
        Route::get('support/{ticket}', [Admin\SupportController::class, 'show'])->name('support.show');
        Route::get('sos', [Admin\SosController::class, 'index'])->name('sos.index');
        Route::get('waitlist', [Admin\WaitlistController::class, 'index'])->name('waitlist.index');
        Route::get('waitlist/export', [Admin\WaitlistController::class, 'export'])->name('waitlist.export');

        Route::middleware('admin.role:operations')->group(function () {
            Route::post('drivers/{driver}/status', [Admin\DriverController::class, 'status'])->name('drivers.status');
            Route::post('documents/{document}/review', [Admin\DriverController::class, 'reviewDocument'])->name('documents.review');
            Route::post('vehicles/{vehicle}/review', [Admin\DriverController::class, 'reviewVehicle'])->name('vehicles.review');
            Route::post('trips/{trip}/cancel', [Admin\TripController::class, 'cancel'])->name('trips.cancel');
            Route::put('shuttles/{shuttle}', [Admin\ShuttleController::class, 'update'])->name('shuttles.update');
            Route::post('shuttles/{shuttle}/cancel', [Admin\ShuttleController::class, 'cancel'])->name('shuttles.cancel');
            Route::get('tours/create', [Admin\TourController::class, 'create'])->name('tours.create');
            Route::post('tours', [Admin\TourController::class, 'store'])->name('tours.store');
            Route::get('tours/{tour}/edit', [Admin\TourController::class, 'edit'])->name('tours.edit');
            Route::put('tours/{tour}', [Admin\TourController::class, 'update'])->name('tours.update');
            Route::delete('tours/{tour}', [Admin\TourController::class, 'destroy'])->name('tours.destroy');
            Route::post('tours/{tour}/slots', [Admin\TourController::class, 'storeSlots'])->name('tours.slots.store');
            Route::put('slots/{slot}', [Admin\TourController::class, 'updateSlot'])->name('slots.update');
            Route::delete('slots/{slot}', [Admin\TourController::class, 'destroySlot'])->name('slots.destroy');
            Route::post('tour-bookings/{booking}/check-in', [Admin\TourBookingController::class, 'checkIn'])->name('tour-bookings.check-in');
            Route::get('partners/create', [Admin\PartnerController::class, 'create'])->name('partners.create');
            Route::post('partners', [Admin\PartnerController::class, 'store'])->name('partners.store');
            Route::get('partners/{partner}/edit', [Admin\PartnerController::class, 'edit'])->name('partners.edit');
            Route::put('partners/{partner}', [Admin\PartnerController::class, 'update'])->name('partners.update');
            Route::get('attractions/create', [Admin\AttractionController::class, 'create'])->name('attractions.create');
            Route::post('attractions', [Admin\AttractionController::class, 'store'])->name('attractions.store');
            Route::get('attractions/{attraction}/edit', [Admin\AttractionController::class, 'edit'])->name('attractions.edit');
            Route::put('attractions/{attraction}', [Admin\AttractionController::class, 'update'])->name('attractions.update');
            Route::delete('attractions/{attraction}', [Admin\AttractionController::class, 'destroy'])->name('attractions.destroy');
            Route::post('zones', [Admin\PricingController::class, 'storeZone'])->name('zones.store');
            Route::put('zones/{zone}', [Admin\PricingController::class, 'updateZone'])->name('zones.update');
            Route::delete('zones/{zone}', [Admin\PricingController::class, 'destroyZone'])->name('zones.destroy');
            Route::post('waitlist/{signup}/invite', [Admin\WaitlistController::class, 'invite'])->name('waitlist.invite');
            Route::delete('waitlist/{signup}', [Admin\WaitlistController::class, 'destroy'])->name('waitlist.destroy');
        });

        Route::middleware('admin.role:operations,support')->group(function () {
            Route::post('riders/{rider}/status', [Admin\RiderController::class, 'status'])->name('riders.status');
            Route::post('support/{ticket}/reply', [Admin\SupportController::class, 'reply'])->name('support.reply');
            Route::put('support/{ticket}', [Admin\SupportController::class, 'update'])->name('support.update');
            Route::put('sos/{alert}', [Admin\SosController::class, 'update'])->name('sos.update');
            Route::post('tour-bookings/{booking}/review-visibility', [Admin\TourBookingController::class, 'toggleReview'])->name('tour-bookings.review');
        });

        Route::middleware('admin.role:finance,support')->group(function () {
            Route::post('trips/{trip}/refund', [Admin\TripController::class, 'refund'])->name('trips.refund');
            Route::post('tour-bookings/{booking}/cancel', [Admin\TourBookingController::class, 'cancel'])->name('tour-bookings.cancel');
            Route::post('riders/{rider}/credit', [Admin\RiderController::class, 'credit'])->name('riders.credit');
        });

        Route::middleware('admin.role:finance')->group(function () {
            Route::put('ride-types/{rideType}', [Admin\PricingController::class, 'updateRideType'])->name('ride-types.update');
            Route::get('promo-codes/create', [Admin\PromoCodeController::class, 'create'])->name('promo-codes.create');
            Route::post('promo-codes', [Admin\PromoCodeController::class, 'store'])->name('promo-codes.store');
            Route::get('promo-codes/{promoCode}/edit', [Admin\PromoCodeController::class, 'edit'])->name('promo-codes.edit');
            Route::put('promo-codes/{promoCode}', [Admin\PromoCodeController::class, 'update'])->name('promo-codes.update');
            Route::put('payouts/{payout}', [Admin\PayoutController::class, 'update'])->name('payouts.update');
            Route::post('payouts/run-weekly', [Admin\PayoutController::class, 'runWeekly'])->name('payouts.run-weekly');
            Route::post('drivers/{driver}/settle-cash', [Admin\DriverController::class, 'settleCash'])->name('drivers.settle-cash');
        });

        Route::middleware('admin.role:super_admin')->group(function () {
            Route::get('settings', [Admin\SettingController::class, 'edit'])->name('settings');
            Route::put('settings', [Admin\SettingController::class, 'update']);
            Route::get('admins', [Admin\AdminUserController::class, 'index'])->name('admins.index');
            Route::get('admins/create', [Admin\AdminUserController::class, 'create'])->name('admins.create');
            Route::post('admins', [Admin\AdminUserController::class, 'store'])->name('admins.store');
            Route::get('admins/{admin}/edit', [Admin\AdminUserController::class, 'edit'])->name('admins.edit');
            Route::put('admins/{admin}', [Admin\AdminUserController::class, 'update'])->name('admins.update');
        });

        // Tour detail comes after tours/create so "create" is not read as a tour id.
        Route::get('tours/{tour}', [Admin\TourController::class, 'show'])->name('tours.show');
    });
});
