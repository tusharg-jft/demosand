import { LightningElement, api, wire } from 'lwc';
import getVendorsForWorkOrder from '@salesforce/apex/VendorApprovalController2.getVendorsForWorkOrder';
import submitApprovalProcess from '@salesforce/apex/VendorApprovalController2.submitApprovalProcess';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class VendorApprovalLWC extends LightningElement {
    @api recordId;  
    vendorData = [];
    selectedVendors = [];

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
        },
        {
            label: 'Approval Status',
            fieldName: 'Approval_Status__c',
            type: 'text',
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
                vendorUrl: vendor.vendorUrl,
                Approval_Status__c: vendor.Approval_Status__c || 'Not Submitted'
            }));
        } else if (error) {
            this.showToast('Error', 'Error loading vendors', 'error');
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedVendors = selectedRows.map(row => row.id); // Correctly store selected vendor IDs
    }

    handleSubmitApproval() {
        if (this.selectedVendors.length > 0) {
            // Call Apex method to submit approval and create VendorWO records
            submitApprovalProcess({ vendorIds: this.selectedVendors, workOrderId: this.recordId })
                .then(() => {
                    this.showToast('Success', 'Approval submitted successfully, VendorWO records created.', 'success');
                })
                .catch(error => {
                    this.showToast('Error', 'Approval submission failed: ' + error.body.message, 'error');
                });
        } else {
            this.showToast('Warning', 'Please select at least one vendor', 'warning');
        }
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}