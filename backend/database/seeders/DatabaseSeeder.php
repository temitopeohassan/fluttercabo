<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Same sample data on every run.
        mt_srand(2026);

        $this->call([
            AdminSeeder::class,
            PlatformSeeder::class,
            ExploreSeeder::class,
            PeopleSeeder::class,
            ActivitySeeder::class,
        ]);
    }
}
