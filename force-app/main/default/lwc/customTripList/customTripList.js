import { LightningElement, api, wire, track } from 'lwc';
import getTripsForParentWorkOrder from '@salesforce/apex/TripController.getTripsForParentWorkOrder';

export default class TripList extends LightningElement {
    @api recordId; // This is the Parent WorkOrder Id passed to the component
    @track trips = [];
    @track filteredList = [];
    @track selectedVendor = '';
    @track vendorOptions = [];
    showModal = false;
    selectedTrip = {};
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
        {
            label: 'Work Order',
            fieldName: 'workOrderUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'WorkOrderName' },
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
    

    @wire(getTripsForParentWorkOrder, { parentWOId: '$recordId' })
    wiredTrips({ error, data }) {
        if (data) {
            this.trips = data.map(t => ({
                ...t,
                VendorName: t.Vendor__r?.Name || '',
                WorkOrderName: t.Work_Orders__r?.Name || '',
                tripUrl: `/lightning/r/Trip__c/${t.Id}/view`, // URL for Trip record
                workOrderUrl: `/lightning/r/Work_Order__c/${t.Work_Orders__c}/view` // URL for Work Order record
            }));
            this.filteredList = this.trips;
            this.generateVendorOptions(this.trips);
        } else if (error) {
            console.error('Error fetching trips:', error);
        }
    }
    

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

    handleVendorChange(event) {
        this.selectedVendor = event.detail.value;
        this.filteredList = this.selectedVendor
            ? this.trips.filter(trip => trip.VendorName === this.selectedVendor)
            : this.trips;
    }

}
