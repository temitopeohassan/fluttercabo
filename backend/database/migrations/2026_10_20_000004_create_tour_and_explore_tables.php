<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Tour operators, guides, attractions and hotels (the partner portal).
        Schema::create('partners', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('type', ['tour_operator', 'guide', 'attraction', 'hotel'])->default('tour_operator');
            $table->string('contact_name')->nullable();
            $table->string('email')->nullable();
            $table->string('phone', 32)->nullable();
            $table->string('cac_number', 32)->nullable();
            $table->enum('status', ['pending', 'approved', 'suspended'])->default('pending');
            $table->decimal('commission_rate', 5, 2)->default(15);
            $table->string('bank_name')->nullable();
            $table->string('bank_account_number', 20)->nullable();
            $table->string('bank_account_name')->nullable();
            $table->timestamps();
        });

        Schema::create('tour_categories', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('icon')->nullable();
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('tours', function (Blueprint $table) {
            $table->id();
            $table->foreignId('partner_id')->constrained()->cascadeOnDelete();
            $table->foreignId('tour_category_id')->constrained();
            $table->string('title');
            $table->string('slug')->unique();
            $table->text('description');
            $table->string('area');
            $table->string('meeting_point');
            $table->decimal('meeting_lat', 10, 7)->nullable();
            $table->decimal('meeting_lng', 10, 7)->nullable();
            $table->unsignedSmallInteger('duration_minutes');
            $table->unsignedInteger('price')->comment('Naira per person');
            $table->unsignedTinyInteger('min_group_size')->default(1);
            $table->unsignedTinyInteger('max_group_size')->default(10);
            $table->json('languages')->nullable();
            $table->json('itinerary')->nullable();
            $table->json('inclusions')->nullable();
            $table->json('exclusions')->nullable();
            $table->json('addons')->nullable()->comment('Partner add-ons: code, name, price');
            $table->string('cancellation_policy')->nullable();
            $table->string('image_url')->nullable();
            $table->boolean('wheelchair_accessible')->default(false);
            $table->decimal('rating', 3, 2)->nullable();
            $table->unsignedInteger('reviews_count')->default(0);
            $table->boolean('is_featured')->default(false);
            $table->boolean('is_published')->default(false);
            $table->timestamps();
        });

        Schema::create('tour_slots', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tour_id')->constrained()->cascadeOnDelete();
            $table->timestamp('starts_at');
            $table->unsignedTinyInteger('capacity');
            $table->unsignedTinyInteger('booked')->default(0);
            $table->foreignId('guide_driver_id')->nullable()->constrained('drivers')->nullOnDelete();
            $table->timestamps();
            $table->unique(['tour_id', 'starts_at']);
        });

        Schema::create('promo_codes', function (Blueprint $table) {
            $table->id();
            $table->string('code', 32)->unique();
            $table->string('description');
            $table->enum('discount_type', ['percent', 'fixed']);
            $table->unsignedInteger('value')->comment('Percent or naira');
            $table->unsignedInteger('max_discount')->nullable()->comment('Naira cap for percent codes');
            $table->enum('applies_to', ['all', 'ride', 'shuttle', 'tour'])->default('all');
            $table->boolean('first_booking_only')->default(false);
            $table->unsignedInteger('usage_limit')->nullable();
            $table->unsignedInteger('used_count')->default(0);
            $table->timestamp('starts_at')->nullable();
            $table->timestamp('ends_at')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('tour_bookings', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 20)->unique();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->foreignId('tour_id')->constrained();
            $table->foreignId('tour_slot_id')->constrained();
            $table->unsignedTinyInteger('guests');
            $table->unsignedInteger('subtotal');
            $table->json('addons')->nullable();
            $table->unsignedInteger('addons_total')->default(0);
            $table->unsignedInteger('ride_addon_price')->default(0);
            $table->foreignId('ride_trip_id')->nullable()->constrained('trips')->nullOnDelete();
            $table->foreignId('promo_code_id')->nullable()->constrained()->nullOnDelete();
            $table->unsignedInteger('discount')->default(0);
            $table->unsignedInteger('total');
            $table->enum('payment_method', ['card', 'wallet', 'bank_transfer']);
            $table->enum('payment_status', ['pending', 'paid', 'refunded', 'partially_refunded'])->default('pending');
            $table->unsignedInteger('refund_amount')->default(0);
            $table->enum('status', ['confirmed', 'checked_in', 'completed', 'cancelled'])->default('confirmed');
            $table->string('qr_token', 40)->unique();
            $table->string('company_name')->nullable();
            $table->timestamp('checked_in_at')->nullable();
            $table->timestamp('cancelled_at')->nullable();
            $table->timestamps();
        });

        Schema::create('reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->foreignId('tour_id')->constrained()->cascadeOnDelete();
            $table->foreignId('tour_booking_id')->unique()->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->json('highlights')->nullable();
            $table->boolean('is_visible')->default(true);
            $table->timestamps();
        });

        Schema::create('attractions', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('category');
            $table->string('area');
            $table->text('description');
            $table->string('address')->nullable();
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->string('opening_hours')->nullable();
            $table->unsignedInteger('entry_fee')->default(0)->comment('Naira, 0 for free');
            $table->json('visitor_tips')->nullable();
            $table->text('safety_notes')->nullable();
            $table->string('image_url')->nullable();
            $table->decimal('rating', 3, 2)->nullable();
            $table->unsignedInteger('reviews_count')->default(0);
            $table->boolean('is_published')->default(true);
            $table->date('last_reviewed_on')->nullable()->comment('Content is checked at least quarterly');
            $table->timestamps();
        });

        Schema::create('wishlist_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->morphs('item');
            $table->timestamps();
            $table->unique(['rider_id', 'item_type', 'item_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('wishlist_items');
        Schema::dropIfExists('attractions');
        Schema::dropIfExists('reviews');
        Schema::dropIfExists('tour_bookings');
        Schema::dropIfExists('promo_codes');
        Schema::dropIfExists('tour_slots');
        Schema::dropIfExists('tours');
        Schema::dropIfExists('tour_categories');
        Schema::dropIfExists('partners');
    }
};
