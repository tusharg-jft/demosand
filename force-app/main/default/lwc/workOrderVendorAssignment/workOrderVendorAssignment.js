import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Import Apex methods
import getActiveVendorsForWorkOrder from '@salesforce/apex/WorkOrderVendorAssignmentController.getActiveVendorsForWorkOrder';
import getPrioritizedVendorsForWorkOrder from '@salesforce/apex/WorkOrderVendorAssignmentController.getPrioritizedVendorsForWorkOrder'; // Fixed missing controller name
import assignVendorToWorkOrder from '@salesforce/apex/WorkOrderVendorAssignmentController.assignVendorToWorkOrder';
import isWorkOrderAvailableForAssignment from '@salesforce/apex/WorkOrderVendorAssignmentController.isWorkOrderAvailableForAssignment';

export default class WorkOrderVendorAssignment extends LightningElement {
    @api recordId; // Work Order Id
    @track vendors = []; // List of vendors
    @track selectedVendorIds = []; // Selected vendor Ids
    @track isLoading = false; // Loading state
    @track error; // Error message
    @track isAvailableForAssignment = false; // Whether the work order is available for assignment
    
    wiredVendorsResult; // Wired result for refreshApex
    wiredAvailabilityResult; // Wired result for refreshApex
    
    // Define columns for the datatable
    columns = [
        { 
            label: 'Vendor Name', 
            fieldName: 'Name', 
            type: 'text',
            sortable: true
        },
        { 
            label: 'Vendor Approval Status', 
            fieldName: 'ApprovalStatus',    
            type: 'text',
            sortable: true
        }
    ];
    
    // Wire the isWorkOrderAvailableForAssignment method to check if the work order is available for assignment
    @wire(isWorkOrderAvailableForAssignment, { workOrderId: '$recordId' })
    wiredAvailability(result) {
        this.wiredAvailabilityResult = result;
        console.log('Work Order Availability Result:', result);
        if (result.data !== undefined ) {
            this.isAvailableForAssignment = result.data;
            this.error = undefined;
        } else if (result.error) {
            this.error = result.error.body.message;
            this.isAvailableForAssignment = false;
        }
    }
    
    // Wire the getPrioritizedVendorsForWorkOrder method first
    @wire(getPrioritizedVendorsForWorkOrder, { workOrderId: '$recordId' })
    wiredPrioritizedVendors(prioritizedResult) {
        console.log('work order id:', this.recordId);
        console.log('Prioritized Vendors Result:', prioritizedResult);
        // Store the result for refreshApex
        this.wiredVendorsResult = prioritizedResult; // Store for refreshApex
        this.isLoading = true;
        if (prioritizedResult.data) {
            this.fetchActiveVendors(prioritizedResult.data);
        } else if (prioritizedResult.error) {
            this.error = prioritizedResult.error.body.message;
            this.vendors = [];
            this.isLoading = false;
        }
    }
    
    // Fetch active vendors and combine with prioritized vendors
    fetchActiveVendors(prioritizedVendors) {
        console.log('Prioritized Vendors:', prioritizedVendors);
        // Call Apex to get active vendors for the work order
        getActiveVendorsForWorkOrder({ workOrderId: this.recordId })
            .then(activeVendors => {
                // Filter out preferred vendors from active vendors to avoid duplicates
                console.log('Active Vendors:', activeVendors);
                const preferredIds = new Set(prioritizedVendors.map(v => v.Id));
                const nonPreferredVendors = activeVendors.filter(v => !preferredIds.has(v.Id));
                // Combine preferred vendors (at top) with non-preferred vendors
                this.vendors = [...prioritizedVendors, ...nonPreferredVendors];
                this.error = undefined;
                this.isLoading = false;
            })
            .catch(error => {
                // If active vendors fail, still show prioritized vendors
                this.vendors = prioritizedVendors;
                this.error = error.body.message;
                this.isLoading = false;
            });
    }
    
    // Handle row selection in the datatable
    handleRowSelection(event) {
        if (!this.isRowSelectionDisabled) { // Only process if row selection is enabled
            this.selectedVendorIds = event.detail.selectedRows.map(row => row.Id);
        }
    }
    
    // Handle assign button click
    handleAssignVendor() {
        if (this.selectedVendorIds.length === 0) {
            this.showToast('Error', 'Please select at least one vendor.', 'error');
            return;
        }
        
        this.isLoading = true;
        assignVendorToWorkOrder({
            workOrderId: this.recordId,
            vendorIds: this.selectedVendorIds
        })
        .then(result => {
            this.showToast('Success', result, 'success');
            this.isLoading = false;
            
            // Reset selection
            this.selectedVendorIds = [];
            
            // Refresh the data
            return Promise.all([
                refreshApex(this.wiredVendorsResult),
                refreshApex(this.wiredAvailabilityResult)
            ]);
        })
        .catch(error => {
            this.error = error.body.message;
            this.showToast('Error', this.error, 'error');
            this.isLoading = false;
        });
    }
    
    // Show toast message
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }
    
    // Getters
    get hasVendors() {
        return this.vendors && this.vendors.length > 0;
    }
    
    get noVendorsMessage() {
        return this.error ? this.error : 'No active vendors found for this work order\'s trade.';
    }
    
    get isComponentDisabled() {
        return !this.isAvailableForAssignment;
    }
    
    get isButtonDisabled() {
        return this.selectedVendorIds.length === 0 || !this.isAvailableForAssignment;
    }
    
    get componentMessage() {
        if (!this.isAvailableForAssignment) {
            return 'This work order is already assigned to a vendor or is not in an Active status.';
        }
        return '';
    }
    
    // New getter to check if any vendor has ApprovalStatus = 'Approved'
    get isRowSelectionDisabled() {
        return this.vendors.some(vendor => vendor.ApprovalStatus === 'Approved');
    }
}