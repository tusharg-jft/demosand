import { LightningElement, api, wire, track } from 'lwc';
import getRecords from '@salesforce/apex/BulkStatusUpdateController.getRecords';
import updateRecords from '@salesforce/apex/BulkStatusUpdateController.updateRecords';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const columns = [
    { label: 'Name', fieldName: 'Name' },
    { label: 'Status', fieldName: 'Status__c', type: 'text' }
];

export default class BulkStatusUpdate extends LightningElement {
    @api recordId;
    @api objectApiName;
    @track records = [];
    selectedRecords = [];
    statusOptions = [
        { label: 'Active', value: 'Active' },
        { label: 'Inactive', value: 'Inactive' }
    ];
    selectedStatus;
    columns = columns;
    isLoading = false;

    connectedCallback() {
        this.fetchRecords();
    }

    fetchRecords() {
        this.isLoading = true;
        getRecords({ objectApiName: this.objectApiName })
            .then(result => {
                this.records = result;
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                console.error('Error fetching records:', error);
            });
    }

    handleRowSelection(event) {
        this.selectedRecords = event.detail.selectedRows.map(row => row.Id);
    }

    handleStatusChange(event) {
        this.selectedStatus = event.target.value;
    }

    handleSave() {
        if (!this.selectedStatus || this.selectedRecords.length === 0) {
            this.showToast('Error', 'Please select records and a status.', 'error');
            return;
        }

        this.isLoading = true;
        updateRecords({ recordIds: this.selectedRecords, newStatus: this.selectedStatus })
            .then(() => {
                this.showToast('Success', 'Status updated successfully.', 'success');
                this.fetchRecords();
            })
            .catch(error => {
                console.error('Error updating records:', error);
                this.showToast('Error', 'Failed to update status.', 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}