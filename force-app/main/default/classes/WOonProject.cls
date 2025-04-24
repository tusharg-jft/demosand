public with sharing class WOonProject {
    
    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getFilteredWorkOrders(String projectId, String searchQuery) {
        if (String.isEmpty(projectId)) {
            throw new CustomException('Project ID is required');
        }

        Project__c project = [SELECT Brand__c FROM Project__c WHERE Id = :projectId LIMIT 1];

        String brandValue = project.Brand__c;

        List<WorkOrder> relatedWorkOrders = [SELECT Id FROM WorkOrder WHERE Project__c = :projectId];
        Set<Id> relatedWorkOrderIds = new Set<Id>();
        
        for (WorkOrder wo : relatedWorkOrders) {
            relatedWorkOrderIds.add(wo.Id);
        }

        String query = 'SELECT Id, WorkOrderNumber, Status, Select__c, Priority, Brand__c FROM WorkOrder WHERE Brand__c = :brandValue AND Id NOT IN :relatedWorkOrderIds';
        
        if (!String.isEmpty(searchQuery)) {
            searchQuery = searchQuery + '%'; // '%' to make it a prefix match
            query += ' AND WorkOrderNumber LIKE :searchQuery'; // Use dynamic searchQuery variable with appended '%'
        }

        query += ' ORDER BY CreatedDate DESC';
        
        return Database.query(query);
    }

    @AuraEnabled
    public static void addWorkOrdersToProject(List<Id> workOrderIds, Id projectId) {
        if (workOrderIds.isEmpty() || projectId == null) {
            throw new CustomException('No WorkOrders selected or invalid Project.');
        }

        List<WorkOrder> workOrdersToUpdate = [SELECT Id, Project__c FROM WorkOrder WHERE Id IN :workOrderIds];

        for (WorkOrder wo : workOrdersToUpdate) {
            wo.Project__c = projectId;
        }

        update workOrdersToUpdate;
    }
    
    public class CustomException extends Exception {}
}