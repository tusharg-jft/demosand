public class VendorApprovalController1 {

    // Method to get vendors related to the work order's trade
    @AuraEnabled(cacheable=true)
    public static List<Vendor__c> getVendorsForWorkOrder(Id workOrderId) {
        WorkOrder workOrder = [SELECT Id, Trade__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        
        if (workOrder != null && workOrder.Trade__c != null) {
            // Query the TradeVendor junction object to get the list of vendors for the trade
            List<TradeVendor__c> tradeVendors = [SELECT Vendor__r.Name, Vendor__r.Id FROM TradeVendor__c WHERE Trade__c = :workOrder.Trade__c AND Vendor__r.User__c != null AND Vendor__r.IsActive__c = true];
            
            // Collect the vendors into a list
            List<Vendor__c> vendors = new List<Vendor__c>();
            for (TradeVendor__c tradeVendor : tradeVendors) {
                vendors.add(tradeVendor.Vendor__r);
            }
            return vendors;
        }
        
        return new List<Vendor__c>();  // Return an empty list if no trade is found
    }

    // Method to submit approval to the selected vendors' users
    @AuraEnabled
    public static void submitApprovalProcess(List<Id> vendorIds, Id workOrderId) {
    if (vendorIds == null || vendorIds.isEmpty()) {
        throw new AuraHandledException('No vendors selected for approval.');
    }
    
    if (workOrderId == null) {
        throw new AuraHandledException('Invalid Work Order ID.');
    }

    // Collect approver IDs directly from the Vendor__c records
    List<Id> approverIds = new List<Id>();
    for (Vendor__c vendor : [SELECT User__r.Id FROM Vendor__c WHERE Id IN :vendorIds AND User__r.Id != null]) {
        approverIds.add(vendor.User__r.Id);
    }
    
    if (approverIds.isEmpty()) {
        throw new AuraHandledException('No valid approvers found for the selected vendors.');
    }

    try {
        // Approval submission setup
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(workOrderId);
        req.setNextApproverIds(approverIds);

        // Process the approval request
        Approval.ProcessResult result = Approval.process(req);

        // Capture any specific errors from the result
        if (!result.isSuccess()) {
            String errors = 'Approval submission failed due to: ';
            for (Database.Error error : result.getErrors()) {
                errors += error.getStatusCode() + ' - ' + error.getMessage() + '; ';
            }
            throw new AuraHandledException(errors);
        }

    } catch (Exception e) {
        throw new AuraHandledException('Approval submission failed: ' + e.getMessage());
    }
}
}