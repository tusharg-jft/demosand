import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getDashboardData from '@salesforce/apex/WORelatedHomePage.getDashboardData';

export default class WorkDashboard extends NavigationMixin(LightningElement) {
    dashboardData = [];

    @wire(getDashboardData)
    wiredDashboardData({ error, data }) {
        if (data) {
            console.log('Dashboard Data:', data); 
            this.dashboardData = Object.keys(data).map((key) => ({
                title: key,
                count: data[key],
                icon: this.getIconForTitle(key),
                handler: () => this.handleView(key),
            }));
        } else if (error) {
            console.error('Error fetching dashboard data', error);
        }
    }

    getIconForTitle(title) {
        const iconMap = {
            'PENDING REQUEST': 'utility:capacity_plan',
            'ACTIVE WORK ORDERS': 'utility:date_input',
            'PENDING ESTIMATES': 'utility:task',
            'PENDING INVOICES': 'utility:moneybag',
            'OVERDUE WORK ORDERS': 'utility:work_order_type',
            'EMERGENCY WORK ORDERS': 'utility:pricing_workspace',
        };
       return iconMap[title] || 'utility:capacity_plan'; 
    }

    handleView(title) {
        let objectApiName;
        let filterName;

        switch (title) {
            case 'PENDING REQUEST':
                objectApiName = 'Work_Order__c';
                filterName = 'Pending_Work_Request';
                break;
            case 'ACTIVE WORK ORDERS':
                objectApiName = 'Work_Order__c';
                filterName = 'Active_Work_Orders';
                break;
            case 'PENDING ESTIMATES':
                objectApiName = 'Estimate__c';
                filterName = 'Pending_Estimates';
                break;
            case 'PENDING INVOICES':
                objectApiName = 'Invoice__c';
                filterName = 'Pending_Invoices';
                break;
            case 'EMERGENCY WORK ORDERS':
                objectApiName = 'Work_Order__c';
                filterName = 'Emergency_Work_Orders';
                break;
            case 'OVERDUE WORK ORDERS':
                objectApiName = 'Work_Order__c';
                filterName = 'Overdue_Work_Orders';
                break;
            default:
                console.warn('No navigation handler for title:', title);
                return;
        }

        this[NavigationMixin.Navigate]( {
            type: 'standard__objectPage',
            attributes: {
                objectApiName,
                actionName: 'list',
            },
            state: {
                filterName,
            },
        });
    }
}