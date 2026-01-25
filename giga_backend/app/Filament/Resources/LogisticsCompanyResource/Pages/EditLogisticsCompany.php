<?php

namespace App\Filament\Resources\LogisticsCompanyResource\Pages;

use App\Filament\Resources\LogisticsCompanyResource;
use Filament\Actions;
use Filament\Resources\Pages\EditRecord;

class EditLogisticsCompany extends EditRecord
{
    protected static string $resource = LogisticsCompanyResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\DeleteAction::make(),
        ];
    }
}
