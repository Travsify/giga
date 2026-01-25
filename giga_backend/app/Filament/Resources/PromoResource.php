<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PromoResource\Pages;
use App\Models\Promo;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class PromoResource extends Resource
{
    protected static ?string $model = Promo::class;

    protected static ?string $navigationIcon = 'heroicon-o-ticket';

    protected static ?string $navigationGroup = 'Marketing';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::class, 'code')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->maxLength(255),
                Forms\Components\Select::class, 'discount_type')
                    ->options([
                        'percentage' => 'Percentage',
                        'fixed' => 'Fixed Amount',
                    ])
                    ->required(),
                Forms\Components\TextInput::class, 'discount_value')
                    ->numeric()
                    ->required(),
                Forms\Components\TextInput::class, 'max_uses')
                    ->numeric(),
                Forms\Components\DateTimePicker::class, 'expires_at'),
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
                Tables\Columns\TextColumn::class, 'discount_type')
                    ->badge(),
                Tables\Columns\TextColumn::class, 'discount_value'),
                Tables\Columns\TextColumn::class, 'uses_count')
                    ->label('Uses'),
                Tables\Columns\TextColumn::class, 'max_uses')
                    ->placeholder('Unlimited'),
                Tables\Columns\TextColumn::class, 'expires_at')
                    ->dateTime()
                    ->sortable(),
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
            'index' => Pages\ListPromos::route('/'),
            'create' => Pages\CreatePromo::route('/create'),
            'edit' => Pages\EditPromo::route('/{record}/edit'),
        ];
    }
}
