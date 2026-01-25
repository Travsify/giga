<?php

namespace App\Filament\Resources;

use App\Filament\Resources\WalletResource\Pages;
use App\Models\Wallet;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class WalletResource extends Resource
{
    protected static ?string $model = Wallet::class;

    protected static ?string $navigationIcon = 'heroicon-o-credit-card';

    protected static ?string $navigationGroup = 'Financial Management';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::class, 'user_id')
                    ->relationship('user', 'name')
                    ->required()
                    ->searchable(),
                Forms\Components\TextInput::class, 'balance')
                    ->numeric()
                    ->prefix('£')
                    ->required(),
                Forms\Components\TextInput::class, 'currency')
                    ->default('GBP')
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::class, 'user.name')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'balance')
                    ->money(fn ($record) => $record->currency)
                    ->sortable(),
                Tables\Columns\TextColumn::class, 'currency')
                    ->sortable(),
                Tables\Columns\TextColumn::class, 'updated_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                //
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
            'index' => Pages\ListWallets::route('/'),
            'create' => Pages\CreateWallet::route('/create'),
            'edit' => Pages\EditWallet::route('/{record}/edit'),
        ];
    }
}
