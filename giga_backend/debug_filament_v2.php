<?php
use App\Models\User;
use Filament\Facades\Filament;
use Illuminate\Support\Facades\Auth;

try {
    $panel = Filament::getPanel('admin');
    $resources = $panel->getResources();
    
    // Mock an admin user to test visibility
    $admin = User::where('role', 'SuperAdmin')->first();
    if ($admin) {
        Auth::login($admin);
        echo "Logged in as: " . $admin->email . "\n";
    } else {
        echo "WARNING: No SuperAdmin user found.\n";
    }

    echo "--- RESOURCE LIST ---\n";
    foreach ($resources as $resource) {
        try {
            $group = $resource::getNavigationGroup();
            $label = $resource::getNavigationLabel();
            $visible = $resource::canViewAny() ? 'YES' : 'NO';
            echo sprintf("[%s]\n  Group: %s\n  Label: %s\n  Visible: %s\n", $resource, $group, $label, $visible);
        } catch (\Exception $e) {
            echo "Error loading $resource: " . $e->getMessage() . "\n";
        }
    }
} catch (\Exception $e) {
    echo "GENERAL ERROR: " . $e->getMessage() . "\n";
}
