/* import { LightningElement, api, wire } from 'lwc';
import getRelatedDocuments from '@salesforce/apex/RelatedNotesAndAttachmentsController.getRelatedDocuments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RelatedNotesAndAttachments extends LightningElement {
    @api recordId; // Automatically populated with record ID on record pages
    @api targetObjectId; // Kept for backward compatibility but unused

    records = [];
    error;

    // Use only recordId directly, ignoring targetObjectId
    @wire(getRelatedDocuments, { targetObjectId: '$recordId' })
    wiredDocuments({ error, data }) {
        console.log('Fetched Object ID:', this.recordId); // Log to verify the fetched recordId

        if (data) {
            if (data.length > 0) {
                this.records = data;
                this.error = undefined;
                console.log('Documents Loaded:', this.records); // Log records
            } else {
                this.records = [];
                this.error = undefined;
                console.log('No documents found for this record');
            }
        } else if (error) {
            this.error = error;
            this.records = [];
            console.error('Error loading documents:', JSON.stringify(error)); // Log the error
            this.showToast('Error', 'Failed to load documents', 'error');
        }
    }

    handleOpen(event) {
        const contentDocumentId = event.target.dataset.id;
        window.open(`/lightning/r/ContentDocument/${contentDocumentId}/view`, '_blank');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}*/


import { LightningElement, api, wire } from 'lwc';
import getRelatedDocuments from '@salesforce/apex/RelatedNotesAndAttachmentsController.getRelatedDocuments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RelatedNotesAndAttachments extends LightningElement {
    @api recordId; // For standard record ID
    @api targetObjectId; // For passing TargetObjectId on approval pages

    records = [];
    error;

    // Determine which ID to use (either targetObjectId or recordId)
    get objectId() {
        return this.targetObjectId || this.recordId;
    }

    @wire(getRelatedDocuments, { targetObjectId: '$objectId' })
    wiredDocuments({ error, data }) {
        console.log('Object ID:', this.objectId); // Log to check if the object ID is correct

        if (data) {
            if (data.length > 0) { // Check if any records are returned
                this.records = data;
                this.error = undefined;
            } else {
                this.records = []; // No records found; set records to empty array
                this.error = undefined;
                console.log('No documents found for this Work Order');
            }
        } else if (error) {
            this.error = error;
            this.records = [];
            console.log('Error:', error); // Log the error for further debugging
            this.showToast('Error', 'Failed to load documents', 'error');
        }
    }

    handleOpen(event) {
        const contentDocumentId = event.target.dataset.id;
        window.open(`/lightning/r/ContentDocument/${contentDocumentId}/view`, '_blank');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}

/* import { LightningElement, api, wire } from 'lwc';
import getRelatedDocuments from '@salesforce/apex/RelatedNotesAndAttachmentsController.getRelatedDocuments';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class RelatedNotesAndAttachments extends LightningElement {
    @api recordId; // Standard Record ID
    @api targetObjectId; // Used for Approval Process Pages

    records = [];
    error;

    // Use targetObjectId for approval page; otherwise, default to recordId
    get objectId() {
        return this.targetObjectId || this.recordId;
    }

    @wire(getRelatedDocuments, { targetObjectId: '$objectId' })
    wiredDocuments({ error, data }) {
        if (data) {
            this.records = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.showToast('Error', 'Failed to load documents', 'error');
        }
    }

    handleOpen(event) {
        const contentDocumentId = event.target.dataset.id;
        window.open(`/lightning/r/ContentDocument/${contentDocumentId}/view`, '_blank');
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}*/