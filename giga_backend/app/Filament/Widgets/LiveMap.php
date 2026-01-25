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
}
