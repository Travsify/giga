<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RiderResource\Pages;
use App\Models\Rider;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class RiderResource extends Resource
{
    protected static ?string $model = Rider::class;

    protected static ?string $navigationIcon = 'heroicon-o-user-circle';

    protected static ?string $navigationGroup = 'User Management';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::class, 'user_id')
                    ->relationship('user', 'name')
                    ->required()
                    ->searchable(),
                Forms\Components\Select::class, 'vehicle_type')
                    ->options([
                        'bike' => 'Bike',
                        'van' => 'Van',
                        'truck' => 'Truck',
                    ])
                    ->required(),
                Forms\Components\Toggle::class, 'is_online')
                    ->required(),
                Forms\Components\Toggle::class, 'is_verified')
                    ->required(),
                Forms\Components\TextInput::class, 'current_lat')
                    ->numeric(),
                Forms\Components\TextInput::class, 'current_lng')
                    ->numeric(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::class, 'user.name')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'vehicle_type')
                    ->sortable(),
                Tables\Columns\IconColumn::class, 'is_online')
                    ->boolean(),
                Tables\Columns\IconColumn::class, 'is_verified')
                    ->boolean(),
                Tables\Columns\TextColumn::class, 'current_lat'),
                Tables\Columns\TextColumn::class, 'current_lng'),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::class, 'is_online'),
                Tables\Filters\TernaryFilter::class, 'is_verified'),
            ])
            ->actions([
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
            'index' => Pages\ListRiders::route('/'),
            'create' => Pages\CreateRider::route('/create'),
            'edit' => Pages\EditRider::route('/{record}/edit'),
        ];
    }
}
