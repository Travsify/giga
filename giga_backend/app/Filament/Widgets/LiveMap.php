<?php

namespace App\Filament\Widgets;

use App\Models\User;
use App\Models\Delivery;
use Filament\Widgets\Widget;

class LiveMap extends Widget
{
    protected static string $view = 'filament.widgets.live-map';
    
    protected static ?int $sort = 4;
    
    protected int | string | array $columnSpan = 1;

    protected static ?string $pollingInterval = '10s';

    public function getActiveRiderCount(): int
    {
        return User::where('role', 'Rider')->count();
    }

    public function getPendingDeliveries(): int
    {
        return Delivery::where('status', 'pending')->count();
    }

    public function getInTransitDeliveries(): int
    {
        return Delivery::whereIn('status', ['picked_up', 'in_transit'])->count();
    }

    public function getTodayDelivered(): int
    {
        return Delivery::where('status', 'delivered')
            ->whereDate('updated_at', today())
            ->count();
    }

    public function getDriverLocations(): array
    {
        return Delivery::whereIn('status', ['picked_up', 'in_transit'])
            ->whereNotNull('rider_lat')
            ->whereNotNull('rider_lng')
            ->get()
            ->map(function ($delivery) {
                return [
                    'id' => $delivery->id,
                    'lat' => $delivery->rider_lat,
                    'lng' => $delivery->rider_lng,
                    'name' => $delivery->rider_name ?? 'Rider',
                    'status' => $delivery->status,
                ];
            })
            ->toArray();
    }
}
