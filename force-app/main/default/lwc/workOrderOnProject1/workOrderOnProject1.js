import { LightningElement, api, wire, track } from 'lwc';
import getFilteredWorkOrderss from '@salesforce/apex/WOonProject1.getFilteredWorkOrderss';
import addWorkOrdersToProjects from '@salesforce/apex/WOonProject1.addWorkOrdersToProjects';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WorkOrderList extends LightningElement {
        @api recordId;
        @track workOrders = [];
        @track visibleWorkOrders = [];
        @track error = '';
        @track isLoading = true;
        @track updatedCheckboxValues = {};
        @track searchQuery = '';
        @track showViewMore = false;
        @track isAnyChangeMade = false;  
    
        wiredWorkOrdersResult;
    
        RECORD_LIMIT = 5; 
        offset = 0;
    
        columns = [
            {
                label: 'Name',
                fieldName: 'workOrderUrl',
                type: 'url',
                typeAttributes: { label: { fieldName: 'WorkOrderNumber' }, target: '_blank' }
            },
            { label: 'Status', fieldName: 'Status', type: 'text' },
            { label: 'Priority', fieldName: 'Priority', type: 'text' },
            { label: 'Brand', fieldName: 'Brand__c', type: 'text' },
            {
                label: 'Assign to Project',
                fieldName: 'Assign_to_Project__c',
                type: 'boolean',
                editable: true
            }
        ];        
        

        @wire(getFilteredWorkOrderss, { projectId: '$recordId', searchQuery: '$searchQuery' })
        wiredWorkOrders(result) {
            this.isLoading = false;
            this.wiredWorkOrdersResult = result;
            const { error, data } = result;
    
            if (data) {
                this.workOrders = data.map(workOrder => ({
                    ...workOrder,
                    workOrderUrl: `/lightning/r/WorkOrder/${workOrder.Id}/view`
                }));
                this.error = undefined;
                this.updateVisibleRecords();
            } else if (error) {
                this.error = error.body.message;
                this.workOrders = [];
                this.visibleWorkOrders = [];
            }
        }
    
        updateVisibleRecords() {
            this.visibleWorkOrders = this.workOrders.slice(0, this.offset + this.RECORD_LIMIT);
            this.showViewMore = this.workOrders.length > this.visibleWorkOrders.length;
        }
    
        handleViewMore() {
            this.offset += this.RECORD_LIMIT;
            this.updateVisibleRecords();
        }
    
        handleSearchChange(event) {
            this.searchQuery = event.target.value;
            this.offset = 0; // Reset the offset when searching
        }
    
        handleCellChange(event) {
            const { draftValues } = event.detail;
            draftValues.forEach(change => {
                this.updatedCheckboxValues[change.Id] = change.Assign_to_Project__c;
            });
            
            // Set the flag to true indicating changes were made
            this.isAnyChangeMade = Object.keys(this.updatedCheckboxValues).length > 0;
        }
    
        handleAdd() {
            if (Object.keys(this.updatedCheckboxValues).length === 0) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Please select at least one work order to assign or unassign to/from the project.',
                        variant: 'error'
                    })
                );
                return;
            }
    
            const workOrderIdsToAdd = [];
            const workOrderIdsToRemove = [];
            Object.keys(this.updatedCheckboxValues).forEach(workOrderId => {
                if (this.updatedCheckboxValues[workOrderId]) {
                    workOrderIdsToAdd.push(workOrderId);
                } else {
                    workOrderIdsToRemove.push(workOrderId);
                }
            });
    
            addWorkOrdersToProjects({
                workOrderIdsToAdd,
                workOrderIdsToRemove,
                projectId: this.recordId
            })
                .then(() => {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Work Orders successfully updated.',
                            variant: 'success'
                        })
                    );
    
                    this.updatedCheckboxValues = {};
                    this.isAnyChangeMade = false; // Reset the flag after submitting
                    this.offset = 0; // Reset the offset
                    return refreshApex(this.wiredWorkOrdersResult);
                })
                .catch(error => {
                    let errorMessage = 'An unexpected error occurred.';
    
                    if (error.body && error.body.message) {
                        errorMessage = error.body.message;
                    } else if (error.message) {
                        errorMessage = error.message;
                    }
    
                    this.error = errorMessage;
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
            this.updatedCheckboxValues = {};
            this.isAnyChangeMade = false;  // Reset the flag on cancel
            this.error = '';
        }
    }   


/* import { LightningElement, api, wire, track } from 'lwc';
import getFilteredWorkOrderss from '@salesforce/apex/WOonProject1.getFilteredWorkOrderss';
import addWorkOrdersToProjects from '@salesforce/apex/WOonProject1.addWorkOrdersToProjects';
import { refreshApex } from '@salesforce/apex'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class WorkOrderList extends LightningElement {
    @api recordId;
    @track workOrders = [];
    @track error = '';
    @track isLoading = true;
    @track selectedWorkOrders = [];
    @track searchQuery = '';
    @track updatedCheckboxValues = {};
    wiredWorkOrdersResult; // Store the wired result for refresh

    columns = [
        {
            label: 'Name',
            fieldName: 'workOrderUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'WorkOrderNumber' }, target: '_blank' }
        },
        { label: 'Status', fieldName: 'Status', type: 'text' },
        { label: 'Priority', fieldName: 'Priority', type: 'text' },
        { label: 'Brand', fieldName: 'Brand__c', type: 'text' },
        {
            label: 'Assign to Project',
            fieldName: 'Assign_to_Project__c',
            type: 'boolean',
            editable: true
        }
    ];

    @wire(getFilteredWorkOrderss, { projectId: '$recordId', searchQuery: '$searchQuery' })
    wiredWorkOrders(result) {
        this.isLoading = false;
        this.wiredWorkOrdersResult = result; // Save the wired result for refreshing
        const { error, data } = result;
        if (data) {
            this.workOrders = data.map(workOrder => ({
                ...workOrder,
                workOrderUrl: `/lightning/r/WorkOrder/${workOrder.Id}/view`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error.body.message;
            this.workOrders = [];
        }
    }

    handleSearchChange(event) {
        this.searchQuery = event.target.value;
    }

    handleCellChange(event) {
        const { draftValues } = event.detail;
        draftValues.forEach(change => {
            this.updatedCheckboxValues[change.Id] = change.Assign_to_Project__c;
        });
    }

    handleAdd() {
        if (Object.keys(this.updatedCheckboxValues).length === 0) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please select at least one work order to assign or unassign to/from the project.',
                    variant: 'error'
                })
            );
            return;
        }

        const workOrderIdsToAdd = [];
        const workOrderIdsToRemove = [];
        Object.keys(this.updatedCheckboxValues).forEach(workOrderId => {
            if (this.updatedCheckboxValues[workOrderId]) {
                workOrderIdsToAdd.push(workOrderId);
            } else {
                workOrderIdsToRemove.push(workOrderId);
            }
        });

        addWorkOrdersToProjects({
            workOrderIdsToAdd,
            workOrderIdsToRemove,
            projectId: this.recordId
        })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Work Orders successfully updated.',
                        variant: 'success'
                    })
                );

                this.updatedCheckboxValues = {};
                return refreshApex(this.wiredWorkOrdersResult); // Refresh the wired data
            })
            .catch(error => {
                let errorMessage = 'An unexpected error occurred.';

                if (error.body && error.body.message) {
                    errorMessage = error.body.message;
                } else if (error.message) {
                    errorMessage = error.message;
                }

                this.error = errorMessage;
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
        this.updatedCheckboxValues = {};
        this.error = '';
    }
}
*/