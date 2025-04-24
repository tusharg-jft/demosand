public with sharing class VendorApprovalController2 {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getVendorsForWorkOrder(Id workOrderId) {
        WorkOrder workOrder = [
            SELECT Id, Trade__c, Site_Name__c, Sites__c
            FROM WorkOrder 
            WHERE Id = :workOrderId 
            LIMIT 1
        ];
        
        if (workOrder == null || workOrder.Trade__c == null) {
            return new List<Map<String, Object>>(); 
        }
        
        Set<Id> preferredVendorIds = new Set<Id>();
        Map<String, Boolean> autoAssignFlags = new Map<String, Boolean>();
        if (workOrder.Site_Name__c != null) {
            Sites__c site = [
                SELECT Primary_Vendor__c, Secondary_Vendor__c, Tertiary_Vendor__c, Auto_Assign_Primary_Vendor__c, Auto_Assign_Secondary_Vendor__c, Auto_Assign_Tertiary_Vendor__c 
                FROM Sites__c 
                WHERE Id = :workOrder.Sites__c 
                LIMIT 1
            ];
            if (site != null) {
                if (site.Primary_Vendor__c != null) preferredVendorIds.add(site.Primary_Vendor__c);
                if (site.Secondary_Vendor__c != null) preferredVendorIds.add(site.Secondary_Vendor__c);
                if (site.Tertiary_Vendor__c != null) preferredVendorIds.add(site.Tertiary_Vendor__c);
            }
        }
        
        List<TradeVendor__c> tradeVendors = [
            SELECT Vendor__r.Name, Vendor__r.Id 
            FROM TradeVendor__c 
            WHERE Trade__c = :workOrder.Trade__c 
            AND Vendor__r.User__c != null 
            AND Vendor__r.IsActive__c = true
        ];
        
        Set<Id> vendorIds = new Set<Id>();
        for (TradeVendor__c tradeVendor : tradeVendors) {
            vendorIds.add(tradeVendor.Vendor__r.Id);
        }
        
        if (!preferredVendorIds.isEmpty()) {
            vendorIds.retainAll(preferredVendorIds);
        }
        
        if (vendorIds.isEmpty()) {
            return new List<Map<String, Object>>(); 
        }
        
        Map<Id, String> vendorApprovalStatuses = new Map<Id, String>();
        List<VendorApprovalStatus__c> approvalStatuses = [
            SELECT Vendor__c, Approval_Status__c 
            FROM VendorApprovalStatus__c 
            WHERE Vendor__c IN :vendorIds 
            AND Work_Order__c = :workOrderId
        ];
        
        for (VendorApprovalStatus__c approvalStatus : approvalStatuses) {
            vendorApprovalStatuses.put(approvalStatus.Vendor__c, approvalStatus.Approval_Status__c);
        }
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (TradeVendor__c tradeVendor : tradeVendors) {
            if (vendorIds.contains(tradeVendor.Vendor__r.Id)) {
                Map<String, Object> vendorData = new Map<String, Object>();
                Vendor__c vendor = tradeVendor.Vendor__r;
                
                vendorData.put('Id', vendor.Id);
                vendorData.put('Name', vendor.Name);
                vendorData.put('vendorUrl', '/lightning/r/Vendor__c/' + vendor.Id + '/view');
                vendorData.put('Approval_Status__c', vendorApprovalStatuses.get(vendor.Id) != null ? vendorApprovalStatuses.get(vendor.Id) : 'Not Submitted');
                
                result.add(vendorData);
            }
        }
        
        return result;
    }
    @AuraEnabled
    public static void submitApprovalProcess(List<Id> vendorIds, Id workOrderId) {
        if (vendorIds == null || vendorIds.isEmpty()) {
            throw new AuraHandledException('No vendors selected for approval.');
        }
        
        if (workOrderId == null) {
            throw new AuraHandledException('Invalid Work Order ID.');
        }
        
        WorkOrder workOrder = [
            SELECT Id, WorkOrderNumber,Trade__c, NTE__c
            FROM WorkOrder 
            WHERE Id = :workOrderId 
            LIMIT 1
        ];
        
        if (workOrder == null) {
            throw new AuraHandledException('Work Order not found.');
        }
        
        List<Vendor__c> vendors = [
            SELECT Id, Name, User__r.Id 
            FROM Vendor__c 
            WHERE Id IN :vendorIds
        ];
        
        Set<Id> approverIds = new Set<Id>();
        List<VendorApprovalStatus__c> approvalStatuses = new List<VendorApprovalStatus__c>();
        List<VendorWO__c> vendorWORecords = new List<VendorWO__c>();
        
        for (Vendor__c vendor : vendors) {
            if (vendor.User__r != null) {
                approverIds.add(vendor.User__r.Id);
                
                VendorApprovalStatus__c approvalStatus = new VendorApprovalStatus__c();
                approvalStatus.Name = 'Approval for WO ' + workOrder.WorkOrderNumber + ' - Vendor ' + vendor.Name;
                approvalStatus.Vendor__c = vendor.Id;
                approvalStatus.Work_Order__c = workOrder.Id;
                approvalStatus.Approval_Status__c = 'Pending Approval';
                approvalStatuses.add(approvalStatus);
                
                VendorWO__c vendorWO = new VendorWO__c();
                vendorWO.Vendor__c = vendor.Id;
                vendorWO.Work_Order__c = workOrder.Id;
                //  vendorWO.NTE__c = workOrder.NTE__c; // Set NTE value
                vendorWo.Trade__c = workOrder.Trade__c;
                vendorWORecords.add(vendorWO);
            }
        }
        
        // If no valid vendors are found, throw an exception
        if (approverIds.isEmpty()) {
            throw new AuraHandledException('No valid vendors with approvers found.');
        }
        
        if (!approvalStatuses.isEmpty()) {
            insert approvalStatuses;
        }
        
        if (!vendorWORecords.isEmpty()) {
            insert vendorWORecords;
        }
        
        try {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setObjectId(workOrderId);
            req.setNextApproverIds(new List<Id>(approverIds));
            
            Approval.ProcessResult result = Approval.process(req);
            
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
    
    
    // @InvocableMethod
    @AuraEnabled
    public static void autoAssignPreferredVendors(List<Id> workOrderIds) {
        if (workOrderIds == null || workOrderIds.isEmpty()) {
            throw new AuraHandledException('Invalid Work Order IDs.');
        }
        
        List<WorkOrder> workOrders = [ SELECT Id, Trade__c, Site_Name__c, Sites__c FROM WorkOrder WHERE Id IN :workOrderIds];
        
        if (workOrders.isEmpty()) {
            throw new AuraHandledException('No valid Work Orders found');
        }
        
        Set<Id> siteIds = new Set<Id>();
        for (WorkOrder wo : workOrders) {
            if (wo.Sites__c != null) {
                siteIds.add(wo.Sites__c);
            }
        }
        
        Map<Id, Sites__c> siteMap = new Map<Id, Sites__c>( [SELECT Id, Primary_Vendor__c, Secondary_Vendor__c, Tertiary_Vendor__c, Auto_Assign_Primary_Vendor__c, Auto_Assign_Secondary_Vendor__c, Auto_Assign_Tertiary_Vendor__c 
                                                            FROM Sites__c WHERE Id IN :siteIds]);
        
        for (WorkOrder wo : workOrders) {
            Sites__c site = siteMap.get(wo.Sites__c);
            
            if (site != null) {
                List<Id> autoAssignVendorIds = new List<Id>();
                
                if (site.Primary_Vendor__c != null && site.Auto_Assign_Primary_Vendor__c == true) {
                    autoAssignVendorIds.add(site.Primary_Vendor__c);
                }
                if (site.Secondary_Vendor__c != null && site.Auto_Assign_Secondary_Vendor__c == true) {
                    autoAssignVendorIds.add(site.Secondary_Vendor__c);
                }
                if (site.Tertiary_Vendor__c != null && site.Auto_Assign_Tertiary_Vendor__c == true) {
                    autoAssignVendorIds.add(site.Tertiary_Vendor__c);
                }
                
                if (!autoAssignVendorIds.isEmpty()) {
                    System.debug('Auto-Assigning Vendors: ' + autoAssignVendorIds);
                    submitApprovalProcess(autoAssignVendorIds, wo.Id);
                } else {
                    System.debug('No vendors met the auto-assign condition for Work Order: ' + wo.Id);
                }
            }
        }
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<VendorApprovalStatus__c> getApprovalStatuses(Id workOrderId) {
        return [SELECT Id, Vendor__c, Vendor__r.Name, Approval_Status__c FROM VendorApprovalStatus__c WHERE Work_Order__c = :workOrderId];
    }   
}