import { LightningElement, api, wire, track } from 'lwc';
import getTripsForWorkOrder from '@salesforce/apex/TripController.getTripsForWorkOrder';
import { NavigationMixin } from 'lightning/navigation';

export default class childWrokorderTriplist extends NavigationMixin(LightningElement) {
    @api recordId; 
    // @api workOrderId; // The Work Order Id passed to the component
    @track trips = [];
    @track filteredList = [];
    @track selectedVendor = '';
    @track vendorOptions = [];
    showModal = false;

    // Columns for the datatable
    columns = [
        {
            label: 'Trip Name',
            fieldName: 'tripUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_self'
            }
        },
        { label: 'Vendor', fieldName: 'VendorName', type: 'text' },
        { label: 'Status', fieldName: 'Status__c' },
        {
            label: 'ETA',
            fieldName: 'Date_Time_ETA__c',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            }
        },
        {
            label: 'Check-In',
            fieldName: 'CheckInTime__c',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            }
        },
        {
            label: 'Check-Out',
            fieldName: 'CheckOutTime__c',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            }
        }
    ];

    // Wire the trips for a given Work Order ID
    @wire(getTripsForWorkOrder, { workOrderId: '$recordId' })
    wiredTrips({ error, data }) {
        if (data) {
            console.log("hello moto" , data)
            this.trips = data.map(t => ({
                ...t,
                VendorName: t.Vendor__r?.Name || '',
                tripUrl: `/lightning/r/Trip__c/${t.Id}/view`, // URL for Trip record
                // Generate workOrderUrl only if you want it
            }));
            this.filteredList = this.trips;
            this.generateVendorOptions(this.trips);
        } else if (error) {
            console.error('Error fetching trips:', error);
        }
    }

    // Generate vendor options for the filter
    generateVendorOptions(data) {
        const vendorSet = new Set();
        data.forEach(t => {
            if (t.Vendor__r && t.Vendor__r.Name) {
                vendorSet.add(t.Vendor__r.Name);
            }
        });

        this.vendorOptions = [
            { label: 'All', value: '' },
            ...Array.from(vendorSet).map(name => ({ label: name, value: name }))
        ];
    }

    // Handle vendor filter change
    handleVendorChange(event) {
        this.selectedVendor = event.detail.value;
        this.filteredList = this.selectedVendor
            ? this.trips.filter(trip => trip.VendorName === this.selectedVendor)
            : this.trips;
    }

    // Navigate to the Trip record page
    handleTripNavigation(event) {
        const tripId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: tripId,
                objectApiName: 'Trip__c',
                actionName: 'view'
            }
        });
    }
}