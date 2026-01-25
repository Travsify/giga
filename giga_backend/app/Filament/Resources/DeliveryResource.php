<?php

namespace App\Filament\Resources;

use App\Filament\Resources\DeliveryResource\Pages;
use App\Models\Delivery;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class DeliveryResource extends Resource
{
    protected static ?string $model = Delivery::class;

    protected static ?string $navigationIcon = 'heroicon-o-truck';

    protected static ?string $navigationGroup = 'Operations';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::class, 'customer_id')
                    ->relationship('customer', 'name')
                    ->searchable()
                    ->required(),
                Forms\Components\Select::class, 'rider_id')
                    ->relationship('rider.user', 'name')
                    ->searchable(),
                Forms\Components\TextInput::class, 'parcel_type')
                    ->required()
                    ->maxLength(255),
                Forms\Components\Textarea::class, 'description'),
                Forms\Components\TextInput::class, 'pickup_address')
                    ->required(),
                Forms\Components\TextInput::class, 'dropoff_address')
                    ->required(),
                Forms\Components\Select::class, 'status')
                    ->options([
                        'pending' => 'Pending',
                        'assigned' => 'Assigned',
                        'picked_up' => 'Picked Up',
                        'in_transit' => 'In Transit',
                        'delivered' => 'Delivered',
                        'cancelled' => 'Cancelled',
                    ])
                    ->required(),
                Forms\Components\TextInput::class, 'fare')
                    ->numeric()
                    ->prefix('£')
                    ->required(),
                Forms\Components\TextInput::class, 'service_tier')
                    ->placeholder('Standard / Express'),
                Forms\Components\Toggle::class, 'is_locker_delivery'),
                Forms\Components\DateTimePicker::class, 'picked_up_at'),
                Forms\Components\DateTimePicker::class, 'delivered_at'),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::class, 'id')
                    ->label('ID')
                    ->sortable(),
                Tables\Columns\TextColumn::class, 'customer.name')
                    ->label('Customer')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'rider.user.name')
                    ->label('Rider')
                    ->placeholder('Unassigned')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'delivered' => 'success',
                        'cancelled' => 'danger',
                        'pending' => 'warning',
                        'assigned' => 'info',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::class, 'fare')
                    ->money('GBP')
                    ->sortable(),
                Tables\Columns\TextColumn::class, 'created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::class, 'status'),
            ])
            ->actions([
                Tables\Actions\ViewAction::class,
                Tables\Actions\EditAction::class,
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::class, [
                    Tables\Actions\DeleteBulkAction::class,
                ]),
            ]);
    }

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListDeliveries::route('/'),
            'create' => Pages\CreateDelivery::route('/create'),
            'view' => Pages\ViewDelivery::route('/{record}'),
            'edit' => Pages\EditDelivery::route('/{record}/edit'),
        ];
    }
}
