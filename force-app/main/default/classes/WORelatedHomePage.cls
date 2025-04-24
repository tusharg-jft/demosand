public with sharing class WORelatedHomePage {
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getDashboardData() {
        Map<String, Integer> dashboardData = new Map<String, Integer>();
        
        try {
            Integer pendingWorkRequestsCount = [SELECT COUNT() FROM Work_Order__c WHERE Status__c = 'Pending'];
            dashboardData.put('PENDING REQUEST', pendingWorkRequestsCount);

            Integer activeWorkOrdersCount = [SELECT COUNT() FROM Work_Order__c WHERE Status__c = 'Active'];
            dashboardData.put('ACTIVE WORK ORDERS', activeWorkOrdersCount);

            Integer pendingEstimatesCount = [SELECT COUNT() FROM Estimate__c WHERE Status__c = 'Pending'];
            dashboardData.put('PENDING ESTIMATES', pendingEstimatesCount);

            Integer pendingInvoicesCount = [SELECT COUNT() FROM Invoice__c WHERE Status__c = 'Pending'];
            dashboardData.put('PENDING INVOICES', pendingInvoicesCount);

            Integer overdueWorkOrdersCount = [SELECT COUNT() FROM Work_Order__c WHERE Original_ETA__c < TODAY];
            dashboardData.put('OVERDUE WORK ORDERS', overdueWorkOrdersCount);

            Integer emergencyWorkOrdersCount = [SELECT COUNT() FROM Work_Order__c WHERE Select__c = 'P2 - Priority 2 hours'];
            dashboardData.put('EMERGENCY WORK ORDERS', emergencyWorkOrdersCount);
        } catch (Exception e) {
            System.debug('Error in fetching dashboard data: ' + e.getMessage());
        }

        return dashboardData;
    }
}