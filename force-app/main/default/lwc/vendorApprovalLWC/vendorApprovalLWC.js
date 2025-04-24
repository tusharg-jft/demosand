import { LightningElement, api, wire } from 'lwc';
import getVendorsForWorkOrder from '@salesforce/apex/VendorrApprovalController.getVendorsForWorkOrder';
import submitApprovalProcess from '@salesforce/apex/VendorrApprovalController.submitApprovalProcess';
import getApprovalStatuses from '@salesforce/apex/VendorrApprovalController.getApprovalStatuses';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class VendorApprovalLWC extends LightningElement {
    @api recordId;  // Work Order record Id
    vendorData = [];
    selectedVendors = [];
    approvalStatuses = new Map();

    wiredVendorData;
    wiredApprovalStatusData;

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
            // Create vendorData with URL and Name
            this.vendorData = data.map(vendor => ({
                id: vendor.Id,
                Name: vendor.Name,
                vendorUrl: `/lightning/r/Vendor__c/${vendor.Id}/view`,
                Approval_Status__c: this.approvalStatuses.get(vendor.Id) || 'Not Submitted'
            }));
            this.wiredVendorData = data;
        } else if (error) {
            this.showToast('Error', 'Error loading vendors', 'error');
        }
    }

    // Fetch approval statuses and map to vendors
    @wire(getApprovalStatuses, { workOrderId: '$recordId' })
    wiredApprovalStatuses(result) {
        this.wiredApprovalStatusData = result;
        const { error, data } = result;
        if (data) {
            data.forEach(status => {
                // Map each approval status to the vendor ID in a Map for easy lookup
                this.approvalStatuses.set(status.Vendor__c, status.Approval_Status__c); 
            });
            // Update vendorData with the latest approval statuses
            this.vendorData = this.vendorData.map(vendor => ({
                ...vendor,
                Approval_Status__c: this.approvalStatuses.get(vendor.id) || 'Not Submitted'
            }));
        } else if (error) {
            this.showToast('Error', 'Error loading approval statuses', 'error');
        }
    }

    // Handle row selection
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedVendors = selectedRows.map(row => row.id); // Store selected vendor IDs
    }

    // Handle submit approval process
    handleSubmitApproval() {
        if (this.selectedVendors.length > 0) {
            submitApprovalProcess({ vendorIds: this.selectedVendors, workOrderId: this.recordId })
                .then(() => {
                    this.showToast('Success', 'Approval submitted successfully', 'success');

                     // Refresh approval statuses and vendor data after submission
                     refreshApex(this.wiredApprovalStatusData);
                     refreshApex(this.wiredVendorData);
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