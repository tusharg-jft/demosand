import { LightningElement, api, wire, track } from 'lwc';
import getFilteredWorkOrders from '@salesforce/apex/WOonProject.getFilteredWorkOrders';
import addWorkOrdersToProject from '@salesforce/apex/WOonProject.addWorkOrdersToProject';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WorkOrderList extends LightningElement {
    @api recordId;
    @track workOrders = [];
    @track error = '';
    @track isLoading = true;
    @track selectedWorkOrders = [];
    @track searchQuery = '';  // Store the search query

    columns = [
        {
            label: 'Name',
            fieldName: 'workOrderUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'WorkOrderNumber' }, target: '_blank' }
        },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Priority', fieldName: 'Select__c', type: 'text' },
        { label: 'Brand', fieldName: 'Brand__c', type: 'text' }
    ];

    @wire(getFilteredWorkOrders, { projectId: '$recordId', searchQuery: '$searchQuery' })
    wiredWorkOrders({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.workOrders = data.map(workOrder => {
                return {
                    ...workOrder,
                    workOrderUrl: `/lightning/r/WorkOrder/${workOrder.Id}/view`
                };
            });
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.workOrders = [];
        }
    }

    handleSearchChange(event) {
        // Update the search query and trigger the wire service to re-fetch data
        this.searchQuery = event.target.value;
    }

    handleSelectedRows(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedWorkOrders = selectedRows.map(row => row.Id);
        console.log('Selected WorkOrders:', this.selectedWorkOrders);
    }

    handleAdd() {
        if (this.selectedWorkOrders.length === 0) {
            this.error = 'Please select at least one work order.';
            return;
        }
    
        addWorkOrdersToProject({ workOrderIds: this.selectedWorkOrders, projectId: this.recordId })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Work Orders added to the Project.',
                        variant: 'success'
                    })
                );
                
                // Clear selected rows and refresh the datatable
                this.selectedWorkOrders = [];
                const datatable = this.template.querySelector('lightning-datatable');
                if (datatable) {
                    datatable.selectedRows = [];
                }
            })
            .catch(error => {
                console.error('Error adding work orders:', error);
    
                this.error =
                    (error && error.body && error.body.message) ||
                    error.message ||
                    'An unexpected error occurred';
    
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.error,
                        variant: 'error'
                    })
                );
            });
    }

    handleCancel() {
        this.selectedWorkOrders = [];
        this.error = '';  
    }
}