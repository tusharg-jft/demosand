import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class PreferredVendorComponent extends NavigationMixin(LightningElement) {
    handleCloneClick() {
        this.launchFlow('Preferred_Vendor');
    }

    handleAddClick() {
        this.launchFlow('new_flow');
    }

    launchFlow(flowName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__flow',
            attributes: {
                flowApiName: flowName
            }
        });
    }
}