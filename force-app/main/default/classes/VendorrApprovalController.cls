public class VendorrApprovalController {
    
    // Method to get vendors related to the work order's trade
    @AuraEnabled(cacheable=true)
    public static List<Vendor__c> getVendorsForWorkOrder(Id workOrderId) {
        WorkOrder workOrder = [SELECT Id, WorkOrderNumber, Trade__c FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        
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

        // Retrieve the Work Order with its Number field
        WorkOrder workOrder = [SELECT Id, WorkOrderNumber FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        if (workOrder == null) {
            throw new AuraHandledException('Work Order not found.');
        }

        // Check if there is already a pending approval for the work order
        List<ProcessInstance> existingApprovals = [SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = :workOrderId AND Status = 'Pending'];
        if (!existingApprovals.isEmpty()) {
            throw new AuraHandledException('An approval request is already pending for this Work Order.');
        }

        // Collect approval status
        List<VendorApprovalStatus__c> approvalStatuses = new List<VendorApprovalStatus__c>();
        List<Id> approverIds = new List<Id>();

        // Collect approver IDs directly from the Vendor__c records and create initial status records
        for (Vendor__c vendor : [SELECT Name, User__r.Id FROM Vendor__c WHERE Id IN :vendorIds AND User__r.Id != null]) {
            approverIds.add(vendor.User__r.Id);

            VendorApprovalStatus__c approvalStatus = new VendorApprovalStatus__c();
            approvalStatus.Name = 'Approval for WO ' + workOrder.WorkOrderNumber + ' - Vendor ' + vendor.Name;
            approvalStatus.Vendor__c = vendor.Id;
            approvalStatus.Work_Order__c = workOrderId;
            approvalStatus.Approval_Status__c = 'Pending Approval';
            approvalStatuses.add(approvalStatus);
        }

        if (approverIds.isEmpty()) {
            throw new AuraHandledException('No valid approvers found for the selected vendors.');
        }

        insert approvalStatuses;

        // Process each approver individually
        List<Approval.ProcessResult> results = new List<Approval.ProcessResult>();
        for (Id approverId : approverIds) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(workOrderId);
            req.setNextApproverIds(new List<Id>{ approverId });

            try {
                Approval.ProcessResult result = Approval.process(req);
                results.add(result);

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

    // Method to recall existing approval requests if they exist
    @AuraEnabled
    public static void recallExistingApprovalRequest(Id workOrderId) {
        // Query existing pending approval requests for the given work order
        List<ProcessInstance> instances = [
            SELECT Id, Status FROM ProcessInstance WHERE TargetObjectId = :workOrderId AND Status = 'Pending'
        ];

        // If there are pending requests, recall them
        for (ProcessInstance instance : instances) {
            Approval.ProcessWorkitemRequest recallRequest = new Approval.ProcessWorkitemRequest();
            recallRequest.setAction('Removed');
            recallRequest.setWorkitemId(instance.Id);
            Approval.process(recallRequest);
        }
    }

    // Method to get approval status records
    @AuraEnabled(cacheable=true)
    public static List<VendorApprovalStatus__c> getApprovalStatuses(Id workOrderId) {
        return [SELECT Id, Vendor__c, Vendor__r.Name, Approval_Status__c FROM VendorApprovalStatus__c WHERE Work_Order__c = :workOrderId];
	    }
}