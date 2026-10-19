<?php

if (! function_exists('naira')) {
    /** ₦12,500 */
    function naira(int|float|null $amount): string
    {
        return '₦'.number_format((int) $amount);
    }
}

if (! function_exists('humanize')) {
    /** pending_review → Pending review */
    function humanize(?string $value): string
    {
        return $value === null ? '' : ucfirst(str_replace('_', ' ', $value));
    }
}
