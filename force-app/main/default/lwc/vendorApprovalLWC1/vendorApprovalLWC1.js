import { LightningElement, api, wire } from 'lwc';
import getVendorsForWorkOrder from '@salesforce/apex/VendorApprovalController1.getVendorsForWorkOrder';
import submitApprovalProcess from '@salesforce/apex/VendorApprovalController1.submitApprovalProcess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class VendorApprovalLWC extends LightningElement {
    @api recordId;  // Work Order record Id
    vendorData = [];
    selectedVendors = [];

    // Define columns
    columns = [
        { 
            label: 'Select', 
            type: 'checkbox', 
            fieldName: 'isSelected', 
            initialWidth: 30,
            sortable: false
        },
        {
            label: 'Vendor Name',
            fieldName: 'vendorUrl',
            type: 'url', 
            typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }, 
            sortable: false
        }
    ];

    // Fetch vendors
    @wire(getVendorsForWorkOrder, { workOrderId: '$recordId' })
    wiredVendors({ error, data }) {
        if (data) {
            this.vendorData = data.map(vendor => ({
                id: vendor.Id,
                Name: vendor.Name,
                vendorUrl: `/lightning/r/Vendor__c/${vendor.Id}/view`,
            }));
        } else if (error) {
            this.showToast('Error', 'Error loading vendors', 'error');
        }
    }

    // Handle row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedVendors = selectedRows.map(row => row.id); // Correctly store selected vendor IDs
    }

    // Handle submit approval process
    handleSubmitApproval() {
        if (this.selectedVendors.length > 0) {
            submitApprovalProcess({ vendorIds: this.selectedVendors, workOrderId: this.recordId })
                .then(() => {
                    this.showToast('Success', 'Approval submitted successfully', 'success');
                })
                .catch(error => {
                    this.showToast('Error', 'Approval submission failed: ' + error.body.message, 'error');
                });
        } else {
            this.showToast('Warning', 'Please select at least one vendor', 'warning');
        }
    }

    // Show toast message
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}