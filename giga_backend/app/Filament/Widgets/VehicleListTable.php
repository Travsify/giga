<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class VehicleListTable extends BaseWidget
{
    protected static ?int $sort = 3;
    
    protected int | string | array $columnSpan = 'full';

    protected static ?string $heading = 'Vehicle List';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Delivery::query()
                    ->latest()
                    ->limit(6)
            )
            ->columns([
                TextColumn::make('id')
                    ->label('Vehicle ID')
                    ->formatStateUsing(fn ($state) => 'VH-' . (1000 + $state))
                    ->weight('bold'),
                    
                TextColumn::make('type') // Mocking type based on ID
                    ->label('Type')
                    ->icon(fn ($record) => $record->id % 2 == 0 ? 'heroicon-m-truck' : 'heroicon-m-shopping-cart')
                    ->label(''),
                    
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'assigned' => 'danger',
                        'picked_up', 'in_transit' => 'info',
                        'delivered' => 'success',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'Available',
                        'assigned' => 'Assigned',
                        'picked_up' => 'Active',
                        'in_transit' => 'In Transit',
                        'delivered' => 'On Hold',
                        default => ucfirst($state),
                    }),

                TextColumn::make('receiver_address')
                    ->label('Current Location')
                    ->limit(25),
                    
                TextColumn::make('user.name')
                    ->label('Driver Assigned')
                    ->formatStateUsing(fn ($state) => $state ?? 'Unassigned'),
            ])
            ->paginated(false);
    }
}
