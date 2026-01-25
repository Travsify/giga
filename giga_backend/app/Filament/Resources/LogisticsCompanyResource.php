<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LogisticsCompanyResource\Pages;
use App\Models\LogisticsCompany;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class LogisticsCompanyResource extends Resource
{
    protected static ?string $model = LogisticsCompany::class;

    protected static ?string $navigationIcon = 'heroicon-o-building-office-2';

    protected static ?string $navigationGroup = 'Business Management';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::class, 'user_id')
                    ->relationship('owner', 'name')
                    ->required()
                    ->searchable(),
                Forms\Components\TextInput::class, 'name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::class, 'company_type')
                    ->required(),
                Forms\Components\TextInput::class, 'registration_number')
                    ->unique(ignoreRecord: true)
                    ->required(),
                Forms\Components\TextInput::class, 'vat_number'),
                Forms\Components\TextInput::class, 'business_email')
                    ->email()
                    ->required(),
                Forms\Components\TextInput::class, 'contact_phone')
                    ->tel()
                    ->required(),
                Forms\Components\Textarea::class, 'address')
                    ->required(),
                Forms\Components\TextInput::class, 'website')
                    ->url(),
                Forms\Components\Toggle::class, 'is_verified')
                    ->label('Verified Business')
                    ->required(),
                Forms\Components\TextInput::class, 'credit_limit')
                    ->numeric()
                    ->prefix('£')
                    ->default(500),
                Forms\Components\TextInput::class, 'outstanding_balance')
                    ->numeric()
                    ->prefix('£')
                    ->default(0),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::class, 'name')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'owner.name')
                    ->label('Owner')
                    ->searchable(),
                Tables\Columns\IconColumn::class, 'is_verified')
                    ->boolean()
                    ->label('Verified'),
                Tables\Columns\TextColumn::class, 'registration_number')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'credit_limit')
                    ->money('GBP'),
                Tables\Columns\TextColumn::class, 'created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
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
            'index' => Pages\ListLogisticsCompanies::route('/'),
            'create' => Pages\CreateLogisticsCompany::route('/create'),
            'edit' => Pages\EditLogisticsCompany::route('/{record}/edit'),
        ];
    }
}
