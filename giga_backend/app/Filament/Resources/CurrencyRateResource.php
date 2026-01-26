<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CurrencyRateResource\Pages;
use App\Models\CurrencyRate;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class CurrencyRateResource extends Resource
{
    protected static ?string $model = CurrencyRate::class;

    protected static ?string $navigationIcon = 'heroicon-o-currency-dollar';
    protected static ?string $navigationGroup = 'Operations';
    protected static ?string $navigationLabel = 'Currency Rates';
    protected static ?int $navigationSort = 3;

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('currency_code')
                    ->required()
                    ->length(3)
                    ->unique(ignoreRecord: true)
                    ->label('Currency Code (e.g. NGN)'),
                Forms\Components\TextInput::make('symbol')
                    ->required()
                    ->maxLength(5)
                    ->label('Symbol (e.g. ₦)'),
                Forms\Components\TextInput::make('rate_to_gbp')
                    ->required()
                    ->numeric()
                    ->label('Exchange Rate (1 GBP = X)')
                    ->helperText('How much of this currency is equal to £1 GBP?'),
                Forms\Components\Toggle::make('is_active')
                    ->default(true),
                Forms\Components\Toggle::make('is_base')
                    ->label('Is Base Currency (GBP)')
                    ->disabled() // Should generally not be changed manually easily
                    ->default(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('currency_code')->sortable()->searchable(),
                Tables\Columns\TextColumn::make('symbol'),
                Tables\Columns\TextColumn::make('rate_to_gbp')->label('Rate (1 GBP =)')->sortable(),
                Tables\Columns\IconColumn::make('is_active')->boolean(),
                Tables\Columns\TextColumn::make('updated_at')->dateTime(),
            ])
            ->filters([
                //
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

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCurrencyRates::route('/'),
            'create' => Pages\CreateCurrencyRate::route('/create'),
            'edit' => Pages\EditCurrencyRate::route('/{record}/edit'),
        ];
    }
}
