<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use App\Models\User;
use App\Models\LogisticsCompany;
use Filament\Widgets\StatsOverviewWidget as BaseWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StatsOverview extends BaseWidget
{
    protected function getStats(): array
    {
        return [
            Stat::make('Total Deliveries', Delivery::count())
                ->description('Total orders processed')
                ->descriptionIcon('heroicon-m-shopping-cart')
                ->color('success'),
            Stat::make('Active Riders', User::where('role', 'Rider')->count())
                ->description('Riders currently in system')
                ->descriptionIcon('heroicon-m-truck')
                ->color('primary'),
            Stat::make('Partner Businesses', LogisticsCompany::count())
                ->description('Companies enrolled')
                ->descriptionIcon('heroicon-m-building-office')
                ->color('warning'),
        ];
    }
}
