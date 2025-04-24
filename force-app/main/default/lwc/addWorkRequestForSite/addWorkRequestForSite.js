import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class AddWorkRequestForSite extends NavigationMixin(LightningElement) {
    createWorkRequest() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'WorkOrder_Request__c',
                actionName: 'new',
            }
        });
    }
}