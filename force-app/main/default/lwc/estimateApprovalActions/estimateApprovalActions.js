import { LightningElement, api, wire } from 'lwc';
import getCurrentUserProfileName from '@salesforce/apex/EstimateApprovalController.getCurrentUserProfileName';
import updateEstimateStatus from '@salesforce/apex/EstimateApprovalController.updateEstimateStatus';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';

import STATUS_FIELD from '@salesforce/schema/Estimate__c.Status__c';

export default class EstimateApprovalButtons extends LightningElement {
    @api recordId;
    showButtons=false ;
    currentStatus;

    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD] })
    wiredEstimate({ data, error }) {
        if (data) {
            this.currentStatus = data.fields.Status__c.value;
            console.log(this.currentStatus);
            this.checkAccess();
        }
    }

    checkAccess() {
        if (this.currentStatus === 'Pending'|| this.currentStatus== 'Submited_For_Approval') {
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

        updateEstimateStatus({ estimateId: this.recordId, action })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Estimate ${action === 'approve' ? 'Approved' : 'Rejected'} successfully.`,
                        variant: 'success'
                    })
                );
                this.showButtons = false;
                // Refresh the view
                setTimeout(() => {
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