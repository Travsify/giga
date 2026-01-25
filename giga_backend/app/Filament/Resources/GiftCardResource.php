<?php

namespace App\Filament\Resources;

use App\Filament\Resources\GiftCardResource\Pages;
use App\Filament\Resources\GiftCardResource\RelationManagers;
use App\Models\GiftCard;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\SoftDeletingScope;

class GiftCardResource extends Resource
{
    protected static ?string $model = GiftCard::class;

    protected static ?string $navigationIcon = 'heroicon-o-rectangle-stack';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::make('code')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->default(fn () => 'GIGA-' . strtoupper(\Illuminate\Support\Str::random(8))),
                Forms\Components\TextInput::make('amount')
                    ->numeric()
                    ->required()
                    ->prefix('Value'),
                Forms\Components\Select::make('currency_code')
                    ->options([
                        'GBP' => 'GBP',
                        'NGN' => 'NGN',
                        'GHS' => 'GHS',
                        'USD' => 'USD',
                    ])
                    ->required(),
                Forms\Components\TextInput::make('max_uses')
                    ->numeric()
                    ->default(1)
                    ->required(),
                Forms\Components\DateTimePicker::make('expires_at'),
                Forms\Components\Toggle::make('is_active')
                    ->default(true)
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('code')->searchable()->copyable(),
                Tables\Columns\TextColumn::make('amount')->money(fn ($record) => $record->currency_code),
                Tables\Columns\TextColumn::make('currency_code')->sortable(),
                Tables\Columns\TextColumn::make('current_uses')->label('Used')
                    ->formatStateUsing(fn ($record) => "{$record->current_uses} / {$record->max_uses}"),
                Tables\Columns\IconColumn::make('is_active')->boolean(),
                Tables\Columns\TextColumn::make('expires_at')->dateTime()->sortable(),
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
            'index' => Pages\ListGiftCards::route('/'),
            'create' => Pages\CreateGiftCard::route('/create'),
            'edit' => Pages\EditGiftCard::route('/{record}/edit'),
        ];
    }
}
