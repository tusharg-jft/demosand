public class WorkOrderTriggerHandler {
    public static void handleAfterInsert(List<Work_Order__c> newWorkOrders) {
        try {
            // Query Work Orders with related data for both sharing and auto-assignment
            List<Work_Order__c> workOrdersWithRelatedData = [
                SELECT Id, Brand__c, Sites__c, Sites__r.CorpUser__c, Sites__r.BrandUser__c, 
                       Sites__r.Site_User__c, Corporate__c, CreatedBy.Profile.Name, CreatedById, 
                       Vendor__c, Work_Order_Type__c, Vendor__r.User__c, Trade__c,
                       Description__c, Select__c, Original_ETA__c, Classification__c, 
                       Issue__c, NTE__c, Request_By_Person__c , Request_Status__c
                FROM Work_Order__c 
                WHERE Id IN :newWorkOrders
            ];
            
            // Handle existing sharing logic
            List<Work_Order__Share> sharesToCreate = new List<Work_Order__Share>();
            for (Work_Order__c workOrder : workOrdersWithRelatedData) {
                if (workOrder.CreatedBy.Profile.Name == 'Corporate Profile') {
                    if (workOrder.Sites__c != null && workOrder.Sites__r.BrandUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.BrandUser__c));
                    }
                    if (workOrder.Sites__c != null && workOrder.Sites__r.Site_User__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.Site_User__c));
                    }
                }
                else if (workOrder.CreatedBy.Profile.Name == 'Brand Profile') {
                    if (workOrder.Sites__c != null && workOrder.Sites__r.CorpUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.CorpUser__c));
                    }
                    if (workOrder.Sites__c != null && workOrder.Sites__r.Site_User__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.Site_User__c));
                    }
                    if (workOrder.Vendor__c != null && workOrder.Work_Order_Type__c == 'Child') {
                        sharesToCreate.add(SharingHelper.createWorkOrderReadOnlyShare(workOrder.Id, workOrder.Vendor__r.User__c));
                    }
                }
                else if (workOrder.CreatedBy.Profile.Name == 'Site Profile') {
                    if (workOrder.Sites__c != null && workOrder.Sites__r.CorpUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.CorpUser__c));
                    }
                    if (workOrder.Sites__c != null && workOrder.Sites__r.BrandUser__c != null) {
                        sharesToCreate.add(SharingHelper.createWorkOrderShare(workOrder.Id, workOrder.Sites__r.BrandUser__c));
                    }
                  
                }
            }
            
            if (!sharesToCreate.isEmpty()) {
                System.debug('Inserting ' + sharesToCreate.size() + ' sharing records');
                Database.insert(sharesToCreate, false);
            }

            // Call the auto-assignment method
            handleAutoAssignment(workOrdersWithRelatedData);
            
            System.debug('handleAfterInsert completed successfully for Work Orders: ' + newWorkOrders);
        } catch (Exception e) {
            System.debug('Error in handleAfterInsert: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
    }

    private static void handleAutoAssignment(List<Work_Order__c> workOrders) {
        Work_Order__c workOrder = workOrders[0]; // Assuming only one Work Order is passed for auto-assignment
        System.debug('Starting handleAutoAssignment for Work Order: ' + workOrder.Id);
        
        // Check if the Work Order has required fields
        if (workOrder.Sites__c == null || workOrder.Trade__c == null) {
            System.debug('No valid Work Order with Sites__c and Trade__c for auto-assignment: ' + workOrder.Id);
            return;
        }
    
    
        if( workOrder.Request_Status__c != 'Approved' && workOrder.Request_Status__c != 'Pending' ) {
            System.debug('Work Order is not in a valid status for auto-assignment: ' + workOrder.Request_Status__c);
            return;
        }
    
        // Query the preferred vendor for this Site and Trade
        Preferred_Trade_Vendor__c preferredVendor;
        try {
            preferredVendor = [
                SELECT Id, Sites__c, Trade__c, Vendor__c, Auto_Assign__c, Priority__c, Vendor__r.User__c
                FROM Preferred_Trade_Vendor__c
                WHERE Sites__c = :workOrder.Sites__c
                  AND Trade__c = :workOrder.Trade__c
                  AND Auto_Assign__c = true
                ORDER BY Priority__c ASC
                LIMIT 1
            ];
            System.debug('Preferred Vendor found: ' + preferredVendor);
        } catch (QueryException e) {
            System.debug('No preferred vendors found for Site: ' + workOrder.Sites__c + ', Trade: ' + workOrder.Trade__c);
            return;
        }
    
        // Fetch the Work Order record from the database using the workOrder.Id
        Work_Order__c parentWorkOrder = [
            SELECT Id, Trade__c, Sites__c, Description__c, Select__c, Original_ETA__c, 
                   Classification__c, Issue__c, NTE__c, Request_By_Person__c , Original_NTE__c
            FROM Work_Order__c
            WHERE Id = :workOrder.Id
            LIMIT 1
        ];
        System.debug('Fetched parent Work Order from database: ' + parentWorkOrder);

        Id recordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE DeveloperName = 'Child_Work_Order' 
                  AND SObjectType = 'Work_Order__c' 
                LIMIT 1
            ].Id;
    
        // Create a single child Work Order using the fetched parent Work Order
        Work_Order__c childWorkOrder = new Work_Order__c(
            RecordTypeId = recordTypeId,
            ParentWO__c = parentWorkOrder.Id,
            Vendor__c = preferredVendor.Vendor__c, // Same vendor as in VendorWO__c
            Trade__c = parentWorkOrder.Trade__c,
            Sites__c = parentWorkOrder.Sites__c,
            Description__c = parentWorkOrder.Description__c,
            Select__c = parentWorkOrder.Select__c,
            Original_ETA__c = parentWorkOrder.Original_ETA__c,
            Classification__c = parentWorkOrder.Classification__c,
            Issue__c = parentWorkOrder.Issue__c,
            NTE__c = parentWorkOrder.NTE__c,
            Original_NTE__c = parentWorkOrder.Original_NTE__c,
            Request_By_Person__c = parentWorkOrder.Request_By_Person__c,
            Status__c = 'Pending Vendor Approval',
            Work_Order_Type__c = 'Child'
        );
        System.debug('Child Work Order to insert: ' + childWorkOrder);
        
        try {
            // Insert the child Work Order first so that its Id is generated
            System.debug('Inserting child Work Order');
            insert childWorkOrder;
            System.debug('Successfully inserted child Work Order: ' + childWorkOrder.Id);
            
            // Now that childWorkOrder.Id is available, create the VendorWO__c record
            VendorWO__c vendorWO = new VendorWO__c(
                Vendor__c = preferredVendor.Vendor__c,
                Related_Work_Order__c = childWorkOrder.Id,
                Trade__c = workOrder.Trade__c,
                Status__c = 'Pending'
            );
            System.debug('VendorWO__c to insert: ' + vendorWO);
            
            // Insert the VendorWO__c record
            System.debug('Inserting VendorWO__c record');
            insert vendorWO;
            System.debug('Successfully inserted VendorWO__c record: ' + vendorWO.Id);
        

            applySharing(new List<Work_Order__c>{childWorkOrder});
            System.debug('Sharing applied for child Work Order: ' + childWorkOrder.Id);
            // Apply sharing logic for the vendor (same as handleAfterInsert)
            List<Work_Order__Share> sharesToCreate = new List<Work_Order__Share>();
            if (preferredVendor.Vendor__c != null && preferredVendor.Vendor__r.User__c != null && childWorkOrder.Work_Order_Type__c == 'Child') {
                sharesToCreate.add(SharingHelper.createWorkOrderReadOnlyShare(childWorkOrder.Id, preferredVendor.Vendor__r.User__c));
            }
        
            if (!sharesToCreate.isEmpty()) {
                System.debug('Inserting ' + sharesToCreate.size() + ' sharing records for child Work Order');
                Database.insert(sharesToCreate, false);
            }
        
            // Query the vendor for notification
            Vendor__c vendor = [
                SELECT Id, User__c
                FROM Vendor__c
                WHERE Id = :preferredVendor.Vendor__c
                LIMIT 1
            ];
            System.debug('Vendor for notification: ' + vendor);

            Work_Order__c childWorkOrderForNotification = [
                SELECT Id, Name
                FROM Work_Order__c
                WHERE Id = :childWorkOrder.Id
                LIMIT 1
            ];
            
            
            // Send notification if vendor has a user
            if (vendor != null && vendor.User__c != null) {
                String messageBody = 'Work Order '+childWorkOrderForNotification.Name+' has been auto-assigned to you';
                
                String messageTitle = 'Work Order Assignment';
                NotificationUtility.sendNotification(
                    'WOAssignTOVendorNotification',
                    new List<Id> { vendor.User__c },
                    childWorkOrder.Id, // Target the child Work Order
                    messageBody,
                    messageTitle
                );
                System.debug('Notification sent to vendor user: ' + vendor.User__c + ' for Child Work Order: ' + childWorkOrder.Id);
            } else {
                System.debug('Vendor or Vendor User is null for Vendor Id: ' + preferredVendor.Vendor__c);
            }
        
        } catch (DmlException e) {
            System.debug('Error in handleAutoAssignment: ' + e.getMessage() + ' | Line: ' + e.getLineNumber());
        }
        
        System.debug('handleAutoAssignment completed successfully');
    }
    

    private static void applySharing(List<Work_Order__c> orders) {
        // re-query to get the related users
        List<Work_Order__c> withData = [
          SELECT Id, Brand__c, Sites__c,
                 Sites__r.CorpUser__c, Sites__r.BrandUser__c, Sites__r.Site_User__c,
                 Corporate__c, CreatedBy.Profile.Name, CreatedById,
                 Vendor__c, Work_Order_Type__c, Vendor__r.User__c
          FROM Work_Order__c
          WHERE Id IN :orders
        ];
    
        List<Work_Order__Share> shares = new List<Work_Order__Share>();
        for (Work_Order__c wo : withData) {
          String profile = wo.CreatedBy.Profile.Name;
          // exactly the same sharing branches you already have...
          if (profile == 'Corporate Profile') {
            if (wo.Sites__r.BrandUser__c != null)
              shares.add(SharingHelper.createWorkOrderShare(wo.Id, wo.Sites__r.BrandUser__c));
            // if (wo.Sites__r.Site_User__c != null)
            //   shares.add(SharingHelper.createWorkOrderShare(wo.Id, wo.Sites__r.Site_User__c));
            if (wo.Vendor__c != null && wo.Work_Order_Type__c == 'Child')
              shares.add(SharingHelper.createWorkOrderReadOnlyShare(wo.Id, wo.Vendor__r.User__c));
          }
          else if (profile == 'Brand Profile') {
            if (wo.Sites__r.CorpUser__c != null)
              shares.add(SharingHelper.createWorkOrderShare(wo.Id, wo.Sites__r.CorpUser__c));
            // if (wo.Sites__r.Site_User__c != null)
            //   shares.add(SharingHelper.createWorkOrderShare(wo.Id, wo.Sites__r.Site_User__c));
            if (wo.Vendor__c != null && wo.Work_Order_Type__c == 'Child')
              shares.add(SharingHelper.createWorkOrderReadOnlyShare(wo.Id, wo.Vendor__r.User__c));
          }
          else if (profile == 'Site Profile') {
            if (wo.Sites__r.CorpUser__c != null)
              shares.add(SharingHelper.createWorkOrderShare(wo.Id, wo.Sites__r.CorpUser__c));
            if (wo.Sites__r.BrandUser__c != null)
              shares.add(SharingHelper.createWorkOrderShare(wo.Id, wo.Sites__r.BrandUser__c));
            if (wo.Vendor__c != null && wo.Work_Order_Type__c == 'Child')
              shares.add(SharingHelper.createWorkOrderReadOnlyShare(wo.Id, wo.Vendor__r.User__c));
          }
        }
    
        if (!shares.isEmpty()) {
          Database.insert(shares, false);
        }
        System.debug('Shares created: ' + shares.size());
    }
    
}