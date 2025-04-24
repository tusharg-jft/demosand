public class WorkOrderTriggerHandler {
    
    public static void handleAfterInsert(List<Work_Order__c> newWorkOrders) {
        
        try {
            // Query Work Orders with related Brand and Users
            List<Work_Order__c> workOrdersWithRelatedData = [
                SELECT Id, Brand__c, Sites__c, Sites__r.CorpUser__c, Sites__r.BrandUser__c, Sites__r.Site_User__c, Corporate__c 
                , CreatedBy.Profile.Name, CreatedById, Vendor__c, Work_Order_Type__c, Vendor__r.user__c
                FROM Work_Order__c 
                WHERE Id IN :newWorkOrders
            ];
            
            List<Work_Order__Share> sharesToCreate = new List<Work_Order__Share>();
            
            for(Work_Order__c workOrder : workOrdersWithRelatedData) {
                // Corporate Profile user creating record
                if(workOrder.CreatedBy.Profile.Name == 'Corporate Profile') {
                    // Share with Brand User from Brand
                    if(workOrder.Sites__c != null && workOrder.Sites__r.brandUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.brandUser__c));
                    }
                    
                    // Share with Site User
                    if(workOrder.Sites__c != null && workOrder.Sites__r.Site_User__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.Site_User__c));
                    }
                }
                // Brand Profile user creating record
                else if(workOrder.CreatedBy.Profile.Name == 'Brand Profile') {
                    // Share with Corporate User
                    if(workOrder.Sites__c != null && workOrder.Sites__r.CorpUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.CorpUser__c));
                    }
                    
                    // Share with Site User
                    if(workOrder.Sites__c != null && workOrder.Sites__r.Site_User__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.Site_User__c));
                    }
                    
                    if(workOrder.Vendor__c != null && workOrder.Work_Order_Type__c == 'Child'){
                        sharesToCreate.add(SharingHelper.createWorkOrderReadOnlyShare(workOrder.Id, workOrder.vendor__r.User__c));
                    }
                    
                }
                // Site Profile user creating record
                else if(workOrder.CreatedBy.Profile.Name == 'Site Profile') {
                    // Share with Corporate User
                    if(workOrder.Sites__c != null && workOrder.Sites__r.CorpUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.CorpUser__c));
                    }
                    
                    // Share with Brand User
                    if(workOrder.Sites__c != null && workOrder.Sites__r.brandUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.brandUser__c));
                    }
                }
            }
            
            if(!sharesToCreate.isEmpty()) {
                Database.insert(sharesToCreate, false);
            }
        } catch(Exception e) {
            System.debug(e);
            
        }
    }
}