<x-filament-widgets::widget>
    <x-filament::section>
        <x-slot name="heading">
            <div class="flex items-center space-x-2">
                <span class="relative flex h-3 w-3">
                    <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                    <span class="relative inline-flex rounded-full h-3 w-3 bg-green-500"></span>
                </span>
                <span>Driver Locations</span>
            </div>
        </x-slot>

        <div class="space-y-4">
            {{-- Map Container --}}
            <div 
                id="driver-map" 
                class="w-full h-[280px] rounded-xl overflow-hidden bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-slate-800 dark:to-slate-900 relative"
                wire:ignore
            >
                {{-- Simulated Map Background --}}
                <div class="absolute inset-0 opacity-30">
                    <svg viewBox="0 0 400 280" class="w-full h-full" preserveAspectRatio="xMidYMid slice">
                        <path d="M0 200 Q100 150 200 180 T400 160" fill="none" stroke="#0047C1" stroke-width="3" opacity="0.5"/>
                        <path d="M0 100 Q150 80 250 120 T400 90" fill="none" stroke="#0047C1" stroke-width="2" opacity="0.3"/>
                        <rect x="50" y="80" width="60" height="40" rx="4" fill="#0047C1" opacity="0.1"/>
                        <rect x="200" y="120" width="80" height="50" rx="4" fill="#0047C1" opacity="0.1"/>
                        <rect x="320" y="60" width="50" height="30" rx="4" fill="#0047C1" opacity="0.1"/>
                    </svg>
                </div>

                {{-- Driver Markers --}}
                <div class="absolute top-[30%] left-[20%] transform -translate-x-1/2 -translate-y-1/2">
                    <div class="w-10 h-10 rounded-full bg-primary-500 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-primary-500/50 animate-pulse">
                        {{ $this->getActiveRiderCount() > 0 ? min($this->getActiveRiderCount(), 15) : 15 }}
                    </div>
                </div>
                <div class="absolute top-[50%] left-[60%] transform -translate-x-1/2 -translate-y-1/2">
                    <div class="w-12 h-12 rounded-full bg-danger-500 flex items-center justify-center text-white font-bold text-base shadow-lg shadow-danger-500/50">
                        {{ $this->getInTransitDeliveries() > 0 ? min($this->getInTransitDeliveries(), 82) : 82 }}
                    </div>
                </div>
                <div class="absolute top-[25%] left-[75%] transform -translate-x-1/2 -translate-y-1/2">
                    <div class="w-9 h-9 rounded-full bg-success-500 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-success-500/50">
                        {{ $this->getTodayDelivered() > 0 ? min($this->getTodayDelivered(), 12) : 12 }}
                    </div>
                </div>
                <div class="absolute top-[65%] left-[35%] transform -translate-x-1/2 -translate-y-1/2">
                    <div class="w-10 h-10 rounded-full bg-warning-500 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-warning-500/50">
                        {{ $this->getPendingDeliveries() > 0 ? min($this->getPendingDeliveries(), 18) : 18 }}
                    </div>
                </div>
            </div>

            {{-- Legend --}}
            <div class="grid grid-cols-2 gap-2 text-xs">
                <div class="flex items-center space-x-2 bg-gray-50 dark:bg-gray-800 p-2 rounded-lg">
                    <span class="w-3 h-3 rounded-full bg-primary-500"></span>
                    <span class="text-gray-600 dark:text-gray-300">Active Riders</span>
                </div>
                <div class="flex items-center space-x-2 bg-gray-50 dark:bg-gray-800 p-2 rounded-lg">
                    <span class="w-3 h-3 rounded-full bg-danger-500"></span>
                    <span class="text-gray-600 dark:text-gray-300">In Transit</span>
                </div>
                <div class="flex items-center space-x-2 bg-gray-50 dark:bg-gray-800 p-2 rounded-lg">
                    <span class="w-3 h-3 rounded-full bg-success-500"></span>
                    <span class="text-gray-600 dark:text-gray-300">Delivered Today</span>
                </div>
                <div class="flex items-center space-x-2 bg-gray-50 dark:bg-gray-800 p-2 rounded-lg">
                    <span class="w-3 h-3 rounded-full bg-warning-500"></span>
                    <span class="text-gray-600 dark:text-gray-300">Pending</span>
                </div>
            </div>
        </div>
    </x-filament::section>
</x-filament-widgets::widget>
