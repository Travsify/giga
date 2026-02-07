<?php

namespace App\Filament\Resources;

use App\Filament\Resources\RiderResource\Pages;
use App\Models\Rider;
use Filament\Forms;
use Filament\Forms\Form;
use Filament\Resources\Resource;
use Filament\Tables;
use Filament\Tables\Table;

class RiderResource extends Resource
{
    protected static ?string $model = Rider::class;

    protected static ?string $navigationIcon = 'heroicon-o-user-group';

    protected static ?string $navigationGroup = 'Logistic Hub';

    protected static ?string $navigationLabel = 'Drivers';

    public static function form(Form $form): Form
    {
        return $form
            ->schema([
                Forms\Components\Tabs::make('Rider Details')
                    ->tabs([
                        Forms\Components\Tabs\Tab::make('Basic Information')
                            ->schema([
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\Select::make('user_id')
                                            ->relationship('user', 'name')
                                            ->required()
                                            ->searchable(),
                                        Forms\Components\Select::make('logistics_company_id')
                                            ->relationship('logisticsCompany', 'name')
                                            ->searchable(),
                                        Forms\Components\Select::make('vehicle_type')
                                            ->options([
                                                'bike' => 'Bike',
                                                'van' => 'Van',
                                                'truck' => 'Truck',
                                            ])
                                            ->required(),
                                        Forms\Components\TextInput::make('vehicle_plate_number'),
                                        Forms\Components\TextInput::make('license_number'),
                                    ]),
                                Forms\Components\Section::make('Location & Status')
                                    ->schema([
                                        Forms\Components\Grid::make(2)
                                            ->schema([
                                                Forms\Components\Toggle::make('is_online')
                                                    ->required(),
                                                Forms\Components\Toggle::make('vehicle_verified')
                                                    ->label('Vehicle Verified'),
                                                Forms\Components\TextInput::make('current_lat')
                                                    ->numeric(),
                                                Forms\Components\TextInput::make('current_lng')
                                                    ->numeric(),
                                            ]),
                                    ])->compact(),
                            ]),
                        
                        Forms\Components\Tabs\Tab::make('Verification Documents')
                            ->schema([
                                Forms\Components\Section::make('Automated Verification Result')
                                    ->schema([
                                        Forms\Components\Select::make('verification_status')
                                            ->options([
                                                'pending' => 'Pending',
                                                'submitted' => 'Submitted',
                                                'verified' => 'Verified',
                                                'rejected' => 'Rejected',
                                            ])
                                            ->required()
                                            ->native(false),
                                        Forms\Components\Textarea::make('rejection_reason')
                                            ->columnSpanFull(),
                                        Forms\Components\KeyValue::make('verification_errors')
                                            ->label('System Errors')
                                            ->columnSpanFull(),
                                    ])->columns(1),
                                
                                Forms\Components\Grid::make(2)
                                    ->schema([
                                        Forms\Components\FileUpload::make('driver_license_path')
                                            ->label('Driver License')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/documents'),
                                        Forms\Components\FileUpload::make('vehicle_license_path')
                                            ->label('Vehicle License')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/documents'),
                                        Forms\Components\FileUpload::make('passport_photo_path')
                                            ->label('Passport Photo')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/documents'),
                                        Forms\Components\FileUpload::make('selfie_id_path')
                                            ->label('Verification Selfie')
                                            ->image()
                                            ->previewable(true)
                                            ->downloadable()
                                            ->directory('riders/documents'),
                                        Forms\Components\FileUpload::make('nin_path')
                                            ->label('NIN Slip')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/documents'),
                                        Forms\Components\FileUpload::make('intl_passport_path')
                                            ->label('International Passport')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/documents'),
                                    ]),
                                Forms\Components\Section::make('Vehicle Photos')
                                    ->schema([
                                        Forms\Components\FileUpload::make('vehicle_front_path')
                                            ->label('Vehicle Front')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/vehicles'),
                                        Forms\Components\FileUpload::make('vehicle_side_path')
                                            ->label('Vehicle Side')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/vehicles'),
                                        Forms\Components\FileUpload::make('vehicle_interior_path')
                                            ->label('Vehicle Interior')
                                            ->image()
                                            ->downloadable()
                                            ->directory('riders/vehicles'),
                                    ])->columns(3),
                            ]),
                    ])->columnSpanFull(),
            ]);
    }

    protected static ?string $recordTitleAttribute = 'user.name';

    public static function getGloballySearchableAttributes(): array
    {
        return ['user.name', 'user.email', 'vehicle_plate_number'];
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                Tables\Columns\TextColumn::make('user.name')
                    ->label('Rider Name')
                    ->description(fn (Rider $record): string => $record->user->email ?? '')
                    ->searchable(),
                Tables\Columns\TextColumn::make('verification_status')
                    ->badge()
                    ->color(fn (string $state): string => match ($state) {
                        'verified' => 'success',
                        'submitted' => 'warning',
                        'rejected' => 'danger',
                        default => 'gray',
                    })
                    ->formatStateUsing(fn (string $state): string => ucfirst($state)),
                Tables\Columns\TextColumn::make('vehicle_type')
                    ->icon(fn (string $state): string => match ($state) {
                        'bike' => 'heroicon-m-sparkles',
                        'van' => 'heroicon-m-truck',
                        'truck' => 'heroicon-m-shield-check',
                        default => 'heroicon-m-user',
                    }),
                Tables\Columns\IconColumn::make('is_online')
                    ->label('Online')
                    ->boolean(),
                Tables\Columns\TextColumn::make('logisticsCompany.name')
                    ->label('Company')
                    ->sortable(),
                Tables\Columns\TextColumn::make('created_at')
                    ->dateTime()
                    ->sortable()
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                Tables\Filters\SelectFilter::make('verification_status')
                    ->options([
                        'pending' => 'Pending',
                        'submitted' => 'Submitted',
                        'verified' => 'Verified',
                        'rejected' => 'Rejected',
                    ]),
                Tables\Filters\TernaryFilter::make('is_online'),
            ])
            ->actions([
                Tables\Actions\ActionGroup::make([
                    Tables\Actions\ViewAction::make(),
                    Tables\Actions\EditAction::make(),
                    Tables\Actions\Action::make('verify')
                        ->label('Approve Rider')
                        ->icon('heroicon-m-check-badge')
                        ->color('success')
                        ->action(fn (Rider $record) => $record->update(['verification_status' => 'verified', 'vehicle_verified' => true])),
                    Tables\Actions\Action::make('reject')
                        ->label('Reject Rider')
                        ->icon('heroicon-m-x-circle')
                        ->color('danger')
                        ->form([
                            Forms\Components\Textarea::make('reason')
                                ->required()
                                ->label('Rejection Reason'),
                        ])
                        ->action(fn (Rider $record, array $data) => $record->update([
                            'verification_status' => 'rejected',
                            'rejection_reason' => $data['reason']
                        ])),
                ]),
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
            'index' => Pages\ListRiders::route('/'),
            'create' => Pages\CreateRider::route('/create'),
            'edit' => Pages\EditRider::route('/{record}/edit'),
        ];
    }
}
