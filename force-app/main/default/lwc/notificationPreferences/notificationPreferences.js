import { LightningElement, wire, track } from 'lwc';
import getPreferences from '@salesforce/apex/NotificationPreferenceController.getPreferences';
import updatePreference from '@salesforce/apex/NotificationPreferenceController.updatePreference';

export default class NotificationPreferences extends LightningElement {
    @track preferences = [];
    @track filteredPreferences = [];
    searchKey = '';

    helpTextMap = {
        'Trip Started': 'Track the progress of your technician. Get real-time notifications when a technician starts a trip for your workOrder',
        'New WO Assign To Project': 'Get WO notification',
        'Work Order Approval From Brand': 'Get WO approval from brand notification',
        'A New Technician Added to Trip': 'Get notified as soon as vendor users added a new technician to trip',
        'New Work Order Created': 'Stay Informed when brands create new work',
        'Return Visit Scheduled': 'Stay informed when technician scheduled a revisit',
        'Trip Assign' : 'Stay infromed when a new trip is assigned',
        'Trip Ended' : 'Stay informed when a trip ends',
        'Work Order Acceptance by Vendor' : 'Get notified when a wo is approved by vendor',
        'Work Order Assigned to Vendor': 'Get notified when a wo is assigned to vendor',
        'Work Order Modified' : 'Get notified when a work order is modified',
        'Work Order Reassigned to Vendor' : 'Get notified when a work order is Reassigned to vendor',
        'Work Order Rejection by Vendor' : 'Get notified when a work order is rejected by vendor',
        'Work Request Approved' : 'Get notified when a work request is approved by vendor',
        'Work Request Rejected' : 'Get notified when a work request is rejected',
      };

    @wire(getPreferences)
    wiredPreferences({ data, error }) {
        if (data) {
            this.preferences = data.map(pref => ({
                ...pref,
                EmailNotificationEnabled: pref.EmailNotificationEnabled, 
                PushNotificationEnabled: pref.PushNotificationEnabled, 
                helpText: this.getHelpText(pref.Name)
            }));
            this.filteredPreferences = [...this.preferences];
        } else if (error) {
            console.error('Error fetching preferences:', error);
        }
    }

    handleToggleChange(event) {
        const id = event.target.dataset.id;
        const type = event.target.dataset.type;
        const enabled = event.target.checked;

        const emailToggle = this.template.querySelector(`[data-id="${id}"][data-type="email"]`).checked;
        const pushToggle = this.template.querySelector(`[data-id="${id}"][data-type="push"]`).checked;

        updatePreference({
            prefId: id,
            type: type,
            enabled: enabled,
            emailValue: emailToggle,
            pushValue: pushToggle
        })
        .then(() => {
            return this.refreshPreferences();
        })
        .catch(error => {
            console.error('Error updating preference:', error);
        });
    }

    handleSearch(event) {
        this.searchKey = event.target.value.toLowerCase();
        this.filteredPreferences = this.preferences.filter(pref =>
            pref.Name.toLowerCase().includes(this.searchKey)
        );
    }

    refreshPreferences() {
        getPreferences()
            .then(data => {
                this.preferences = data.map(pref => ({
                    ...pref,
                    EmailNotificationEnabled: pref.EmailNotificationEnabled, 
                    PushNotificationEnabled: pref.PushNotificationEnabled, 
                    helpText: this.getHelpText(pref.Name)
                }));
                this.filteredPreferences = [...this.preferences]; 
            })
            .catch(error => {
                console.error('Error refreshing preferences:', error);
            });
    }

    getHelpText(prefName) {
        return this.helpTextMap[prefName] || ''; 
    }
}