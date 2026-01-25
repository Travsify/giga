<?php

use Illuminate\Support\Facades\Route;

Route::get('/debug-filament', function () {
    $panel = \Filament\Facades\Filament::getPanel('admin');
    return [
        'resources' => array_keys($panel->getResources()),
        'navigation' => array_map(fn($item) => $item->getLabel(), $panel->getNavigation()),
    ];
});

Route::get('/', function () {
    return view('welcome');
});
