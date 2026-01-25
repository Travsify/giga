<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use Filament\Widgets\ChartWidget;
use Carbon\Carbon;

class AvgDeliveryTimeChart extends ChartWidget
{
    protected static ?string $heading = 'Avg Delivery Time';
    
    protected static ?int $sort = 6;
    
    protected int | string | array $columnSpan = 1;

    protected function getData(): array
    {
        // Mocking some trend data for the last 7 days to match reference aesthetics
        $data = [6.5, 5.2, 4.8, 4.7, 3.9, 4.5, 4.2];

        return [
            'datasets' => [
                [
                    'label' => 'Hours',
                    'data' => $data,
                    'borderColor' => '#0D9488', // Teal
                    'backgroundColor' => 'rgba(13, 148, 136, 0.1)',
                    'fill' => true,
                    'tension' => 0.4,
                ],
            ],
            'labels' => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
