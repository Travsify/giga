<?php

namespace App\Filament\Widgets;

use App\Models\Delivery;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\BadgeColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class RecentShipmentsTable extends BaseWidget
{
    protected static ?int $sort = 3;
    
    protected int | string | array $columnSpan = 1;

    protected static ?string $heading = 'Recent Shipments';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Delivery::query()
                    ->latest()
                    ->limit(5)
            )
            ->columns([
                TextColumn::make('id')
                    ->label('ID')
                    ->formatStateUsing(fn ($state) => '#' . $state)
                    ->color('gray'),
                    
                TextColumn::make('receiver_name')
                    ->label('Recipient')
                    ->searchable()
                    ->limit(15),
                    
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'pending' => 'warning',
                        'assigned' => 'info',
                        'picked_up', 'in_transit' => 'primary',
                        'delivered' => 'success',
                        'cancelled' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => match ($state) {
                        'pending' => 'Pending',
                        'assigned' => 'Assigned',
                        'picked_up' => 'Picked Up',
                        'in_transit' => 'In Transit',
                        'delivered' => 'Delivered',
                        'cancelled' => 'Cancelled',
                        default => ucfirst($state),
                    }),
                    
                TextColumn::make('created_at')
                    ->label('Date')
                    ->date('M d, Y')
                    ->color('gray'),
            ])
            ->paginated(false);
    }
}
