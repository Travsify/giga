<x-filament-widgets::widget>
    <x-filament::section>
        <x-slot name="heading">
            <div class="flex items-center space-x-2">
                <span class="relative flex h-3 w-3">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                </span>
                <span>Live Operations Monitor</span>
            </div>
        </x-slot>

        <div class="space-y-4">
            <div 
                id="live-map" 
                class="w-full h-[500px] rounded-2xl overflow-hidden shadow-lg bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 dark:from-slate-950 dark:via-slate-900 dark:to-slate-950 border border-slate-700/50"
                wire:ignore
            >
                <div class="flex items-center justify-center h-full text-slate-400 flex-col space-y-4">
                    <div class="relative">
                        <div class="w-20 h-20 rounded-full border-4 border-primary-500/30 flex items-center justify-center">
                            <x-filament::loading-indicator class="h-10 w-10 text-primary-500" />
                        </div>
                        <div class="absolute -top-1 -right-1 w-6 h-6 bg-green-500 rounded-full flex items-center justify-center animate-pulse">
                            <span class="text-xs font-bold text-white">✓</span>
                        </div>
                    </div>
                    <div class="text-center">
                        <p class="text-lg font-semibold text-white/90">Giga Command Center</p>
                        <p class="text-sm text-slate-500">Initializing Real-Time Fleet Telemetry...</p>
                    </div>
                </div>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                <div class="flex items-center space-x-3 bg-gradient-to-r from-primary-500/10 to-primary-500/5 dark:from-primary-500/20 dark:to-primary-500/10 p-3 rounded-xl border border-primary-500/20">
                    <span class="w-3 h-3 rounded-full bg-primary-500 animate-pulse shadow-lg shadow-primary-500/50"></span>
                    <div>
                        <p class="text-xs font-semibold text-primary-500 uppercase tracking-wider">Riders</p>
                        <p class="text-sm text-slate-400">Active Fleet</p>
                    </div>
                </div>
                <div class="flex items-center space-x-3 bg-gradient-to-r from-amber-500/10 to-amber-500/5 dark:from-amber-500/20 dark:to-amber-500/10 p-3 rounded-xl border border-amber-500/20">
                    <span class="w-3 h-3 rounded-full bg-amber-500"></span>
                    <div>
                        <p class="text-xs font-semibold text-amber-500 uppercase tracking-wider">Pickup</p>
                        <p class="text-sm text-slate-400">Pending</p>
                    </div>
                </div>
                <div class="flex items-center space-x-3 bg-gradient-to-r from-green-500/10 to-green-500/5 dark:from-green-500/20 dark:to-green-500/10 p-3 rounded-xl border border-green-500/20">
                    <span class="w-3 h-3 rounded-full bg-green-500"></span>
                    <div>
                        <p class="text-xs font-semibold text-green-500 uppercase tracking-wider">Dropoff</p>
                        <p class="text-sm text-slate-400">Secure</p>
                    </div>
                </div>
                <div class="flex items-center space-x-3 bg-gradient-to-r from-cyan-500/10 to-cyan-500/5 dark:from-cyan-500/20 dark:to-cyan-500/10 p-3 rounded-xl border border-cyan-500/20">
                    <span class="w-3 h-3 rounded-full bg-cyan-400 animate-ping"></span>
                    <div>
                        <p class="text-xs font-semibold text-cyan-400 uppercase tracking-wider">Telemetry</p>
                        <p class="text-sm text-slate-400">Live Stream</p>
                    </div>
                </div>
            </div>
        </div>
    </x-filament::section>
</x-filament-widgets::widget>
