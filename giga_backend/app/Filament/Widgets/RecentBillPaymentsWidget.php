<?php

namespace App\Filament\Widgets;

use App\Models\Transaction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget as BaseWidget;

class RecentBillPaymentsWidget extends BaseWidget
{
    protected static ?int $sort = 4;
    
    protected int | string | array $columnSpan = 1;

    protected static ?string $heading = 'Recent Bill Payments';

    public function table(Table $table): Table
    {
        return $table
            ->query(
                Transaction::query()
                    ->where('category', 'bill_payment')
                    ->latest()
                    ->limit(5)
            )
            ->columns([
                TextColumn::make('reference')
                    ->label('Ref')
                    ->searchable()
                    ->limit(8)
                    ->color('gray'),
                    
                TextColumn::make('description')
                    ->label('Biller')
                    ->limit(20),
                    
                TextColumn::make('amount')
                    ->money(fn ($record) => $record->currency ?? 'GBP')
                    ->color('success')
                    ->weight('bold'),
                    
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'completed' => 'success',
                        'pending' => 'warning',
                        'failed' => 'danger',
                        default => 'gray',
                    }),
            ])
            ->paginated(false);
    }
}
