<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use App\Models\User;
use App\Models\LogisticsCompany;
use App\Models\Wallet;
use Carbon\Carbon;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    protected static ?int $sort = 1;
    
    protected int | string | array $columnSpan = 'full';

    protected function getStats(): array
    {
        return [
            Stat::make('Total Shipments', Delivery::count())
                ->extraAttributes(['class' => 'stat-card-blue']),
                
            Stat::make('Pending', Delivery::where('status', 'pending')->count())
                ->extraAttributes(['class' => 'stat-card-red']),
                
            Stat::make('Delivered', Delivery::where('status', 'delivered')->count())
                ->extraAttributes(['class' => 'stat-card-purple']),
                
            Stat::make('Cancelled', Delivery::where('status', 'cancelled')->count())
                ->extraAttributes(['class' => 'stat-card-navy']),
                
            Stat::make('In Transit', Delivery::whereIn('status', ['picked_up', 'in_transit'])->count())
                ->extraAttributes(['class' => 'stat-card-green']),
                
            Stat::make('Returned', Delivery::where('status', 'returned')->count())
                ->extraAttributes(['class' => 'stat-card-orange']),
        ];
    }

    private function getTrendLabel(float $trend): string
    {
        $sign = $trend >= 0 ? '+' : '';
        return $sign . $trend . '%';
    }
}
