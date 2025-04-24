import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getVendorWoRecords from '@salesforce/apex/VendorWoController.getVendorWoRecords';

const columns = [
    { label: 'Vendor Name', fieldName: 'VendorName' },
    { label: 'Trade', fieldName: 'TradeName' },
    { label: 'Status', fieldName: 'Vendor_Status__c' },
    { label: 'WO', fieldName: 'WorkOrderNumber' },

];

export default class VendorWoTable extends LightningElement {
    @api recordId;
    vendorWoRecords;
    error;
    columns = columns;

    @wire(getRecord, { recordId: '$recordId', fields: ['WorkOrder.Name'] })
    workOrder;

    @wire(getVendorWoRecords, { workOrderId: '$recordId' })
    wiredVendorWoRecords({ error, data }) {
        if (data) {
            this.vendorWoRecords = data.map(wo => ({
                ...wo,
                VendorName: wo.Vendor__r ? wo.Vendor__r.Name : '',  
                TradeName: wo.Trade__r ? wo.Trade__r.Name :'',
                WorkOrderNumber: wo.Work_Order__r ? wo.Work_Order__r.WorkOrderNumber : ''  
            }));
            this.error = undefined;
        } else if (error) {
            this.vendorWoRecords = undefined;
            this.error = error.body.message;
        }
    }
}