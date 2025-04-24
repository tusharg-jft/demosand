import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getGoogleVendors from '@salesforce/apex/VendorController.getGoogleVendors';
import createTaskForVendor from '@salesforce/apex/VendorController.createTaskForVendor';

export default class VendorList extends LightningElement {
    recordId;
    externalVendors;
    error;
    selectedVendor;

    connectedCallback() {
        this.recordId = this.getRecordIdFromUrl();
        console.log('🔗 Extracted Record ID:', this.recordId);
        this.fetchExternalVendors();
    }

    getRecordIdFromUrl() {
        let url = window.location.href;
        let match = url.match(/\/Work_Order__c\/([a-zA-Z0-9]{15,18})\//);
        return match ? match[1] : null;
    }

    fetchExternalVendors() {
        getGoogleVendors({ workOrderId: this.recordId })
            .then(result => {
                console.log('✅ External vendors received:', result);
                try {
                    let parsedResult = JSON.parse(result);
                    if (parsedResult.results) {
                        this.externalVendors = parsedResult.results.map(vendor => ({
                            ...vendor,
                            status: 'Active'
                        }));
                    } else {
                        this.error = 'No results returned from Google.';
                        this.externalVendors = undefined;
                    }
                } catch (e) {
                    console.error('JSON parse error:', e);
                    this.error = e;
                    this.externalVendors = undefined;
                }
            })
            .catch(error => {
                console.error('❌ Error fetching external vendors:', error);
                this.error = error.body ? error.body.message : error;
                this.externalVendors = undefined;
            });
    }

    get externalColumns() {
        return [
            { 
                label: 'Name', 
                fieldName: 'name', 
                type: 'text',
                cellAttributes: { alignment: 'left' },
                typeAttributes: { label: { alignment: 'center' } }
            },
            { 
                label: 'Vendor Email', 
                fieldName: 'email', 
                type: 'email',
                cellAttributes: { alignment: 'left' },
                typeAttributes: { label: { alignment: 'center' } }
            },
            { 
                label: 'Distance from site(km)', 
                fieldName: 'distance', 
                type: 'number',
                cellAttributes: { alignment: 'center' },
                typeAttributes: { label: { alignment: 'center' } }
            },
            { 
                label: 'Status', 
                fieldName: 'status', 
                type: 'text',
                cellAttributes: { alignment: 'center' },
                typeAttributes: { label: { alignment: 'center' } }
            }
        ];
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length > 0) {
            this.selectedVendor = selectedRows[0];
        } else {
            this.selectedVendor = null;
        }
    }

    handleAssignVendor() {
        createTaskForVendor({ workOrderId: this.recordId})
            .then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'External Vendor Assigned Succesfully',
                    variant: 'success'
                }));
                this.selectedVendor = null;
            })
            .catch(error => {
                console.error('Error creating task:', error);
                this.error = error.body ? error.body.message : error;
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: this.error,
                    variant: 'error'
                }));
            });
    }
}