<?php

namespace Database\Seeders;

use App\Models\Admin;
use Illuminate\Database\Seeder;

class AdminSeeder extends Seeder
{
    public function run(): void
    {
        // Main control panel login. Change this password before going live.
        Admin::updateOrCreate(
            ['email' => 'admin@caboapp.online'],
            ['name' => 'Cabo Admin', 'password' => 'password123!', 'role' => 'super_admin', 'is_active' => true],
        );

        foreach ([
            ['Ngozi Adeyemi', 'ops@caboapp.online', 'operations'],
            ['Kelechi Eze', 'support@caboapp.online', 'support'],
            ['Funke Balogun', 'finance@caboapp.online', 'finance'],
        ] as [$name, $email, $role]) {
            Admin::updateOrCreate(['email' => $email], ['name' => $name, 'password' => 'password123!', 'role' => $role, 'is_active' => true]);
        }
    }
}
