<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('fleet_partners', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('area')->nullable();
            $table->string('contact_name')->nullable();
            $table->string('phone', 32)->nullable();
            $table->string('email')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('drivers', function (Blueprint $table) {
            $table->id();
            $table->string('first_name')->nullable();
            $table->string('last_name')->nullable();
            $table->string('email')->nullable()->unique();
            $table->string('phone', 32)->unique();
            $table->string('photo_url')->nullable();
            $table->date('date_of_birth')->nullable();
            $table->string('address')->nullable();
            $table->json('languages')->nullable();
            $table->enum('driver_type', ['independent', 'fleet'])->default('independent');
            $table->foreignId('fleet_partner_id')->nullable()->constrained()->nullOnDelete();
            $table->enum('status', ['applicant', 'pending_review', 'approved', 'suspended', 'rejected'])->default('applicant');
            $table->string('status_reason')->nullable();
            $table->enum('tier', ['standard', 'premium'])->default('standard');
            $table->boolean('is_tour_guide')->default(false);
            $table->boolean('training_completed')->default(false);
            $table->boolean('background_check_consent')->default(false);
            $table->timestamp('inspection_at')->nullable();
            $table->string('inspection_location')->nullable();
            $table->boolean('is_online')->default(false);
            $table->decimal('current_lat', 10, 7)->nullable();
            $table->decimal('current_lng', 10, 7)->nullable();
            $table->timestamp('location_updated_at')->nullable();
            $table->json('preferences')->nullable()->comment('Ride tiers, job types and destination filter');
            $table->decimal('rating', 3, 2)->nullable();
            $table->decimal('acceptance_rate', 5, 2)->default(100);
            $table->decimal('cancellation_rate', 5, 2)->default(0);
            $table->string('bank_name')->nullable();
            $table->string('bank_account_number', 20)->nullable();
            $table->string('bank_account_name')->nullable();
            $table->unsignedInteger('earnings_balance')->default(0)->comment('Naira, unpaid card earnings');
            $table->unsignedInteger('cash_commission_owed')->default(0)->comment('Naira, from cash trips');
            $table->string('referral_code', 16)->unique();
            $table->timestamp('approved_at')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        Schema::create('vehicles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->string('make');
            $table->string('model');
            $table->unsignedSmallInteger('year');
            $table->string('colour');
            $table->string('plate_number', 16)->unique();
            $table->unsignedTinyInteger('seats')->default(4);
            $table->json('ride_types')->nullable()->comment('Ride type codes this vehicle qualifies for');
            $table->boolean('wheelchair_accessible')->default(false);
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->boolean('is_active')->default(false);
            $table->timestamps();
        });

        Schema::create('driver_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->foreignId('vehicle_id')->nullable()->constrained()->cascadeOnDelete();
            $table->enum('type', [
                'drivers_licence', 'national_id', 'proof_of_address', 'lasdri_card', 'state_permit',
                'vehicle_licence', 'roadworthiness', 'insurance', 'vehicle_photo', 'selfie',
            ]);
            $table->string('label')->nullable();
            $table->string('file_path')->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->string('rejection_reason')->nullable();
            $table->date('expires_at')->nullable();
            $table->foreignId('reviewed_by')->nullable()->constrained('admins')->nullOnDelete();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamps();
            $table->index(['status', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('driver_documents');
        Schema::dropIfExists('vehicles');
        Schema::dropIfExists('drivers');
        Schema::dropIfExists('fleet_partners');
    }
};
