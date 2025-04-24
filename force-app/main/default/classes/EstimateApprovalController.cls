public with sharing class EstimateApprovalController {
    @AuraEnabled
    public static String submitForApproval(Id estimateId) {
        try {
            if (String.isBlank(estimateId)) {
                throw new AuraHandledException('Estimate Id is required.');
            }

            // Step 1: Fetch the Estimate
            List<Estimate__c> estimateList = [
                SELECT Id, Work_Orders__c, Status__c,Name__c 
                FROM Estimate__c 
                WHERE Id = :estimateId
                LIMIT 1
            ];

            if (estimateList.isEmpty()) {
                return 'Error: Estimate not found.';
            }

            Estimate__c estimate = estimateList[0];

            // Check status
            if (estimate.Status__c == 'Approved' || estimate.Status__c == 'Rejected') {
                return 'Estimate already finalized.';
            }

            // Step 2: Fetch related Work Order
            if (estimate.Work_Orders__c == null) {
                return 'Error: Estimate has no associated Work Order.';
            }

            List<Work_Order__c> woList = [
                SELECT Id, Brand__c, Corporate__c ,Sites__c,Vendor__c,Status__c
                FROM Work_Order__c 
                WHERE Id = :estimate.Work_Orders__c 
                LIMIT 1
            ];

            if (woList.isEmpty()) {
                return 'Error: Work Order not found.';
            }

            Work_Order__c workOrder = woList[0];

         //   WorkOrderStatusFunction.checkWithWOStatus(workOrder.Id);

            Vendor__c v =[Select Name from Vendor__c where Id=:workOrder.Vendor__c];
            
            
            Set<Id> userIds = new Set<Id>();

            // Step 3: Fetch Brand Users
            if (workOrder.Sites__c != null){
                Sites__c siteUsers = [
                        SELECT CorpUser__c,BrandUser__c
                        FROM Sites__c 
                        WHERE Id = :workOrder.Sites__c 
                    ];
                
        
                // Step 3: Fetch Brand Users
                if (siteUsers.BrandUser__c != null) {
                   
                        userIds.add(siteUsers.BrandUser__c);
                        userIds.add(siteUsers.CorpUser__c);
                    }


                System.debug('@@@ siteUsers.CorpUser__c'+siteUsers.CorpUser__c);
                System.debug('@@@ siteUsers.CorpUser__c'+siteUsers.BrandUser__c);
                }
        

            // Step 5: Share Estimate__c record
            System.debug('Sharing Estimate with users: ' + userIds);

List<Estimate__Share> shares = new List<Estimate__Share>();
for (Id uid : userIds) {
    Estimate__Share es = new Estimate__Share(
        ParentId = estimate.Id,
        UserOrGroupId = uid,
        AccessLevel = 'Edit',
        RowCause = Schema.Estimate__Share.RowCause.Manual
    );
    System.debug('Prepared share record: ' + es);
    shares.add(es);
}

if (!shares.isEmpty()) {
    insert shares;
    System.debug('Inserted share records: ' + shares);
}

 String  body = ' New Estimate '+ estimate.Name__c +' has been Submitted for Approval by '+ v.Name ;
String  title = 'New Estimate has be sent for Approval' ;


List<Id> userIdList = new List<Id>(userIds);

NotificationUtility.sendNotification('EstimateApproval',  userIdList,  estimate.Id ,body,title);

               
            // Step 6: Update status
            estimate.Status__c = 'Submited_For_Approval';
            
            update estimate;
            

            return 'Success: Estimate submitted for approval.';

        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

// this is a button apex controller // i want that as soon as this controller is accessed a notification is sent to the users fetched from above // use customnotification / messaging




    @AuraEnabled(cacheable=true)
    public static String getCurrentUserProfileName() {
        try {
            User u = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            return u.Profile.Name;
        } catch (Exception e) {
            return null;
        }
    }

    @AuraEnabled
    public static String updateEstimateStatus(Id estimateId, String action) {
        System.debug('estimateId: ' + estimateId + ', action: ' + action);
    
        Estimate__c estimate = [SELECT Id, Status__c,Name__c, Work_Orders__c FROM Estimate__c WHERE Id = :estimateId LIMIT 1];
    	
        if (estimate != null) {
            System.debug('Current Status: ' + estimate.Status__c);
            if (estimate.Status__c == 'Pending' || estimate.Status__c == 'Submited_For_Approval') 
                 {
                if (action == 'approve') {
                    estimate.Status__c = 'Approved';
                } else if (action == 'reject') {
                    estimate.Status__c = 'Rejected';
                }
                update estimate;
            } else {
                System.debug('Status is not Submitted, skipping update.');
            }
        }


        List<Id> userIdList = new List<Id>();

        Estimate__c est = [Select CreatedById from Estimate__c where Id =:estimateId];

        User u = [SELECT Id,Profile.Name FROM User WHERE Id = :est.CreatedById LIMIT 1];

        if(u.Profile.Name=='Vendor Profile' || u.Profile.Name=='System Administrator'){

            userIdList.add(u.Id);
        }


                   // Step 1: Fetch the Estimate
                //    List<Estimate__c> estimateList = [
                //     SELECT Id, Work_Orders__c, Status__c 
                //     FROM Estimate__c 
                //     WHERE Id = :estimateId
                //     LIMIT 1
                // ];
    
                // if (estimateList.isEmpty()) {
                //     return 'Error: Estimate not found.';
                // }
    
                // Estimate__c estimate1 = estimateList[0];
    
                // Check status
                // if (estimate.Status__c == 'Approved' || estimate.Status__c == 'Rejected') {
                //     return 'Estimate already finalized.';
                // }
    
                // Step 2: Fetch related Work Order
                if (estimate.Work_Orders__c == null) {
                    return 'Error: Estimate has no associated Work Order.';
                }
    
                List<Work_Order__c> woList = [
                    SELECT Id,Vendor__c
                    FROM Work_Order__c 
                    WHERE Id = :estimate.Work_Orders__c 
                    LIMIT 1
                ];
    
                if (woList.isEmpty()) {
                    return 'Error: Work Order not found.';
                }
    
                Work_Order__c workOrder = woList[0];

               // WorkOrderStatusFunction.checkWithWOStatus(workOrder.Id);
    
                // Set<Id> userIds = new Set<Id>();
    
                
    
                // // Step 4: Fetch Vendor User
                // if (workOrder.Vendor__c != null) {
                //     List<Vendor__c> vendorList = [
                //         SELECT User__c 
                //         FROM Vendor__c 
                //         WHERE Id = :workOrder.Vendor__c 
                //         LIMIT 1
                //     ];
                //     if (!vendorList.isEmpty() && vendorList[0].User__c != null) {
                //         userIds.add(vendorList[0].User__c);
                //     }
                // }

              
System.debug('userLIst '+userIdList);


                String  body= ' Estimate ' + estimate.Name__c +' has been ' +  estimate.Status__c +' by '+ UserInfo.getName();
String title= 'Estimate has been ' + estimate.Status__c;




NotificationUtility.sendNotification('EstimateApproval',  userIdList,  estimate.Id ,body,title);
               
        
            return 'Success: Estimate Finalized';





    }
    
}