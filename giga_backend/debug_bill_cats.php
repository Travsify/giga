<?php
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$service = app(App\Services\FlutterwaveBillService::class);
$cats = $service->getBillCategories();

echo "Total Categories: " . count($cats) . "\n\n";

foreach(array_slice($cats, 0, 50) as $c) {
    echo "ID: " . ($c['id'] ?? 'N/A') . " | ";
    echo "Name: " . ($c['name'] ?? 'N/A') . " | ";
    echo "Biller: " . ($c['biller_code'] ?? 'N/A') . " | ";
    echo "Item: " . ($c['item_code'] ?? 'N/A') . " | ";
    echo "Category: " . ($c['category'] ?? 'N/A') . "\n";
}
