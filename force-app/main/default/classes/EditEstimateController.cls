public with sharing class EditEstimateController {
    
    @AuraEnabled(cacheable=true)
    public static Object getLatestEstimateData(Id workOrderId) {
        
        // Return an empty list if workOrderId is null
        if (workOrderId == null) {
            return new List<Estimate__c>();
        }
        
        // Query the latest Estimate record related to the Work Order
        Estimate__c estimate = [
            SELECT Id, Estimate_Data__c
            FROM Estimate__c
            WHERE Work_Orders__c = :workOrderId
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        // Return the list (it could be empty or contain 1 record)
        return estimate.Estimate_Data__c;
    }
}