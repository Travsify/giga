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
        // Calculate revenue with trend
        $currentRevenue = Wallet::sum('balance');
        $lastMonthRevenue = Wallet::where('created_at', '<', Carbon::now()->startOfMonth())
            ->sum('balance');
        $revenueTrend = $lastMonthRevenue > 0 
            ? round((($currentRevenue - $lastMonthRevenue) / $lastMonthRevenue) * 100, 1) 
            : 0;

        // Active deliveries (not completed)
        $activeDeliveries = Delivery::whereNotIn('status', ['delivered', 'cancelled'])->count();
        $lastWeekActive = Delivery::whereNotIn('status', ['delivered', 'cancelled'])
            ->where('created_at', '<', Carbon::now()->subWeek())
            ->count();
        $activeTrend = $lastWeekActive > 0 
            ? round((($activeDeliveries - $lastWeekActive) / $lastWeekActive) * 100, 1) 
            : 0;

        // Online riders (riders with recent activity or just count)
        $onlineRiders = User::where('role', 'Rider')->count();
        $lastMonthRiders = User::where('role', 'Rider')
            ->where('created_at', '<', Carbon::now()->startOfMonth())
            ->count();
        $riderTrend = $lastMonthRiders > 0 
            ? round((($onlineRiders - $lastMonthRiders) / $lastMonthRiders) * 100, 1) 
            : 0;

        return [
            Stat::make('Total Revenue', '£' . number_format($currentRevenue, 0))
                ->description($this->getTrendLabel($revenueTrend))
                ->descriptionIcon($revenueTrend >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color($revenueTrend >= 0 ? 'success' : 'danger')
                ->chart($this->getRevenueChart()),
                
            Stat::make('Active Deliveries', $activeDeliveries)
                ->description($this->getTrendLabel($activeTrend))
                ->descriptionIcon($activeTrend >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color('warning')
                ->chart($this->getDeliveryChart()),
                
            Stat::make('Online Riders', $onlineRiders)
                ->description($this->getTrendLabel($riderTrend))
                ->descriptionIcon($riderTrend >= 0 ? 'heroicon-m-arrow-trending-up' : 'heroicon-m-arrow-trending-down')
                ->color('primary')
                ->chart($this->getRiderChart()),
        ];
    }

    private function getTrendLabel(float $trend): string
    {
        $sign = $trend >= 0 ? '+' : '';
        return $sign . $trend . '%';
    }

    private function getRevenueChart(): array
    {
        // Get last 7 days of wallet transactions
        return Delivery::selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->where('created_at', '>=', Carbon::now()->subDays(7))
            ->groupBy('date')
            ->orderBy('date')
            ->pluck('count')
            ->toArray() ?: [0, 0, 0, 0, 0, 0, 0];
    }

    private function getDeliveryChart(): array
    {
        return Delivery::selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->where('created_at', '>=', Carbon::now()->subDays(7))
            ->groupBy('date')
            ->orderBy('date')
            ->pluck('count')
            ->toArray() ?: [0, 0, 0, 0, 0, 0, 0];
    }

    private function getRiderChart(): array
    {
        return User::where('role', 'Rider')
            ->selectRaw('DATE(created_at) as date, COUNT(*) as count')
            ->where('created_at', '>=', Carbon::now()->subDays(7))
            ->groupBy('date')
            ->orderBy('date')
            ->pluck('count')
            ->toArray() ?: [0, 0, 0, 0, 0, 0, 0];
    }
}
