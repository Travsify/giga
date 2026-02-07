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
        // Today's Revenue (Transactions created today with 'completed' status)
        $todayRevenue = \App\Models\Transaction::where('status', 'completed')
            ->whereDate('created_at', today())
            ->sum('amount');
        
        $yesterdayRevenue = \App\Models\Transaction::where('status', 'completed')
            ->whereDate('created_at', today()->subDay())
            ->sum('amount');
        
        $revenueTrend = $yesterdayRevenue > 0 
            ? round((($todayRevenue - $yesterdayRevenue) / $yesterdayRevenue) * 100, 1) 
            : 0;

        // Active deliveries
        $activeDeliveries = Delivery::whereNotIn('status', ['delivered', 'cancelled'])->count();
        
        // Pending Incidents
        $pendingIncidents = \App\Models\Incident::where('status', 'pending')->count();

        return [
            Stat::make("Today's Revenue", '£' . number_format($todayRevenue, 2))
                ->description($revenueTrend >= 0 ? '+' . $revenueTrend . '% from yesterday' : $revenueTrend . '% from yesterday')
                ->descriptionIcon($revenueTrend >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($revenueTrend >= 0 ? 'primary' : 'danger')
                ->chart([$yesterdayRevenue, $todayRevenue]),
                
            Stat::make('Active Deliveries', $activeDeliveries)
                ->description('Orders currently in progress')
                ->color('success')
                ->descriptionIcon('heroicon-m-truck'),
                
            Stat::make('Safety Incidents', $pendingIncidents)
                ->description($pendingIncidents > 0 ? 'Requires urgent attention' : 'All clear')
                ->descriptionIcon('heroicon-m-shield-exclamation')
                ->color($pendingIncidents > 0 ? 'danger' : 'success'),
        ];
    }
}
