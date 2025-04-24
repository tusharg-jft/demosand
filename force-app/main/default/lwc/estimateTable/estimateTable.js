import { LightningElement, api, wire, track } from 'lwc';
import getEstimates from '@salesforce/apex/EstimateController.getEstimates';
import submitForApproval from '@salesforce/apex/EstimateApprovalController.submitForApproval';
import createInvoiceFromEstimate from '@salesforce/apex/InvoiceApprovalController.createInvoiceFromEstimate';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class EstimateTable extends NavigationMixin(LightningElement) {
    @api recordId;
    @track isModalOpen = false;
    @track showModal = false;
    @track parsedEstimateData = [];
    estimateid;

    estimates = { data: [], error: null };

    @wire(getEstimates, { workOrderId: '$recordId' })
    wiredEstimates({ data, error }) {
        if (data) {
            console.log("data", data);
            this.estimates = {
                data: data.map(row => ({
                    ...row,
                    recordLink: '/' + row.Id,
                    estimateDataLabel: row.Estimate_Data__c ? 'View Estimate Data' : 'No Data',
                    submitLabel: row.Status__c === 'Pending' 
                        ? 'Submit for Approval' 
                        : row.Status__c === 'Approved' 
                            ? 'Approved' 
                            : row.Status__c === 'Rejected'
                                ? 'Rejected'
                                : 'N/A',
                    invoiceLabel: row.Status__c === 'Approved' 
                        ? 'Create Invoice'
                        : '----'
                })),
                error: null
            };
        } else if (error) {
            this.estimates = { data: [], error };
        }
    }

    get firstEstimate() {
        return this.estimates.data && this.estimates.data.length > 0
            ? this.estimates.data[0]
            : null;
    }

    handleSubmitInvoiceApproval() {
        this.estimateid = this.estimates.data[0].Id;
        console.log('Submitting Estimate Id:', this.estimateid);

        createInvoiceFromEstimate({ estimateId: this.estimateid })
            .then(invoiceId => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Invoice created successfully',
                        variant: 'success'
                    })
                );

                // Navigate to the newly created invoice record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: invoiceId,
                        objectApiName: 'Invoice__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body ? error.body.message : error.message,
                        variant: 'error'
                    })
                );
            });
    }

    handleEditClick(event) {
        this.estimateRecordId = event.currentTarget.dataset.id;
        this.showModal = true;
    }

    handleCloseModal() {
        this.showModal = false;
    }

    handleSave(event) {
        // const estimateData = event.detail;
        
        // saveEstimate({ estimateId: this.estimateRecordId, estimateData: estimateData })
        //     .then(result => {
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Success',
        //                 message: 'Estimate saved successfully',
        //                 variant: 'success'
        //             })
        //         );
        //         this.showModal = false;
        //         // Refresh the estimates data
        //         return refreshApex(this.estimates);
        //     })
        //     .catch(error => {
        //         this.dispatchEvent(
        //             new ShowToastEvent({
        //                 title: 'Error',
        //                 message: error.body.message,
        //                 variant: 'error'
        //             })
        //         );
        //     });
    }

    isSubmitting = false;

    handleSubmitApproval(event) {
        this.estimateid = this.estimates.data[0].Id;
        console.log('Submitting Estimate Id:', this.estimateid);

        this.isSubmitting = true;
        console.log('Before Apex Call');

        submitForApproval({ estimateId: this.estimateid })
            .then(result => {
                console.log('Apex Response:', result);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Submitted',
                    message: result,
                    variant: 'success'
                }));
            })
            .catch(error => {
                console.error('Error submitting for approval', error);
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: error.body?.message || 'Unexpected error',
                    variant: 'error'
                }));
            })
            .finally(() => {
                this.isSubmitting = false;
                console.log('After Apex Call');
            });
    }

    get submitButtonLabel() {
        return this.isSubmitting ? 'Pending' : 'Submit for Approval';
    }

    get submitButtonStyle() {
        return this.isSubmitting ? 'background-color: yellow;' : '';
    }

    handleEstimateDataClick(event) {
        const rowId = event.currentTarget.dataset.recordId;
        const record = this.estimates.data.find(r => r.Id === rowId);

        if (record && record.Estimate_Data__c) {
            try {
                const parsed = JSON.parse(record.Estimate_Data__c);

                this.parsedEstimateData = parsed.Estimate.map((section, sectionIndex) => {
                    const fields = section.Fields;

                    return {
                        label: section.Label,
                        // Header row (assumes first row defines columns)
                        columns: fields.length > 0
                            ? fields[0].map((col, i) => ({
                                key: `header-${sectionIndex}-${i}-${col.filedLabel}`,
                                ...col
                            }))
                            : [],
                        // Data rows
                        fields: fields.map((row, rowIndex) => ({
                            rowKey: `row-${sectionIndex}-${rowIndex}`,
                            cols: row.map((col, colIndex) => ({
                                key: `col-${sectionIndex}-${rowIndex}-${colIndex}-${col.filedLabel}`,
                                ...col
                            }))
                        }))
                    };
                });

                this.isModalOpen = true;
            } catch (error) {
                console.error('Failed to parse Estimate_Data__c JSON:', error);
                this.parsedEstimateData = [];
                this.isModalOpen = true; // still open modal, maybe with error/fallback message
            }
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.parsedEstimateData = [];
    }
}