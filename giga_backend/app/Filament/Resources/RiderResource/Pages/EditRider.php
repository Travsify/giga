<?php

namespace App\Filament\Resources\RiderResource\Pages;

use App\Filament\Resources\RiderResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditRider extends EditRecord
{
    protected static string $resource = RiderResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\Action::make('approve')
                ->label('Approve Driver')
                ->icon('heroicon-o-check-badge')
                ->color('success')
                ->action(function () {
                    $this->record->update([
                        'verification_status' => 'verified',
                        'vehicle_verified' => true,
                    ]);
                    \Filament\Notifications\Notification::make()
                        ->success()
                        ->title('Driver Approved')
                        ->body('The driver has been manually verified.')
                        ->send();
                })
                ->visible(fn () => $this->record->verification_status !== 'verified'),

            Actions\Action::make('reject')
                ->label('Reject Driver')
                ->icon('heroicon-o-x-circle')
                ->color('danger')
                ->form([
                    \Filament\Forms\Components\Textarea::make('reason')
                        ->required()
                        ->label('Rejection Reason'),
                ])
                ->action(function (array $data) {
                    $this->record->update([
                        'verification_status' => 'rejected',
                        'rejection_reason' => $data['reason']
                    ]);
                    \Filament\Notifications\Notification::make()
                        ->warning()
                        ->title('Driver Rejected')
                        ->body('The driver has been rejected.')
                        ->send();
                })
                ->visible(fn () => $this->record->verification_status !== 'verified'),

            Actions\DeleteAction::make(),
        ];
    }
}
