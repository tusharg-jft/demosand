public class SubmitApprovalController {
    public List<Id> selectedVendorIds { get; set; }  // List of selected vendor IDs
    public List<SelectOption> vendorOptions { get; set; }
    public WorkOrder workOrder { get; set; }

    // Constructor to get the Work Order from the standard controller and load vendor options
    public SubmitApprovalController(ApexPages.StandardController stdController) {
        this.workOrder = (WorkOrder) stdController.getRecord();
        loadVendorOptions();
    }

    // Fetch vendors associated with the trade in the work order
    public void loadVendorOptions() {
        vendorOptions = new List<SelectOption>();

        // Make sure to query for the Trade__c field to avoid the error
        WorkOrder workOrderWithTrade = [
            SELECT Id, Trade__c
            FROM WorkOrder
            WHERE Id = :workOrder.Id
            LIMIT 1
        ];

        // Get the trade connected to the work order
        Id tradeId = workOrderWithTrade.Trade__c; // Now you can safely access the Trade__c field

        // Query the TradeVendor junction object to get the vendors for the trade
        List<TradeVendor__c> tradeVendors = [
            SELECT Vendor__r.Name, Vendor__r.Id 
            FROM TradeVendor__c 
            WHERE Trade__c = :tradeId
        ];

        // Add each vendor as an option in the select list
        for (TradeVendor__c tradeVendor : tradeVendors) {
            vendorOptions.add(new SelectOption(tradeVendor.Vendor__r.Id, tradeVendor.Vendor__r.Name));
        }
    }

    // Submit the Work Order for approval
    public PageReference submitForApproval() {
        if (selectedVendorIds != null && !selectedVendorIds.isEmpty()) {
            // Fetch the associated User Ids for the selected vendors
            List<Id> approverIds = new List<Id>();

            // Fetch the User IDs associated with the selected vendors
            List<Vendor__c> selectedVendors = [
                SELECT User__r.Id 
                FROM Vendor__c 
                WHERE Id IN :selectedVendorIds
            ];

            // Add the User Ids to the approverIds list
            for (Vendor__c vendor : selectedVendors) {
                approverIds.add(vendor.User__r.Id);  // Add User Id to the list
            }

            // Create the Approval Process submission request
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(workOrder.Id);  // Submit Work Order for approval
            req.setNextApproverIds(approverIds);  // Set the approvers' User Ids

            // Process the approval request
            Approval.ProcessResult result = Approval.process(req);

            // Check the result and show a message
            if (result.isSuccess()) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Approval submitted successfully.'));
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Approval submission failed.'));
            }
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one vendor to approve.'));
        }

        return null;  // Stay on the current page
    }
}