<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LockerResource\Pages;
use App\Models\Locker;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class LockerResource extends Resource
{
    protected static ?string $model = Locker::class;

    protected static ?string $navigationIcon = 'heroicon-o-archive-box';

    protected static ?string $navigationGroup = 'Settings';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('code')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('location_address')
                    ->required(),
                Forms\Components\TextInput::make('lat')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::make('lng')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::make('total_slots')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::make('available_slots')
                    ->numeric()
                    ->required(),
                Forms\Components\Toggle::make('is_active')
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('code')
                    ->searchable(),
                Tables\Columns\TextColumn::make('name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('location_address')
                    ->limit(30),
                Tables\Columns\TextColumn::make('available_slots')
                    ->label('Available')
                    ->badge()
                    ->color(fn ($state, $record) => $state < 5 ? 'danger' : 'success'),
                Tables\Columns\IconColumn::make('is_active')
                    ->boolean(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_active'),
            ])
            ->actions([
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
            'index' => Pages\ListLockers::route('/'),
            'create' => Pages\CreateLocker::route('/create'),
            'edit' => Pages\EditLocker::route('/{record}/edit'),
        ];
    }
}
