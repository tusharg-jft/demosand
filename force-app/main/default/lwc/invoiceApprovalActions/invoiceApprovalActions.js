import { LightningElement, api, wire } from 'lwc';
import getCurrentUserProfileName from '@salesforce/apex/InvoiceApprovalController.getCurrentUserProfileName';
import updateInvoiceStatus from '@salesforce/apex/InvoiceApprovalController.updateInvoiceStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

import STATUS_FIELD from '@salesforce/schema/Estimate__c.Status__c';

export default class InvoiceApprovalButtons extends LightningElement {
    @api recordId;
    showButtons = false;
    currentStatus;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD] })
    wiredInvoice({ data, error }) {
        if (data) {
            this.currentStatus = data.fields.Status__c.value;
            this.checkAccess();
        }
    }

    checkAccess() {
        if (this.currentStatus === 'Pending' || this.currentStatus==='On Hold') {
            getCurrentUserProfileName()
                .then(profileName => {
                    if (profileName === 'Vendor Profile') {
                        this.showButtons = false;
                    } else {
                        this.showButtons = true;
                    }
                })
                //     profileName => {
                //     if (['Corporate Profile', 'Brand Profile', 'System Administrator'].includes(profileName)) {
                //         this.showButtons = true;
                //     }
                // })
                .catch(error => {
                    console.error('Error fetching profile:', error);
                });
        }
    }

    handleAction(event) {
        const action = event.target.dataset.action;
        console.log(this.recordId);
        console.log(action);

        updateInvoiceStatus({ invoiceId: this.recordId, action })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Invoice ${action === 'approve' ? 'Approved' : 'Rejected'} successfully.`,
                        variant: 'success'
                    })
                );
                this.showButtons = false;
                // Refresh the view
                setTimeout(() => {
                    console.log("working");
                    eval("$A.get('e.force:refreshView').fire();"); // Classic Aura-style workaround for record page
                }, 500);
            })
            .catch(error => {
                console.error('Error updating status:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to update status.',
                        variant: 'error'
                    })
                );
            });
           
    }
}