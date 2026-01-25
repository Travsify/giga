<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use Filament\Widgets\ChartWidget;

class VehicleStatusChart extends ChartWidget
{
    protected static ?string $heading = 'Vehicle Status';
    
    protected static ?int $sort = 4;
    
    protected int | string | array $columnSpan = 1;

    protected function getData(): array
    {
        $data = [
            Delivery::whereIn('status', ['picked_up', 'in_transit'])->count(), // Active
            Delivery::where('status', 'pending')->count(), // In Transit (Mapped to Pending for mockup)
            Delivery::where('status', 'assigned')->count(), // Available (Mapped to Assigned)
            Delivery::where('status', 'returned')->count(), // Out/Maintenance (Mapped to Returned)
        ];

        return [
            'datasets' => [
                [
                    'label' => 'Vehicles',
                    'data' => $data,
                    'backgroundColor' => [
                        '#3B82F6', // Blue
                        '#10B981', // Green
                        '#F59E0B', // Yellow/Gold
                        '#EF4444', // Red
                    ],
                ],
            ],
            'labels' => ['Active', 'In Transit', 'Available', 'Maintenance'],
        ];
    }

    protected function getType(): string
    {
        return 'bar';
    }
}
