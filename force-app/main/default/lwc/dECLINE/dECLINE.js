import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import STATUS_FIELD from '@salesforce/schema/Vendor_Trade_Rate_Management__c.Status__c';
import RECORD_ID_FIELD from '@salesforce/schema/Vendor_Trade_Rate_Management__c.Id';

export default class DeclineButton extends LightningElement {
    @api recordId;
    @track status;

    // Fetch record data
    @wire(getRecord, { recordId: '$recordId', fields: [STATUS_FIELD] })
    wiredRecord({ error, data }) {
        if (data) {
            this.status = data.fields.Status__c.value;
            console.log('Fetched Status:', this.status); // ✅ Debugging log
        } else if (error) {
            console.error('Error fetching record:', error);
        }
    }

    handleDecline() {
        const fields = {};
        fields[RECORD_ID_FIELD.fieldApiName] = this.recordId;
        fields[STATUS_FIELD.fieldApiName] = 'Declined';

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Status updated to Declined',
                        variant: 'success'
                    })
                );
                // Refresh UI by fetching the latest status
                return refreshApex(this.wiredRecord);
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error'
                    })
                );
            });
    }

    get showDeclineButton() {
        console.log('Checking button visibility: Status is', this.status);
        return this.status === 'Approved'; // ✅ Ensure case-sensitive match
    }
}