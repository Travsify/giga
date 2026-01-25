<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use App\Models\User;
use App\Models\Rider;
use App\Models\LogisticsCompany;
use App\Models\Wallet;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $totalRevenue = Wallet::sum('balance');
        $pendingDeliveries = Delivery::where('status', 'pending')->count();
        $completedToday = Delivery::whereDate('created_at', today())->where('status', 'delivered')->count();

        return [
            Stat::make('Total Deliveries', Delivery::count())
                ->description('All-time orders')
                ->descriptionIcon('heroicon-m-shopping-cart')
                ->color('primary')
                ->chart([7, 12, 8, 15, 22, 18, 25]),
            Stat::make('Active Riders', User::where('role', 'Rider')->count())
                ->description('Fleet capacity')
                ->descriptionIcon('heroicon-m-truck')
                ->color('success')
                ->chart([3, 5, 4, 6, 8, 7, 9]),
            Stat::make('Pending Now', $pendingDeliveries)
                ->description('Awaiting pickup')
                ->descriptionIcon('heroicon-m-clock')
                ->color('warning'),
            Stat::make('Partners', LogisticsCompany::count())
                ->description('B2B enrolled')
                ->descriptionIcon('heroicon-m-building-office')
                ->color('primary'),
            Stat::make('Completed Today', $completedToday)
                ->description('Daily throughput')
                ->descriptionIcon('heroicon-m-check-circle')
                ->color('success'),
            Stat::make('Wallet Balance', '£' . number_format($totalRevenue, 2))
                ->description('Total in wallets')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('primary'),
        ];
    }
}
