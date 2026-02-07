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
        
        // Pending Verifications
        $pendingVerifications = \App\Models\Rider::where('verification_status', 'submitted')->count();

        // Bill Payments Today
        $billPaymentsVolume = \App\Models\Transaction::where('status', 'completed')
            ->where('category', 'bill_payment')
            ->whereDate('created_at', today())
            ->sum('amount');

        return [
            Stat::make("Today's Revenue", '£' . number_format($todayRevenue, 2))
                ->description($revenueTrend >= 0 ? '+' . $revenueTrend . '% from yesterday' : $revenueTrend . '% from yesterday')
                ->descriptionIcon($revenueTrend >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($revenueTrend >= 0 ? 'primary' : 'danger')
                ->chart([$yesterdayRevenue, $todayRevenue]),
                
            Stat::make('Bill Payments', '£' . number_format($billPaymentsVolume, 2))
                ->description('Total volume today')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),

            Stat::make('Pending Verifications', $pendingVerifications)
                ->description($pendingVerifications > 0 ? 'Riders awaiting review' : 'All up to date')
                ->descriptionIcon('heroicon-m-user-plus')
                ->color($pendingVerifications > 0 ? 'warning' : 'success'),

            Stat::make('Active Deliveries', $activeDeliveries)
                ->description('Orders in progress')
                ->color('primary')
                ->descriptionIcon('heroicon-m-truck'),
        ];
    }
}
