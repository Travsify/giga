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
                class="w-full h-[300px] rounded-2xl overflow-hidden bg-gradient-to-br from-slate-900 to-black relative border border-cyan-500/20"
                wire:ignore
            >
                {{-- Modern Grid Map Background --}}
                <div class="absolute inset-0 opacity-20" style="background-image: radial-gradient(#00F2FF 1px, transparent 1px); background-size: 20px 20px;"></div>

                {{-- Driver Markers (Simplified & Animated) --}}
                <div class="absolute top-[35%] left-[25%] transform -translate-x-1/2 -translate-y-1/2">
                    <div class="w-12 h-12 rounded-full bg-cyan-500 flex items-center justify-center text-black font-black text-xs shadow-[0_0_20px_rgba(0,242,255,0.6)] animate-pulse">
                        {{ $this->getActiveRiderCount() }}
                    </div>
                </div>
                <div class="absolute top-[55%] left-[65%] transform -translate-x-1/2 -translate-y-1/2">
                    <div class="w-14 h-14 rounded-full bg-red-500 flex items-center justify-center text-white font-black text-sm shadow-[0_0_25px_rgba(255,0,85,0.6)]">
                         {{ $this->getInTransitDeliveries() }}
                    </div>
                </div>
                <div class="absolute top-[20%] left-[80%] transform -translate-x-1/2 -translate-y-1/2">
                    <div class="w-10 h-10 rounded-full bg-green-500 flex items-center justify-center text-white font-black text-xs shadow-[0_0_15px_rgba(0,255,133,0.6)]">
                        {{ $this->getTodayDelivered() }}
                    </div>
                </div>
            </div>

            {{-- Modern Legend --}}
            <div class="grid grid-cols-3 gap-3 text-[10px] font-bold uppercase tracking-wider">
                <div class="flex flex-col items-center p-2 rounded-xl bg-slate-800/50 border border-cyan-500/20">
                    <span class="text-cyan-400 mb-1">Active Riders</span>
                    <span class="text-white text-lg">{{ $this->getActiveRiderCount() }}</span>
                </div>
                <div class="flex flex-col items-center p-2 rounded-xl bg-slate-800/50 border border-red-500/20">
                    <span class="text-red-400 mb-1">In Transit</span>
                    <span class="text-white text-lg">{{ $this->getInTransitDeliveries() }}</span>
                </div>
                <div class="flex flex-col items-center p-2 rounded-xl bg-slate-800/50 border border-green-500/20">
                    <span class="text-green-400 mb-1">Delivered</span>
                    <span class="text-white text-lg">{{ $this->getTodayDelivered() }}</span>
                </div>
            </div>
        </div>
    </x-filament::section>
</x-filament-widgets::widget>
