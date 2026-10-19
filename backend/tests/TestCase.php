<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    /**
     * Tests share one in-memory database that is migrated once per run, so
     * every test seeds the same sample data and rolls back its own changes.
     */
    protected bool $seed = true;
}
