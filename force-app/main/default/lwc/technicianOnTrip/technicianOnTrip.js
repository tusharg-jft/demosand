import { LightningElement, api, track, wire } from 'lwc';
import getTechnicianResources from '@salesforce/apex/WorkOrderResourceController.getTechnicianResources';
import createTripTechnicians from '@salesforce/apex/WorkOrderResourceController.createTripTechnicians';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class TechnicianOnTrip extends LightningElement {
    @api recordId;  // The Trip Id passed to the component
    @track fieldResourceData = []; // Store the technician data
    @track selectedRowIds = [];    // Store selected rows
    @track error = null;           // Store error message
    @track workOrderId;

    // Columns for the datatable
    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Resource Type', fieldName: 'Resource_Type__c' },
    ];

    // Wire method to fetch data based on the Trip Id
    @wire(getTechnicianResources, { tripId: '$recordId' })
    wiredTechnicians({ data, error }) {
        if (data) {
            this.fieldResourceData = data;
            this.error = null;
           // this.workOrderId = data[0]?.Work_Order__c;
        } else if (error) {
            this.error = error;
            this.showToast('Error', 'Failed to load technician records', 'error');
            console.error(error);
        }
    }

    // Handle row selection
    handleRowSelection(event) {
        this.selectedRowIds = event.detail.selectedRows.map(row => row.Id);
        console.log('Selected Rows:', this.selectedRowIds);
    }


     // Handle button click to create TripTechnician records
     AddTechnician() {
        if (this.selectedRowIds.length > 0) {
            createTripTechnicians({ 
                tripId: this.recordId, 
              //  workOrderId: this.workOrderId, 
                fieldResourceIds: this.selectedRowIds    
            })
            .then(() => {
                this.showToast('Success', 'Technician records have been added to the Trip.', 'success');
                // Optionally refresh the datatable or clear selection
            })
            .catch(error => {
                this.showToast('Error', 'Failed to add technician records.', 'error');
                console.error(error);
            });
        } else {
            this.showToast('Warning', 'Please select at least one technician.', 'warning');
        }
    }

    // Show Toast utility for notifications
    showToast(title, message, variant) {
        const toastEvent = new ShowToastEvent({
            title,
            message,
            variant,
        });
        this.dispatchEvent(toastEvent);
    }
}