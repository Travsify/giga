<?php
use Filament\Facades\Filament;

try {
    $panel = Filament::getPanel('admin');
    $resources = $panel->getResources();
    
    echo "REGISTERED RESOURCES:\n";
    foreach ($resources as $resource) {
        echo "- " . $resource . "\n";
    }
    
    echo "\nNAVIGATION GROUPS:\n";
    // Check navigation groups logic
} catch (\Exception $e) {
    echo "ERROR: " . $e->getMessage();
}
