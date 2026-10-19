<?php

namespace App\Services;

use App\Models\PromoCode;
use App\Models\RideType;
use App\Models\Setting;
use App\Models\Zone;
use App\Support\Geo;

/**
 * Upfront ride pricing: base + distance + time, multiplied by the pickup
 * zone's surge, never below the ride type's minimum, plus stops and tolls.
 */
class FareCalculator
{
    /** Lagos roads are not straight lines. */
    private const ROAD_FACTOR = 1.35;

    /** Average city speed used for the duration estimate. */
    private const AVERAGE_KMH = 22;

    public function estimate(RideType $type, float $fromLat, float $fromLng, float $toLat, float $toLng, array $stops = [], ?PromoCode $promo = null): array
    {
        $points = array_merge([[$fromLat, $fromLng]], array_map(fn ($s) => [(float) $s['lat'], (float) $s['lng']], $stops), [[$toLat, $toLng]]);

        $distance = 0.0;
        for ($i = 1; $i < count($points); $i++) {
            $distance += Geo::distanceKm($points[$i - 1][0], $points[$i - 1][1], $points[$i][0], $points[$i][1]);
        }
        $distance = round(max(0.5, $distance * self::ROAD_FACTOR), 2);
        $minutes = (int) max(3, ceil($distance / self::AVERAGE_KMH * 60));

        $zone = Zone::at($fromLat, $fromLng);
        $surge = $zone?->surge_multiplier ?? 1.0;

        $base = $type->base_fare;
        $distanceFare = (int) round($distance * $type->per_km);
        $timeFare = $minutes * $type->per_minute;
        $subtotal = (int) round(($base + $distanceFare + $timeFare) * $surge);
        $subtotal = max($subtotal, $type->minimum_fare);

        $stopsFare = count($stops) * (int) Setting::read('stop_fee', 300);
        $tolls = $this->tolls($points);
        $gross = $subtotal + $stopsFare + $tolls;
        $discount = $promo ? $promo->discountFor($gross) : 0;
        $total = $gross - $discount;

        return [
            'ride_type' => $type->code,
            'distance_km' => $distance,
            'duration_minutes' => $minutes,
            'zone' => $zone?->name,
            'surge_multiplier' => $surge,
            'fare_base' => $base,
            'fare_distance' => $distanceFare,
            'fare_time' => $timeFare,
            'fare_stops' => $stopsFare,
            'tolls' => $tolls,
            'discount' => $discount,
            'fare_total' => $total,
            'currency' => 'NGN',
        ];
    }

    /** Commission and driver share of a fare. Tips go entirely to the driver. */
    public function split(int $fare): array
    {
        $rate = (float) Setting::read('commission_rate', 20);
        $commission = (int) round($fare * $rate / 100);

        return ['commission' => $commission, 'driver_earnings' => $fare - $commission];
    }

    /** Lekki toll gate charge when a route crosses it. */
    private function tolls(array $points): int
    {
        // Lekki Toll Gate sits at roughly 6.4315, 3.4600 on the Lekki–Epe Expressway.
        $tollLng = 3.4600;
        $fee = (int) Setting::read('lekki_toll', 250);
        for ($i = 1; $i < count($points); $i++) {
            [$aLat, $aLng] = $points[$i - 1];
            [$bLat, $bLng] = $points[$i];
            $crosses = ($aLng - $tollLng) * ($bLng - $tollLng) < 0;
            $onCorridor = min($aLat, $bLat) < 6.46 && max($aLat, $bLat) > 6.42;
            if ($crosses && $onCorridor) {
                return $fee;
            }
        }

        return 0;
    }
}
