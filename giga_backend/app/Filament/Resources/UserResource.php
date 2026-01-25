<?php

namespace App\Filament\Resources;

use App\Filament\Resources\UserResource\Pages;
use App\Models\User;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;
use Illuminate\Support\Facades\Hash;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static ?string $navigationIcon = 'heroicon-o-users';

    protected static ?string $navigationGroup = 'User Management';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\TextInput::class, 'name')
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::class, 'email')
                    ->email()
                    ->required()
                    ->maxLength(255),
                Forms\Components\TextInput::class, 'uk_phone')
                    ->tel()
                    ->maxLength(255),
                Forms\Components\Select::class, 'role')
                    ->options([
                        'Customer' => 'Customer',
                        'Rider' => 'Rider',
                        'Company' => 'Company',
                        'Business' => 'Business',
                        'SuperAdmin' => 'Super Admin',
                    ])
                    ->required(),
                Forms\Components\Toggle::class, 'is_giga_plus')
                    ->label('Giga Plus Member'),
                Forms\Components\DateTimePicker::class, 'giga_plus_expiry'),
                Forms\Components\TextInput::class, 'password')
                    ->password()
                    ->dehydrateStateUsing(fn ($state) => Hash::make($state))
                    ->dehydrated(fn ($state) => filled($state))
                    ->required(fn (string $context): bool => $context === 'create'),
                Forms\Components\Select::class, 'business_id')
                    ->relationship('business', 'name')
                    ->searchable(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::class, 'name')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'email')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'role')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'SuperAdmin' => 'danger',
                        'Business' => 'warning',
                        'Rider' => 'success',
                        default => 'gray',
                    }),
                Tables\Columns\IconColumn::class, 'is_giga_plus')
                    ->boolean()
                    ->label('Giga+'),
                Tables\Columns\TextColumn::class, 'uk_phone')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::class, 'role'),
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
            'index' => Pages\ListUsers::route('/'),
            'create' => Pages\CreateUser::route('/create'),
            'edit' => Pages\EditUser::route('/{record}/edit'),
        ];
    }
}
