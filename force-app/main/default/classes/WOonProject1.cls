/*public with sharing class WOonProject1 {
    
    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getFilteredWorkOrderss(String projectId, String searchQuery) {
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

        String query = 'SELECT Id, WorkOrderNumber, Status, Select__c, Priority, Brand__c,Assign_to_Project__c FROM WorkOrder WHERE Brand__c = :brandValue';
/*        String query = 'SELECT Id, WorkOrderNumber, Status, Select__c, Priority, Brand__c,Assign_to_Project__c FROM WorkOrder WHERE Brand__c = :brandValue AND Id NOT IN :relatedWorkOrderIds';
*/
  /*      
        if (!String.isEmpty(searchQuery)) {
            searchQuery = searchQuery + '%'; // '%' to make it a prefix match
            query += ' AND WorkOrderNumber LIKE :searchQuery'; // use dynamic searchquery variable with appended '%'
        }

        query += ' ORDER BY CreatedDate DESC';
        
        return Database.query(query);
    }
 @AuraEnabled
    public static void addWorkOrdersToProjects(List<Id> workOrderIdsToAdd, List<Id> workOrderIdsToRemove, Id projectId) {
        if (projectId == null) {
            throw new CustomException('Invalid Project ID.');
        }

        if (!workOrderIdsToAdd.isEmpty()) {
            List<WorkOrder> workOrdersToUpdate = [SELECT Id, Project__c, Assign_to_Project__c FROM WorkOrder WHERE Id IN :workOrderIdsToAdd];
            for (WorkOrder wo : workOrdersToUpdate) {
                wo.Project__c = projectId;
                wo.Assign_to_Project__c = true; 
            }
            update workOrdersToUpdate;
        }

        if (!workOrderIdsToRemove.isEmpty()) {
            List<WorkOrder> workOrdersToUpdate = [SELECT Id, Project__c, Assign_to_Project__c FROM WorkOrder WHERE Id IN :workOrderIdsToRemove];
            for (WorkOrder wo : workOrdersToUpdate) {
                wo.Project__c = null; 
                wo.Assign_to_Project__c = false; 
            }
            update workOrdersToUpdate;
        }
    }

    public class CustomException extends Exception {}
}*/

/*For Project Manager*/

public with sharing class WOonProject1 {
    
    @AuraEnabled(cacheable=true)
    public static List<WorkOrder> getFilteredWorkOrderss(String projectId, String searchQuery) {
        if (String.isEmpty(projectId)) {
            throw new CustomException('Project ID is required');
        }

        Project__c project = [SELECT Brand__c, Project_Manager__c FROM Project__c WHERE Id = :projectId LIMIT 1];

        String projectmanagerValue = project.Project_Manager__c;

        List<WorkOrder> relatedWorkOrders = [SELECT Id FROM WorkOrder WHERE Project__c = :projectId];
        Set<Id> relatedWorkOrderIds = new Set<Id>();
        
        for (WorkOrder wo : relatedWorkOrders) {
            relatedWorkOrderIds.add(wo.Id);
        }

        String query = 'SELECT Id, WorkOrderNumber, Status, Select__c, Priority, Brand__c, Corporate__c, Assign_to_Project__c FROM WorkOrder WHERE Corporate__c = :projectmanagerValue';

        
        if (!String.isEmpty(searchQuery)) {
            searchQuery = searchQuery + '%'; // '%' to make it a prefix match
            query += ' AND WorkOrderNumber LIKE :searchQuery'; // use dynamic searchquery variable with appended '%'
        }

        query += ' ORDER BY CreatedDate DESC';
        
        return Database.query(query);
    }
 @AuraEnabled
    public static void addWorkOrdersToProjects(List<Id> workOrderIdsToAdd, List<Id> workOrderIdsToRemove, Id projectId) {
        if (projectId == null) {
            throw new CustomException('Invalid Project ID.');
        }

        if (!workOrderIdsToAdd.isEmpty()) {
            List<WorkOrder> workOrdersToUpdate = [SELECT Id, Project__c, Assign_to_Project__c FROM WorkOrder WHERE Id IN :workOrderIdsToAdd];
            for (WorkOrder wo : workOrdersToUpdate) {
                wo.Project__c = projectId;
                wo.Assign_to_Project__c = true; 
            }
            update workOrdersToUpdate;
        }

        if (!workOrderIdsToRemove.isEmpty()) {
            List<WorkOrder> workOrdersToUpdate = [SELECT Id, Project__c, Assign_to_Project__c FROM WorkOrder WHERE Id IN :workOrderIdsToRemove];
            for (WorkOrder wo : workOrdersToUpdate) {
                wo.Project__c = null; 
                wo.Assign_to_Project__c = false; 
            }
            update workOrdersToUpdate;
        }
    }

    public class CustomException extends Exception {}
}