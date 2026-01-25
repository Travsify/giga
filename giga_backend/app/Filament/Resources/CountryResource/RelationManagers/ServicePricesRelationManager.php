<?php

namespace App\Filament\Resources\CountryResource\RelationManagers;

use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class ServicePricesRelationManager extends RelationManager
{
    protected static string $relationship = 'servicePrices';

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::make('service_id')
                    ->relationship('service', 'name')
                    ->searchable()
                    ->preload()
                    ->required(),
                Forms\Components\TextInput::make('base_price')
                    ->required()
                    ->numeric()
                    ->prefix('Base'),
                Forms\Components\TextInput::make('price_per_km')
                    ->required()
                    ->numeric()
                    ->prefix('/ KM'),
                Forms\Components\TextInput::make('price_per_min')
                    ->required()
                    ->numeric()
                    ->prefix('/ Min'),
                Forms\Components\TextInput::make('minimum_fare')
                    ->required()
                    ->numeric()
                    ->default(0),
                Forms\Components\TextInput::make('commission_percentage')
                    ->required()
                    ->numeric()
                    ->suffix('%')
                    ->maxValue(100)
                    ->default(15),
                Forms\Components\Toggle::make('is_active')
                    ->default(true),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('base_price')
            ->columns([
                Tables\Columns\TextColumn::make('service.name')
                    ->label('Service')
                    ->sortable()
                    ->searchable(),
                Tables\Columns\TextColumn::make('base_price')
                    ->money(fn ($livewire) => $livewire->getOwnerRecord()->currency_code ?? 'USD')
                    ->sortable(),
                Tables\Columns\TextColumn::make('price_per_km')
                    ->numeric()
                    ->sortable(),
                Tables\Columns\TextColumn::make('commission_percentage')
                    ->suffix('%'),
                Tables\Columns\ToggleColumn::make('is_active'),
            ])
            ->filters([
                //
            ])
            ->headerActions([
                Tables\Actions\CreateAction::make(),
            ])
            ->actions([
                Tables\Actions\EditAction::make(),
                Tables\Actions\DeleteAction::make(),
            ])
            ->bulkActions([
                Tables\Actions\BulkActionGroup::make([
                    Tables\Actions\DeleteBulkAction::make(),
                ]),
            ]);
    }
}
