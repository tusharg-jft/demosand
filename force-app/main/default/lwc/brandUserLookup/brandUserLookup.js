import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getBrandUsers from '@salesforce/apex/BrandUserController.getBrandUsers';

export default class BrandUserLookup extends LightningElement {
    @api recordId;
    @api selectedUserId;
    searchTerm = '';
    users = [];
    
    @wire(getBrandUsers, { searchKey: '$searchTerm' })
    wiredUsers({ error, data }) {
        if (data) {
            this.users = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.users = [];
        }
    }
    
    handleSearch(event) {
        this.searchTerm = event.target.value;
    }
    
    handleSelection(event) {
        const userId = event.currentTarget.dataset.id;
        const selectedEvent = new CustomEvent('selection', {
            detail: userId
        });
        this.dispatchEvent(selectedEvent);
    }
}