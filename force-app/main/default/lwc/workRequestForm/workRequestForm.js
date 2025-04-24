import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord } from 'lightning/uiRecordApi';
import Id from '@salesforce/user/Id';
import PROFILE_NAME_FIELD from '@salesforce/schema/User.Profile.Name';

// Import Apex methods
import getTrades from '@salesforce/apex/WorkOrderService.getTrades';
import getClassifications from '@salesforce/apex/WorkOrderService.getClassifications';
import getIssues from '@salesforce/apex/WorkOrderService.getIssues';
import getSites from '@salesforce/apex/CalendarController.getSites';
import calculateETA from '@salesforce/apex/WorkOrderService.calculateETA';
import createWorkRequest from '@salesforce/apex/WorkRequestService.createWorkRequest';
import getPriorityOptions from '@salesforce/apex/WorkOrderService.getPriorityOptions';

export default class WorkRequestForm extends NavigationMixin(LightningElement) {
    // User information
    userId = Id;
    userProfileName;
    
    // Loading and error states
    isLoading = true;
    error;
    
    // Form data
    @track tradeOptions = [];
    @track classificationOptions = [];
    @track issueOptions = [];
    @track siteOptions = [];
    @track priorityOptions = [];
    
    // Selected values
    selectedTradeId;
    selectedClassificationId;
    selectedIssueId;
    selectedSiteId;
    selectedPriority;
    originalEta;
    requestedByPerson;
    nte;
    description;
    
    // UI control properties
    get disableClassification() {
        return !this.selectedTradeId;
    }
    
    get disableIssue() {
        return !this.selectedClassificationId;
    }
    
    // Get current user's profile
    @wire(getRecord, { recordId: '$userId', fields: [PROFILE_NAME_FIELD] })
    wiredUser({ error, data }) {
        if (data) {
            this.userProfileName = data.fields.Profile.value.fields.Name.value;
            this.loadInitialData();
        } else if (error) {
            this.error = 'Error loading user profile: ' + this.reduceErrors(error);
            this.isLoading = false;
        }
    }
    
    // Load initial data based on user profile
    loadInitialData() {
        this.loadTrades();
        this.loadSites();
        this.loadPriorityOptions();
        this.isLoading = false;
    }
    
    // Load priority options from Select__c picklist
    loadPriorityOptions() {
        this.isLoading = true;
        getPriorityOptions()
            .then(result => {
                this.priorityOptions = result.map(option => ({
                    label: option.label,
                    value: option.value
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.error = 'Error loading priority options: ' + this.reduceErrors(error);
                this.isLoading = false;
            });
    }
    
    // Load trades based on user profile
    loadTrades() {
        this.isLoading = true;
        getTrades({ userId: this.userId, profileName: this.userProfileName })
            .then(result => {
                this.tradeOptions = result.map(trade => ({
                    label: trade.Name,
                    value: trade.Id
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.error = 'Error loading trades: ' + this.reduceErrors(error);
                this.isLoading = false;
            });
    }
    
    // Load classifications based on selected trade
    loadClassifications() {
        if (!this.selectedTradeId) {
            this.classificationOptions = [];
            this.selectedClassificationId = null;
            return;
        }
        
        this.isLoading = true;
        getClassifications({ tradeId: this.selectedTradeId })
            .then(result => {
                this.classificationOptions = result.map(classification => ({
                    label: classification.Name,
                    value: classification.Id
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.error = 'Error loading classifications: ' + this.reduceErrors(error);
                this.isLoading = false;
            });
    }
    
    // Load issues based on selected classification
    loadIssues() {
        if (!this.selectedClassificationId) {
            this.issueOptions = [];
            this.selectedIssueId = null;
            return;
        }
        
        this.isLoading = true;
        getIssues({ classificationId: this.selectedClassificationId })
            .then(result => {
                this.issueOptions = result.map(issue => ({
                    label: issue.Name,
                    value: issue.Id
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.error = 'Error loading issues: ' + this.reduceErrors(error);
                this.isLoading = false;
            });
    }
    
    // Load sites based on user profile
    loadSites() {
        this.isLoading = true;
        getSites({ userId: this.userId, profileName: this.userProfileName })
            .then(result => {
                this.siteOptions = result.map(site => ({
                    label: site.Name,
                    value: site.Id
                }));
                this.isLoading = false;
            })
            .catch(error => {
                this.error = 'Error loading sites: ' + this.reduceErrors(error);
                this.isLoading = false;
            });
    }
    
    // Calculate ETA based on selected priority
    updateETA() {
        if (!this.selectedPriority) {
            this.originalEta = null;
            return;
        }

        console.log("Just before calling calculate ETA==", { priorityLabel: this.selectedPriority })
        
        calculateETA({ priorityLabel: this.selectedPriority })
            .then(result => {
                this.originalEta = result;
            })
            .catch(error => {
                this.error = 'Error calculating ETA: ' + this.reduceErrors(error);
            });
    }
    
    // Event handlers
    handleTradeChange(event) {
        this.selectedTradeId = event.detail.value;
        this.loadClassifications();
    }
    
    handleClassificationChange(event) {
        this.selectedClassificationId = event.detail.value;
        this.loadIssues();
    }
    
    handleIssueChange(event) {
        this.selectedIssueId = event.detail.value;
    }
    
    handleSiteChange(event) {
        this.selectedSiteId = event.detail.value;
    }
    
    handlePriorityChange(event) {
        this.selectedPriority = event.detail.value;
        this.updateETA();
    }
    
    handleRequestedByPersonChange(event) {
        this.requestedByPerson = event.detail.value;
    }
    
    handleNteChange(event) {
        this.nte = event.detail.value;
    }
    
    handleDescriptionChange(event) {
        this.description = event.detail.value;
    }
    
    handleCancel() {
        // Navigate back to the Work Order list view
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Work_Order__c',
                actionName: 'list'
            }
        });
    }
    
    handleSave() {
        // Validate required fields
        if (!this.validateForm()) {
            return;
        }
        
        this.isLoading = true;
        
        // Prepare work order data
        const workOrderRequestData = {
            Trade__c: this.selectedTradeId,
            Classification__c: this.selectedClassificationId,
            Issue__c: this.selectedIssueId,
            Sites__c: this.selectedSiteId,
            Select__c: this.selectedPriority,
            Original_ETA__c: this.originalEta,
            Requested_By_Person__c: this.requestedByPerson,
            NTE__c: Number(this.nte),
            Description__c: this.description
        };
        
        // Create work order
        createWorkRequest({ workOrderRequestData })
            .then(result => {
                this.isLoading = false;
                
                // Show success toast
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Work Order Reqeust created successfully',
                        variant: 'success'
                    })
                );
                
                // Navigate to the new record
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: result,
                        objectApiName: 'Work_Order_Request__c',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.isLoading = false;
                this.error = 'Error creating Work Order: ' + this.reduceErrors(error);
            });
    }
    
    // Validate form fields based on profile
    validateForm() {
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox, lightning-textarea')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        
        if (!allValid) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Please fill in all required fields',
                    variant: 'error'
                })
            );
        }
        
        return allValid;
    }
    
    // Helper to determine if submit button should be disabled
    get isSubmitDisabled() {
        if (this.isCorporateOrBrandProfile) {
            return !this.selectedTradeId || !this.selectedSiteId || !this.selectedPriority ||
                   (this.isCorporateProfile && !this.nte);
        } else if (this.isSiteProfile) {
            return !this.selectedTradeId || !this.selectedSiteId || !this.description || !this.requestedByPerson;
        }
        return true;
    }
    
    // Profile-based getters
    get isCorporateProfile() {
        return this.userProfileName === 'Corporate Profile';
    }
    
    get isBrandProfile() {
        return this.userProfileName === 'Brand Profile';
    }
    
    get isSiteProfile() {
        return this.userProfileName === 'Site Profile';
    }
    
    get isCorporateOrBrandProfile() {
        return this.isCorporateProfile || this.isBrandProfile;
    }
    
    // Helper method to reduce errors
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }
        
        return errors
            .filter(error => !!error)
            .map(error => {
                if (typeof error === 'string') {
                    return error;
                } else if (error.body && typeof error.body.message === 'string') {
                    return error.body.message;
                } else if (error.message) {
                    return error.message;
                }
                return JSON.stringify(error);
            })
            .join(', ');
    }
}