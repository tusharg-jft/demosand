import { LightningElement, api, wire, track } from 'lwc';
import getEstimatesBasedOnWorkOrder from '@salesforce/apex/EstimateController.getEstimatesBasedOnWorkOrder';

export default class RelatedEstimates extends LightningElement {
    @api recordId;
    @track estimateList = [];
    @track filteredList = [];
    @track showModal = false;
    @track vfPageUrl = '';
    selectedStatus = 'All';

    statusOptions = [
        { label: 'All', value: 'All' },
        { label: 'Pending', value: 'Pending' },
        { label: 'Approved', value: 'Approved' },
        { label: 'Active', value: 'Active' },
        { label: 'Pending Vendor Approval', value: 'Pending Vendor Approval' },
        { label: 'Request Declined', value: 'Request Declined' },
        { label: 'cancelled', value: 'cancelled' },
    ];

    columns = [
        {
            label: 'Estimate Number',
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'Name' },
                name: 'openEstimate',
                variant: 'base',
                class: 'slds-text-link'
            }
        },
        {
            label: 'Work Order',
            fieldName: 'workOrderUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'workOrderName' },
                target: '_blank'
            }
        },
        { label: 'Vendor', fieldName: 'Vendor__c', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Net Price', fieldName: 'netPrice__c', type: 'currency' },
        { label: 'Grand Total', fieldName: 'grandTotal__c', type: 'currency' },
        { label: 'Total Discount', fieldName: 'totalDiscount__c', type: 'currency' }
    ];

    @wire(getEstimatesBasedOnWorkOrder, { workOrderId: '$recordId' })
    wiredEstimates({ error, data }) {
        if (data) {
            this.estimateList = data.map(est => ({
                ...est,
                workOrderName: est.Work_Orders__r?.Name || 'N/A',
                workOrderUrl: est.Work_Orders__c
                    ? `/lightning/r/Work_Order__c/${est.Work_Orders__c}/view`
                    : null
            }));
            this.applyFilter();
        } else if (error) {
            console.error('Error loading estimates:', error);
        }
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        this.applyFilter();
    }

    applyFilter() {
        if (this.selectedStatus === 'All') {
            this.filteredList = this.estimateList;
        } else {
            this.filteredList = this.estimateList.filter(est => est.Status__c === this.selectedStatus);
        }
    }

    handleCellClick(event) {
        const fieldName = event.detail.columnDefinition.fieldName;
        const estimateId = event.detail.row.Id;

        if (fieldName === 'Name') {
            this.vfPageUrl = `/apex/EstimatePDFPage?id=${estimateId}`;
            this.showModal = true;
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'openEstimate') {
            this.vfPageUrl = `/apex/EstimatePDFPage?id=${row.Id}`;
            this.showModal = true;
        }
    }

    closeModal() {
        this.showModal = false;
        this.vfPageUrl = '';
    }
}