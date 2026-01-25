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

    protected static ?string $navigationGroup = 'Infrastructure';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::class, 'code')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),
                Forms\Components\TextInput::class, 'name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::class, 'location_address')
                    ->required(),
                Forms\Components\TextInput::class, 'lat')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::class, 'lng')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::class, 'total_slots')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::class, 'available_slots')
                    ->numeric()
                    ->required(),
                Forms\Components\Toggle::class, 'is_active')
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::class, 'code')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'name')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'location_address')
                    ->limit(30),
                Tables\Columns\TextColumn::class, 'available_slots')
                    ->label('Available')
                    ->badge()
                    ->color(fn ($state, $record) => $state < 5 ? 'danger' : 'success'),
                Tables\Columns\IconColumn::class, 'is_active')
                    ->boolean(),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::class, 'is_active'),
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
            'index' => Pages\ListLockers::route('/'),
            'create' => Pages\CreateLocker::route('/create'),
            'edit' => Pages\EditLocker::route('/{record}/edit'),
        ];
    }
}
