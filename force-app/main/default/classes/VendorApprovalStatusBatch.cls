global class VendorApprovalStatusBatch implements Database.Batchable<SObject>, Schedulable {
    
    // Start method to query ProcessInstance records where approval status is final (Approved or Rejected)
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, TargetObjectId, Status 
            FROM ProcessInstance 
            WHERE TargetObject.Type = 'WorkOrder' 
            AND Status IN ('Approved', 'Rejected')
        ]);
    }

    // Execute method to process each batch of ProcessInstance records
    global void execute(Database.BatchableContext bc, List<ProcessInstance> processInstances) {
        Set<Id> workOrderIds = new Set<Id>();
        
        // Collect WorkOrder IDs from ProcessInstance records
        for (ProcessInstance pi : processInstances) {
            workOrderIds.add(pi.TargetObjectId);
        }
        
        // Query VendorApprovalStatus__c records linked to these Work Orders
        List<VendorApprovalStatus__c> approvalStatuses = [
            SELECT Id, Work_Order__c, Vendor__c, Approval_Status__c 
            FROM VendorApprovalStatus__c 
            WHERE Work_Order__c IN :workOrderIds
        ];
        
        // Map each WorkOrder to its approval status in ProcessInstance
        Map<Id, String> workOrderApprovalStatusMap = new Map<Id, String>();
        for (ProcessInstance pi : processInstances) {
            workOrderApprovalStatusMap.put(pi.TargetObjectId, pi.Status);
        }

        // Update VendorApprovalStatus__c records based on WorkOrder approval status
        for (VendorApprovalStatus__c status : approvalStatuses) {
            if (workOrderApprovalStatusMap.containsKey(status.Work_Order__c)) {
                status.Approval_Status__c = workOrderApprovalStatusMap.get(status.Work_Order__c) == 'Approved' 
                    ? 'Approved' 
                    : 'Rejected';
            }
        }
        
        // Update VendorApprovalStatus__c records in Salesforce
        if (!approvalStatuses.isEmpty()) {
            update approvalStatuses;
        }
    }

    global void finish(Database.BatchableContext bc) {
        // Optional: Add any final cleanup or logging if needed
    }
    
    // Implement Schedulable interface to schedule this batch job
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new VendorApprovalStatusBatch(), 100); // Setting batch size to 100
    }
}