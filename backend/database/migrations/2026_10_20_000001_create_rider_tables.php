<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('riders', function (Blueprint $table) {
            $table->id();
            $table->string('first_name')->nullable();
            $table->string('last_name')->nullable();
            $table->string('email')->nullable()->unique();
            $table->string('phone', 32)->nullable()->unique();
            $table->string('photo_url')->nullable();
            $table->string('nationality')->nullable();
            $table->char('home_currency', 3)->default('NGN');
            $table->enum('traveller_type', ['international', 'domestic', 'resident'])->nullable();
            $table->string('language', 8)->default('en');
            $table->json('accessibility')->nullable();
            $table->unsignedInteger('wallet_balance')->default(0)->comment('Naira');
            $table->unsignedInteger('loyalty_points')->default(0);
            $table->string('referral_code', 16)->unique();
            $table->foreignId('referred_by_id')->nullable()->constrained('riders')->nullOnDelete();
            $table->enum('status', ['active', 'suspended'])->default('active');
            $table->decimal('rating', 3, 2)->nullable();
            $table->timestamp('last_active_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('emergency_contacts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('phone', 32);
            $table->string('relationship')->nullable();
            $table->boolean('share_trips_automatically')->default(false);
            $table->timestamps();
        });

        Schema::create('saved_places', function (Blueprint $table) {
            $table->id();
            $table->foreignId('rider_id')->constrained()->cascadeOnDelete();
            $table->string('label');
            $table->string('address');
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->timestamps();
        });

        // One-time passcodes for rider and driver sign-in by SMS or email.
        Schema::create('otp_codes', function (Blueprint $table) {
            $table->id();
            $table->enum('app', ['rider', 'driver']);
            $table->string('identifier')->comment('Phone number or email');
            $table->enum('channel', ['sms', 'email']);
            $table->string('code_hash');
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('expires_at');
            $table->timestamp('used_at')->nullable();
            $table->timestamps();
            $table->index(['app', 'identifier']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('otp_codes');
        Schema::dropIfExists('saved_places');
        Schema::dropIfExists('emergency_contacts');
        Schema::dropIfExists('riders');
    }
};
