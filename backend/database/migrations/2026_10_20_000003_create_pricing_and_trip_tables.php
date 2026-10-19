<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ride_types', function (Blueprint $table) {
            $table->id();
            $table->string('code', 32)->unique();
            $table->string('name');
            $table->string('description')->nullable();
            $table->unsignedTinyInteger('seats')->default(4);
            $table->unsignedInteger('base_fare')->comment('Naira');
            $table->unsignedInteger('per_km')->comment('Naira');
            $table->unsignedInteger('per_minute')->comment('Naira');
            $table->unsignedInteger('minimum_fare')->comment('Naira');
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        // Pricing zones with a surge multiplier set by operations.
        Schema::create('zones', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->decimal('center_lat', 10, 7);
            $table->decimal('center_lng', 10, 7);
            $table->decimal('radius_km', 5, 2);
            $table->decimal('surge_multiplier', 3, 2)->default(1);
            $table->boolean('is_service_area')->default(true);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value');
            $table->string('label');
            $table->string('group')->default('general');
            $table->timestamps();
        });

        Schema::create('trips', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 20)->unique();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('vehicle_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('ride_type_id')->constrained();
            $table->enum('status', ['scheduled', 'requested', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled', 'no_show'])->default('requested');
            $table->string('pickup_address');
            $table->decimal('pickup_lat', 10, 7);
            $table->decimal('pickup_lng', 10, 7);
            $table->string('dropoff_address');
            $table->decimal('dropoff_lat', 10, 7);
            $table->decimal('dropoff_lng', 10, 7);
            $table->json('stops')->nullable();
            $table->timestamp('scheduled_at')->nullable();
            $table->char('pin', 4);
            $table->decimal('distance_km', 6, 2);
            $table->unsignedSmallInteger('duration_minutes');
            $table->decimal('surge_multiplier', 3, 2)->default(1);
            $table->unsignedInteger('fare_base')->default(0);
            $table->unsignedInteger('fare_distance')->default(0);
            $table->unsignedInteger('fare_time')->default(0);
            $table->unsignedInteger('fare_stops')->default(0);
            $table->unsignedInteger('tolls')->default(0);
            $table->unsignedInteger('discount')->default(0);
            $table->unsignedInteger('fare_total')->comment('Naira charged to the rider, before tip');
            $table->unsignedInteger('tip')->default(0);
            $table->unsignedInteger('commission')->default(0);
            $table->unsignedInteger('driver_earnings')->default(0);
            $table->unsignedInteger('cancellation_fee')->default(0);
            $table->foreignId('promo_code_id')->nullable();
            $table->enum('payment_method', ['card', 'wallet', 'bank_transfer', 'cash'])->default('card');
            $table->enum('payment_status', ['pending', 'authorised', 'paid', 'refunded', 'failed'])->default('pending');
            $table->enum('cancelled_by', ['rider', 'driver', 'admin'])->nullable();
            $table->string('cancellation_reason')->nullable();
            $table->unsignedTinyInteger('rider_rating')->nullable()->comment('Given by the driver');
            $table->unsignedTinyInteger('driver_rating')->nullable()->comment('Given by the rider');
            $table->string('rider_feedback')->nullable();
            $table->string('driver_feedback')->nullable();
            $table->json('declined_driver_ids')->nullable();
            $table->string('share_token', 32)->nullable()->unique();
            $table->timestamp('accepted_at')->nullable();
            $table->timestamp('arrived_at')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'created_at']);
        });

        Schema::create('shuttle_bookings', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 20)->unique();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->foreignId('driver_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('direction', ['airport_pickup', 'airport_dropoff']);
            $table->string('airport')->default('Murtala Muhammed International (LOS)');
            $table->string('terminal')->nullable();
            $table->string('flight_number', 12)->nullable();
            $table->timestamp('flight_time')->nullable()->comment('Scheduled arrival or departure');
            $table->enum('flight_status', ['scheduled', 'on_time', 'delayed', 'landed', 'cancelled'])->default('scheduled');
            $table->timestamp('pickup_at');
            $table->string('address')->comment('Hotel or home end of the trip');
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->foreignId('ride_type_id')->constrained();
            $table->unsignedTinyInteger('passengers')->default(1);
            $table->unsignedTinyInteger('large_bags')->default(0);
            $table->unsignedTinyInteger('small_bags')->default(0);
            $table->unsignedInteger('price')->comment('Fixed price in naira');
            $table->unsignedInteger('driver_payout')->default(0);
            $table->string('meeting_point')->nullable();
            $table->string('name_board')->nullable();
            $table->string('notes')->nullable();
            $table->enum('payment_method', ['card', 'wallet', 'bank_transfer'])->default('card');
            $table->enum('payment_status', ['pending', 'paid', 'refunded'])->default('pending');
            $table->enum('status', ['confirmed', 'driver_assigned', 'in_progress', 'completed', 'cancelled'])->default('confirmed');
            $table->timestamp('driver_assigned_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shuttle_bookings');
        Schema::dropIfExists('trips');
        Schema::dropIfExists('settings');
        Schema::dropIfExists('zones');
        Schema::dropIfExists('ride_types');
    }
};
