import { LightningElement, wire, api, track } from 'lwc';
import getTrades from '@salesforce/apex/VendorTradeController.getTrades';
import getCurrencyFields from '@salesforce/apex/VendorTradeController.getCurrencyFields';
import saveVendorTradeRate from '@salesforce/apex/VendorTradeController.saveVendorTradeRate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTradesByVendor from '@salesforce/apex/VendorTradeController.getTradesByVendor';
import getAllCorporates from '@salesforce/apex/VendorTradeController.getAllCorporates';

export default class VendorTrade extends LightningElement {
    @api recordId;                     // Vendor ID from the record page
    @track trades = [];                 // List of trades with isChecked property
    @track selectedTradeId = null;   
    @track selectedCorpId = null;
    @track selectedCorpName = '';   // Selected trade ID
    @track selectedTradeName = '';      // Selected trade name
    @track currencyFields = [];         // List of currency fields
    @track fieldValues = {};            // Field values (API names and their values)
    showModal = false;                  // Modal visibility flag

    // Fetch trades and add a boolean 'isChecked' property

    @track corporateOptions = [];

    @wire(getAllCorporates)
    wiredCorporates({ data, error }) {
        if (data) {
            this.corporateOptions = data.map(corp => ({
                label: corp.Name,
                value: corp.Id
            }));
        } else if (error) {
            console.error('Error fetching corporates:', error);
        }
    }




@wire(getTradesByVendor, { vendorId: '$recordId' })
wiredTrades({ error, data }) {
    if (data) {
        this.trades = data.map(trade => ({
            ...trade,
            isChecked: false
        }));
    } else if (error) {
        console.error('Error fetching trades:', error);
    }
}


    // Handle checkbox selection
    handleCheckboxChange(event) {
        const tradeId = event.target.dataset.id;

        // Deselect all checkboxes first
        this.trades = this.trades.map(trade => {
            trade.isChecked = (trade.Id === tradeId);
            return trade;
        });

        // Update selected trade ID and name
        const selectedTrade = this.trades.find(trade => trade.isChecked);
        this.selectedTradeId = selectedTrade?.Id || null;
        this.selectedTradeName = selectedTrade?.Name || '';  // Store trade name
    }

    // Clear all checkboxes
    clearCheckboxes() {
        this.trades = this.trades.map(trade => {
            trade.isChecked = false;
            return trade;
        });
        this.selectedTradeId = null;
        this.selectedTradeName = '';
        this.selectedCorpId=null;
        this.selectedCorpName='';
    }

    // Show modal and fetch currency fields
    handleAddTrade() {
        if (!this.selectedTradeId) {
            this.showToast('Error', 'Please select a trade before adding.', 'error');
            return;
        }

        getCurrencyFields()
            .then(result => {
                this.currencyFields = result.map(field => ({
                    apiName: field.apiName,
                    label: field.label
                }));
                this.showModal = true;
            })
            .catch(error => {
                console.error('Error fetching currency fields:', error);
            });
    }

    // Close the modal
    closeModal() {
        this.showModal = false;
    }

    // Clear the text fields in the modal
    clearFields() {
        this.fieldValues = {};
        this.template.querySelectorAll('lightning-input').forEach(input => {
            input.value = '';
        });
    }


    handleCorporateChange(event) {
        this.selectedCorpId = event.detail.value;
    }

    // Handle currency field value changes
    handleCurrencyChange(event) {
        const fieldName = event.target.dataset.field;
        this.fieldValues[fieldName] = parseFloat(event.target.value) || 0;
    }

    // Save the trade rate record with validation for currency fields only
    saveTradeRate() {
        if (!this.selectedTradeId) {
            this.showToast('Error', 'Please select a trade.', 'error');
            return;
        }

        // Validate only currency fields
        const currencyFields = this.currencyFields.map(field => field.apiName);
        const hasEmptyCurrencyFields = currencyFields.some(field => {
            const value = this.fieldValues[field];
            return value === '' || value === null || value === undefined || isNaN(value);
        });

        if (hasEmptyCurrencyFields) {
            this.showToast('Error', 'All currency fields must be filled before saving.', 'error');
            return;
        }

        saveVendorTradeRate({
            vendorId: this.recordId,
            tradeId: this.selectedTradeId,
            corporateId: this.selectedCorpId,
            currencyValues: this.fieldValues
            
        })
        .then(() => {
            this.showToast('Success', 'Trade rate saved successfully.', 'success');
            this.closeModal();
        })
        .catch(error => {
            console.error('Error saving trade rate:', error);
            this.showToast('Error', 'Failed to save trade rate.', 'error');
        });
    }

    // Toast message handler
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title,
            message,
            variant
        });
        this.dispatchEvent(event);
    }
}