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
            {{-- Map Container --}}
            <div 
                wire:ignore
                x-data="{
                    map: null,
                    markers: [],
                    locations: @js($this->getDriverLocations()),
                    initMap() {
                        if (!document.getElementById('google-maps-script')) {
                            const script = document.createElement('script');
                            script.id = 'google-maps-script';
                            script.src = 'https://maps.googleapis.com/maps/api/js?key=AIzaSyDVqP4CjWp_fcFim7d_E0kAL35Ie2gWMzE&callback=initGoogleMap';
                            script.async = true;
                            script.defer = true;
                            document.head.appendChild(script);
                            
                            window.initGoogleMap = () => {
                                this.renderMap();
                            };
                        } else if (window.google && window.google.maps) {
                            this.renderMap();
                        }
                    },
                    renderMap() {
                        const mapDiv = document.getElementById('driver-map');
                        if (!mapDiv) return;

                        this.map = new google.maps.Map(mapDiv, {
                            center: { lat: 9.0820, lng: 8.6753 }, // Nigeria Center
                            zoom: 6,
                            disableDefaultUI: true, // Clean look
                            styles: [
                                { featureType: 'poi', elementType: 'labels', stylers: [{ visibility: 'off' }] }
                            ]
                        });

                        this.updateMarkers();
                    },
                    updateMarkers() {
                        // Clear existing
                        this.markers.forEach(m => m.setMap(null));
                        this.markers = [];

                        this.locations.forEach(loc => {
                            const marker = new google.maps.Marker({
                                position: { lat: parseFloat(loc.lat), lng: parseFloat(loc.lng) },
                                map: this.map,
                                title: loc.name,
                                icon: {
                                    url: 'https://cdn-icons-png.flaticon.com/512/3063/3063822.png', // Truck icon or similar
                                    scaledSize: new google.maps.Size(32, 32)
                                }
                            });
                            
                            const infoWindow = new google.maps.InfoWindow({
                                content: `<div style='color:black;'><strong>${loc.name}</strong><br>${loc.status}</div>`
                            });

                            marker.addListener('click', () => {
                                infoWindow.open(this.map, marker);
                            });

                            this.markers.push(marker);
                        });
                    }
                }"
                x-init="initMap(); $watch('locations', value => updateMarkers())"
                id="driver-map" 
                class="w-full h-[350px] rounded-xl overflow-hidden bg-gray-100 relative"
            >
                <div class="absolute inset-0 flex items-center justify-center bg-gray-100" x-show="!map">
                    <span class="animate-pulse text-gray-400">Loading Map...</span>
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
