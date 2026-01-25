<?php

namespace App\Filament\Resources\LogisticsCompanyResource\Pages;

use App\Filament\Resources\LogisticsCompanyResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListLogisticsCompanies extends ListRecords
{
    protected static string $resource = LogisticsCompanyResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
