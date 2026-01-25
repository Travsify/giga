<?php

namespace App\Filament\Resources\LockerResource\Pages;

use App\Filament\Resources\LockerResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListLockers extends ListRecords
{
    protected static string $resource = LockerResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
