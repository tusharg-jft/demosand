import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import GOOGLE_MAPS from '@salesforce/resourceUrl/GoogleMaps'; // Maps to the static resource

export default class Googlemap extends LightningElement {
    mapInitialized = false;

    async renderedCallback() {
        if (this.mapInitialized) {
            return;
        }
        this.mapInitialized = true;

        try {
            console.log('Attempting to load Google Maps script from:', GOOGLE_MAPS);
            await loadScript(this, GOOGLE_MAPS);
            console.log('Google Maps script loaded successfully');
            if (window.google) {
                console.log('Google object is defined');
                this.initMap();
            } else {
                console.error('Google object is not defined after script load');
            }
        } catch (error) {
            console.error('Error loading Google Maps script:', error);
            console.error('Error details:', JSON.stringify(error, null, 2));
        }
    }

    initMap() {
        try {
            const mapContainer = this.template.querySelector('.map-container');
            if (mapContainer) {
                console.log('Initializing map...');
                const mapOptions = {
                    center: { lat: 37.7749, lng: -122.4194 }, // San Francisco
                    zoom: 12
                };
                const map = new google.maps.Map(mapContainer, mapOptions);
                console.log('Map initialized successfully');
            } else {
                console.error('Map container not found');
            }
        } catch (error) {
            console.error('Error initializing map:', error);
        }
    }
}