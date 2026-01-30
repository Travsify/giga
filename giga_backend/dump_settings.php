<?php
require 'vendor/autoload.php';
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

$settings = App\Models\AppSetting::where('group', 'email')->get();
foreach ($settings as $s) {
    echo $s->key . ': ' . $s->value . PHP_EOL;
}
