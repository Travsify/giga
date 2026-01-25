<x-filament-widgets::widget>
    <x-filament::section>
        <x-slot name="heading">
            Live Delivery Operations (God Mode)
        </x-slot>

        <div class="space-y-4">
            <div 
                id="live-map" 
                class="w-full h-[500px] rounded-xl overflow-hidden shadow-inner bg-slate-100"
                wire:ignore
            >
                <div class="flex items-center justify-center h-full text-slate-400 flex-col space-y-2">
                    <x-filament::loading-indicator class="h-8 w-8" />
                    <p class="text-sm font-medium">Initializing Advanced Satellite Monitoring...</p>
                </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-4 gap-4 text-xs font-mono uppercase tracking-wider text-slate-500">
                <div class="flex items-center space-x-2 bg-slate-50 p-2 rounded-lg border border-slate-100">
                    <span class="w-3 h-3 rounded-full bg-blue-500 animate-pulse"></span>
                    <span>Rider: Active</span>
                </div>
                <div class="flex items-center space-x-2 bg-slate-50 p-2 rounded-lg border border-slate-100">
                    <span class="w-3 h-3 rounded-full bg-orange-500"></span>
                    <span>Pickup: Pending</span>
                </div>
                <div class="flex items-center space-x-2 bg-slate-50 p-2 rounded-lg border border-slate-100">
                    <span class="w-3 h-3 rounded-full bg-green-500"></span>
                    <span>Dropoff: Secure</span>
                </div>
                <div class="flex items-center space-x-2 bg-slate-50 p-2 rounded-lg border border-slate-100">
                    <span class="w-3 h-3 rounded-full bg-cyan-400 animate-ping"></span>
                    <span>Telemetry: Live</span>
                </div>
            </div>
        </div>

        <script>
            // This is a placeholder for Google Maps integration in the admin panel
            // In a real implementation, you'd initialize the Google Maps JS SDK here
            // and fetch live locations from Firestore or your API.
            console.log('God Mode Live Map Initialized');
        </script>
    </x-filament::section>
</x-filament-widgets::widget>
