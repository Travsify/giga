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
                Forms\Components\Select::make('customer_id')
                    ->relationship('customer', 'name')
                    ->searchable()
                    ->required(),
                Forms\Components\Select::make('rider_id')
                    ->relationship('rider.user', 'name')
                    ->searchable(),
                Forms\Components\TextInput::make('parcel_type')
                    ->required()
                    ->maxLength(255),
                Forms\Components\Textarea::make('description'),
                Forms\Components\TextInput::make('pickup_address')
                    ->required(),
                Forms\Components\TextInput::make('dropoff_address')
                    ->required(),
                Forms\Components\Select::make('status')
                    ->options([
                        'pending' => 'Pending',
                        'assigned' => 'Assigned',
                        'picked_up' => 'Picked Up',
                        'in_transit' => 'In Transit',
                        'delivered' => 'Delivered',
                        'cancelled' => 'Cancelled',
                    ])
                    ->required(),
                Forms\Components\TextInput::make('fare')
                    ->numeric()
                    ->prefix('£')
                    ->required(),
                Forms\Components\TextInput::make('service_tier')
                    ->placeholder('Standard / Express'),
                Forms\Components\Toggle::make('is_locker_delivery'),
                Forms\Components\DateTimePicker::make('picked_up_at'),
                Forms\Components\DateTimePicker::make('delivered_at'),
                Forms\Components\Section::make('Delivery Stops')
                    ->schema([
                        Forms\Components\Repeater::make('stops')
                            ->relationship()
                            ->schema([
                                Forms\Components\TextInput::make('address')
                                    ->required()
                                    ->columnSpan(2),
                                Forms\Components\TextInput::make('lat')
                                    ->numeric()
                                    ->required(),
                                Forms\Components\TextInput::make('lng')
                                    ->numeric()
                                    ->required(),
                                Forms\Components\Select::make('type')
                                    ->options([
                                        'pickup' => 'Pickup',
                                        'dropoff' => 'Dropoff',
                                    ])
                                    ->required(),
                                Forms\Components\Select::make('status')
                                    ->options([
                                        'pending' => 'Pending',
                                        'arrived' => 'Arrived',
                                        'departed' => 'Departed',
                                        'failed' => 'Failed',
                                    ])
                                    ->required(),
                                Forms\Components\TextInput::make('stop_order')
                                    ->numeric()
                                    ->default(0),
                                Forms\Components\Textarea::make('instructions')
                                    ->columnSpanFull(),
                            ])
                            ->columns(3)
                            ->defaultItems(2)
                            ->reorderableWithButtons(),
                    ]),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('id')
                    ->label('ID')
                    ->sortable(),
                Tables\Columns\TextColumn::make('customer.name')
                    ->label('Customer')
                    ->searchable(),
                Tables\Columns\TextColumn::make('rider.user.name')
                    ->label('Rider')
                    ->placeholder('Unassigned')
                    ->searchable(),
                Tables\Columns\TextColumn::make('status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'delivered' => 'success',
                        'cancelled' => 'danger',
                        'pending' => 'warning',
                        'assigned' => 'info',
                        default => 'gray',
                    }),
                Tables\Columns\TextColumn::make('fare')
                    ->money('GBP')
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('status'),
            ])
            ->actions([
                Tables\Actions\ViewAction::make(),
                Tables\Actions\EditAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
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
