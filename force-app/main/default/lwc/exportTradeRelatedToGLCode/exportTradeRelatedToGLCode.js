import { LightningElement, api, wire, track } from 'lwc';
import getTradesByGLCode from '@salesforce/apex/TradeController.getTradesByGLCode';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import saveFile from '@salesforce/apex/TradeController.saveFile';

export default class TradeList extends LightningElement {
    @api recordId;
    @track trades = [];
    @track error;
    @track isLoading = true;
    fileName = 'Trades.csv';

    columns = [
        { label: 'Trade Name', fieldName: 'tradeRecordUrl', type: 'url', typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' } },
        { label: 'Trade Name', fieldName: 'Name', type: 'Text' },
        { label: 'IsActive', fieldName: 'IsActive__c', type: 'Boolean' },
    ];

    @wire(getTradesByGLCode, { glCodeId: '$recordId' })
    wiredTrades({ error, data }) {
        this.isLoading = true;
        if (data) {
            this.trades = data.map(trade => ({
                ...trade,
                tradeRecordUrl: '/lightning/r/Trade__c/' + trade.Id + '/view'
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.trades = undefined;
            this.showToast('Error', error.body.message, 'error');
        }
        this.isLoading = false;
    }

    get noTrades() {
        return this.trades && this.trades.length === 0;
    }

    handleExportAsCSV() {
        if (this.noTrades) {
            this.showToast('No Trades', 'No trades found to export.', 'warning');
            return;
        }

        let csvContent = "data:text/csv;charset=utf-8,";
        let header = this.columns.map(col => col.label).join(",");
        csvContent += header + "\r\n";

        this.trades.forEach(trade => {
            let row = this.columns.map(col => `"${trade[col.fieldName] ? trade[col.fieldName].toString().replace(/"/g, '""') : ''}"`).join(",");
            csvContent += row + "\r\n";
        });

        let base64Content = btoa(csvContent); 
        this.uploadCSVFile(base64Content);
    }

    uploadCSVFile(base64Content) {
        this.isLoading = true;
    
        saveFile({
            fileName: this.fileName,
            base64: base64Content,
            recordId: this.recordId
        })
        .then(() => {
            this.showToast('Success', 'File exported and attached successfully!', 'success');
            this.isLoading = false;
        })
        .catch(error => {
            console.error('Error occurred while exporting the CSV:', error);
            const errorMessage = error.body ? error.body.message : 'Unknown error';
            this.showToast('Error', errorMessage, 'error');
            this.isLoading = false;
        });
    }
    
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}