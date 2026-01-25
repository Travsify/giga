<?php

namespace App\Filament\Resources;

use App\Filament\Resources\CountryResource\Pages;
use App\Filament\Resources\CountryResource\RelationManagers;
use App\Models\Country;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class CountryResource extends Resource
{
    protected static ?string $model = Country::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('iso_code')
                    ->required()
                    ->length(2)
                    ->label('ISO Code (2 chars)')
                    ->helperText('e.g. GB, NG'),
                Forms\Components\TextInput::make('currency_code')
                    ->required()
                    ->length(3)
                    ->label('Currency Code')
                    ->helperText('e.g. GBP, NGN'),
                Forms\Components\TextInput::make('currency_symbol')
                    ->required()
                    ->label('Currency Symbol')
                    ->helperText('e.g. £, ₦'),
                Forms\Components\TextInput::make('phone_code')
                    ->required()
                    ->label('Phone Dial Code')
                    ->helperText('e.g. +44'),
                Forms\Components\CheckboxList::make('payment_gateways')
                    ->options([
                        'stripe' => 'Stripe',
                        'paystack' => 'Paystack',
                        'flutterwave' => 'Flutterwave',
                        'paypal' => 'PayPal',
                    ])
                    ->columns(2),
                Forms\Components\CheckboxList::make('features')
                    ->options([
                        'instant_delivery' => 'Instant Delivery',
                        'scheduled_delivery' => 'Scheduled Delivery',
                        'wallet' => 'In-App Wallet',
                        'cod' => 'Cash on Delivery',
                        'ulez' => 'ULEZ/Congestion Zone Logic',
                    ])
                    ->columns(2),
                Forms\Components\Toggle::make('is_active')
                    ->default(true),
                Forms\Components\Toggle::make('is_default')
                    ->default(false),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')->searchable()->sortable(),
                Tables\Columns\TextColumn::make('iso_code')->searchable()->label('ISO'),
                Tables\Columns\TextColumn::make('currency_code')->label('Currency'),
                Tables\Columns\IconColumn::make('is_active')->boolean(),
                Tables\Columns\IconColumn::make('is_default')->boolean()->label('Default'),
                Tables\Columns\TextColumn::make('payment_gateways')->badge()->separator(','),
                Tables\Columns\TextColumn::make('features')->badge()->separator(','),
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

    public static function getRelations(): array
    {
        return [
            //
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListCountries::route('/'),
            'create' => Pages\CreateCountry::route('/create'),
            'edit' => Pages\EditCountry::route('/{record}/edit'),
        ];
    }
}
