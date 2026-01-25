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
                Forms\Components\Select::make('user_id')
                    ->relationship('owner', 'name')
                    ->required()
                    ->searchable(),
                Forms\Components\TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::make('company_type')
                    ->required(),
                Forms\Components\TextInput::make('registration_number')
                    ->unique(ignoreRecord: true)
                    ->required(),
                Forms\Components\TextInput::make('vat_number'),
                Forms\Components\TextInput::make('business_email')
                    ->email()
                    ->required(),
                Forms\Components\TextInput::make('contact_phone')
                    ->tel()
                    ->required(),
                Forms\Components\Textarea::make('address')
                    ->required(),
                Forms\Components\TextInput::make('website')
                    ->url(),
                Forms\Components\Toggle::make('is_verified')
                    ->label('Verified Business')
                    ->required(),
                Forms\Components\TextInput::make('credit_limit')
                    ->numeric()
                    ->prefix('£')
                    ->default(500),
                Forms\Components\TextInput::make('outstanding_balance')
                    ->numeric()
                    ->prefix('£')
                    ->default(0),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('name')
                    ->searchable(),
                Tables\Columns\TextColumn::make('owner.name')
                    ->label('Owner')
                    ->searchable(),
                Tables\Columns\IconColumn::make('is_verified')
                    ->boolean()
                    ->label('Verified'),
                Tables\Columns\TextColumn::make('registration_number')
                    ->searchable(),
                Tables\Columns\TextColumn::make('credit_limit')
                    ->money('GBP'),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\TernaryFilter::make('is_verified'),
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
            'index' => Pages\ListLogisticsCompanies::route('/'),
            'create' => Pages\CreateLogisticsCompany::route('/create'),
            'edit' => Pages\EditLogisticsCompany::route('/{record}/edit'),
        ];
    }
}
