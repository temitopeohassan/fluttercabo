<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Every money movement: charges, refunds, wallet top-ups, tips, payouts.
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 32)->unique();
            $table->nullableMorphs('owner'); // Rider or driver
            $table->nullableMorphs('subject'); // Trip, shuttle or tour booking
            $table->enum('type', ['charge', 'refund', 'wallet_topup', 'wallet_payment', 'tip', 'driver_earning', 'commission', 'payout', 'cash_settlement', 'referral_credit']);
            $table->enum('direction', ['credit', 'debit']);
            $table->unsignedInteger('amount')->comment('Naira');
            $table->enum('method', ['card', 'wallet', 'bank_transfer', 'cash', 'system'])->default('system');
            $table->enum('status', ['pending', 'succeeded', 'failed'])->default('succeeded');
            $table->string('description')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();
        });

        Schema::create('payouts', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 20)->unique();
            $table->foreignId('driver_id')->constrained()->cascadeOnDelete();
            $table->enum('type', ['weekly', 'instant']);
            $table->unsignedInteger('amount')->comment('Naira paid to the driver');
            $table->unsignedInteger('fee')->default(0);
            $table->date('period_start')->nullable();
            $table->date('period_end')->nullable();
            $table->string('bank_name');
            $table->string('bank_account_number', 20);
            $table->enum('status', ['pending', 'processing', 'paid', 'failed'])->default('pending');
            $table->foreignId('processed_by')->nullable()->constrained('admins')->nullOnDelete();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();
        });

        Schema::create('support_tickets', function (Blueprint $table) {
            $table->id();
            $table->string('reference', 20)->unique();
            $table->morphs('requester'); // Rider or driver
            $table->nullableMorphs('subject'); // Trip, shuttle or tour booking
            $table->enum('category', ['lost_item', 'overcharge', 'fare_dispute', 'refund', 'driver_behaviour', 'rider_behaviour', 'vehicle_damage', 'accident', 'payout', 'account', 'other']);
            $table->string('subject_line');
            $table->enum('status', ['open', 'in_review', 'awaiting_user', 'resolved'])->default('open');
            $table->enum('priority', ['low', 'normal', 'high', 'urgent'])->default('normal');
            $table->foreignId('assigned_admin_id')->nullable()->constrained('admins')->nullOnDelete();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamps();
        });

        Schema::create('support_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('support_ticket_id')->constrained()->cascadeOnDelete();
            $table->morphs('sender'); // Rider, driver or admin
            $table->text('body');
            $table->timestamps();
        });

        Schema::create('sos_alerts', function (Blueprint $table) {
            $table->id();
            $table->morphs('raised_by'); // Rider or driver
            $table->foreignId('trip_id')->nullable()->constrained()->nullOnDelete();
            $table->decimal('lat', 10, 7)->nullable();
            $table->decimal('lng', 10, 7)->nullable();
            $table->string('address')->nullable();
            $table->enum('status', ['open', 'acknowledged', 'resolved'])->default('open');
            $table->foreignId('handled_by')->nullable()->constrained('admins')->nullOnDelete();
            $table->timestamp('acknowledged_at')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();
        });

        // In-app notifications shown in the rider and driver inboxes.
        Schema::create('app_notifications', function (Blueprint $table) {
            $table->id();
            $table->morphs('recipient');
            $table->string('type', 40);
            $table->string('title');
            $table->string('body');
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        // Sign-ups from the website's waitlist form.
        Schema::create('waitlist_signups', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('source', 32)->default('website');
            $table->string('ip_address', 45)->nullable();
            $table->timestamp('invited_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('waitlist_signups');
        Schema::dropIfExists('app_notifications');
        Schema::dropIfExists('sos_alerts');
        Schema::dropIfExists('support_messages');
        Schema::dropIfExists('support_tickets');
        Schema::dropIfExists('payouts');
        Schema::dropIfExists('transactions');
    }
};
