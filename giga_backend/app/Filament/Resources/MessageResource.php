<?php

namespace App\Filament\Resources;

use App\Filament\Resources\MessageResource\Pages;
use App\Models\Message;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class MessageResource extends Resource
{
    protected static ?string $model = Message::class;

    protected static ?string $navigationIcon = 'heroicon-o-chat-bubble-left-right';

    protected static ?string $navigationGroup = 'Operations';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Select::class, 'delivery_id')
                    ->relationship('delivery', 'id')
                    ->required()
                    ->searchable(),
                Forms\Components\Select::class, 'sender_id')
                    ->relationship('sender', 'name')
                    ->required()
                    ->searchable(),
                Forms\Components\Textarea::class, 'content')
                    ->required()
                    ->columnSpanFull(),
                Forms\Components\Toggle::class, 'is_read')
                    ->required(),
            ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::class, 'delivery.id')
                    ->label('Delivery ID')
                    ->sortable(),
                Tables\Columns\TextColumn::class, 'sender.name')
                    ->searchable(),
                Tables\Columns\TextColumn::class, 'content')
                    ->limit(50),
                Tables\Columns\IconColumn::class, 'is_read')
                    ->boolean(),
                Tables\Columns\TextColumn::class, 'created_at')
                    ->dateTime()
                    ->sortable(),
            ])
            ->filters([
                //
            ])
            ->actions([
                Tables\Actions\EditAction::class,
                Tables\Actions\DeleteAction::class,
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
            'index' => Pages\ListMessages::route('/'),
            'create' => Pages\CreateMessage::route('/create'),
            'edit' => Pages\EditMessage::route('/{record}/edit'),
        ];
    }
}
