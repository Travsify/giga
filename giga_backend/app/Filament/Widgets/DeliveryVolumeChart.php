<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use Carbon\Carbon;
use Filament\Widgets\ChartWidget;

class DeliveryVolumeChart extends ChartWidget
{
    protected static ?string $heading = 'Delivery Volume';
    
    protected static ?int $sort = 2;
    
    protected int | string | array $columnSpan = 'full';
    
    protected static ?string $maxHeight = '300px';

    protected function getData(): array
    {
        $months = collect();
        $data = collect();

        // Get last 7 months of data
        for ($i = 6; $i >= 0; $i--) {
            $date = Carbon::now()->subMonths($i);
            $months->push($date->format('M'));
            
            $count = Delivery::whereYear('created_at', $date->year)
                ->whereMonth('created_at', $date->month)
                ->count();
            
            $data->push($count);
        }

        return [
            'datasets' => [
                [
                    'label' => 'Deliveries',
                    'data' => $data->toArray(),
                    'fill' => true,
                    'backgroundColor' => 'rgba(193, 39, 45, 0.3)',  // Giga Red with opacity
                    'borderColor' => 'rgb(193, 39, 45)',           // Giga Red
                    'tension' => 0.4,
                ],
            ],
            'labels' => $months->toArray(),
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }

    protected function getOptions(): array
    {
        return [
            'plugins' => [
                'legend' => [
                    'display' => false,
                ],
            ],
            'scales' => [
                'y' => [
                    'beginAtZero' => true,
                    'grid' => [
                        'display' => true,
                        'color' => 'rgba(0, 0, 0, 0.05)',
                    ],
                ],
                'x' => [
                    'grid' => [
                        'display' => false,
                    ],
                ],
            ],
            'elements' => [
                'point' => [
                    'radius' => 4,
                    'hoverRadius' => 6,
                    'backgroundColor' => 'rgb(255, 255, 255)',
                    'borderWidth' => 2,
                ],
            ],
        ];
    }
}
