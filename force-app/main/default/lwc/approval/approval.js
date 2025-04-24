import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import processApproval from '@salesforce/apex/VendorTradeController.processApproval';
import isCorporateUser from '@salesforce/apex/VendorTradeController.isCorporateUser';
import getVtrmStatus from '@salesforce/apex/VendorTradeController.getVtrmStatus';

export default class VtrmApproval extends LightningElement {
    @api recordId;
    isCorporate = false; // Flag to check if the user is Corporate
    status;

    @wire(isCorporateUser, { recordId: '$recordId' })
    wiredCorporateUser({ error, data }) {
        if (data) {
            this.isCorporate = data;
        } else if (error) {
            console.error('Error fetching corporate user info', error);
        }
    }

    @wire(getVtrmStatus, { recordId: '$recordId' })
    wiredStatus({ error, data }) {
        if (data) {
            this.status = data;
        } else if (error) {
            console.error('Error fetching record status', error);
        }
    }

    get isPending() {
        return this.status === 'Pending';
    }

    handleApprove() {
        this.updateApproval(true);
    }

    handleReject() {
        this.updateApproval(false);
    }

    updateApproval(isApproved) {
        processApproval({ vtrmId: this.recordId, isApproved: isApproved })
            .then(() => {
                this.showToast('Success', isApproved ? 'Approved successfully' : 'Rejected successfully', 'success');
                setTimeout(() => {
                    eval("$A.get('e.force:refreshView').fire();"); // Classic Aura-style workaround for record page
                }, 500);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    checkStatus() {}

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}