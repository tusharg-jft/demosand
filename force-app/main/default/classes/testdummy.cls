public with sharing class InvoiceApprovalController {
    @AuraEnabled
    public static string submitInvoiceForApproval(Id invoiceId){
        try {
            

            Invoice__c invoice = [SELECT Id,Work_Orders__c,Status__c FROM Invoice__c WHERE Id =:invoiceId];
            
            Work_Order__c woList = [
                SELECT Id, Brand__c, Corporate__c ,Sites__c
                FROM Work_Order__c 
                WHERE Id = :invoice.Work_Orders__c 
                LIMIT 1
            ];

            List<Id> userIds = new LIst<Id>();

        if (workOrder.Sites__c != null){
        Sites__c siteUsers = [
                SELECT CorpUser__c,BrandUser__c
                FROM Sites__c 
                WHERE Id = :woList.Sites__c 
            ];
        

        // Step 3: Fetch Brand Users
        if (siteUsers.BrandUser__c != null) {
           
                userIds.add(siteUsers.BrandUser__c);
                userIds.add(siteUsers.CorpUser__c);
            }
        }

        invoice.Status__c='On Hold';
        update Invoice;

List<Invoice__Share> shares = new List<Invoice__Share>();
for (Id uid : userIds) {
    Invoice__Share es = new Invoice__Share(
        ParentId = invoiceId,
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

        String body = ' Invoice has been Submitted for Approval' ;
        String title = 'Invoice Approval' ;
        
        
        List<Id> userIdList = new List<Id>(userIds);
        
        NotificationUtility.sendNotification('InvoiceApproval',  userIds,  invoice.Id ,body,title);

        return 'Success: Invoice Submitted for Approval';

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static String createInvoiceFromEstimate(Id estimateId) {
    

        try {
            if (String.isBlank(estimateId)) {
                throw new AuraHandledException('Estimate Id is required.');
            }

            // Step 1: Fetch the Estimate
            List<Estimate__c> estimateList = [
                SELECT Id, Work_Orders__c, Status__c , Estimate_Data__c, Incurred_Data__c, Email__c,	Estimate_Date__c,	Grand_total__c,Net_Total__c,	Tax_Amount__c,
                Value__c,	Description__c,Account__c , netPrice__c , grandTotal__c , totalDiscount__c  , Internal_Estimate_No__c ,Assessment_Troubleshoot__c ,
                Proposal_For_Repairs__c
                FROM Estimate__c 
                WHERE Id = :estimateId
                LIMIT 1
            ];

            if (estimateList.isEmpty()) {
                return 'Error: Estimate not found.';
            }

            Estimate__c estimate = estimateList[0];

            if (estimate.Status__c == 'Pending' ) {
                return ' Waiting For Estimate Approval';
            }
            

        


            // Create Invoice
        Invoice__c invoice = new Invoice__c();
        
        invoice.Estimate__c=estimateid;
invoice.Work_Orders__c     = estimate.Work_Orders__c;
invoice.Status__c          = 'Pending';
invoice.Estimate_Data__c   = estimate.Estimate_Data__c;
invoice.Incurred_Data__c   = estimate.Incurred_Data__c;
invoice.Email__c           = estimate.Email__c;
invoice.Estimate_Date__c   = estimate.Estimate_Date__c;
// invoice.Grand_total__c     = estimate.Grand_total__c;
// invoice.Net_Total__c       = estimate.Net_Total__c;
invoice.Tax_Amount__c      = estimate.Tax_Amount__c;
invoice.Value__c           = estimate.Value__c;
invoice.Description__c     = estimate.Description__c;
invoice.Account__c         = estimate.Account__c;
invoice.netTotal__c         = estimate.netPrice__c;
invoice.grandTotal__c         = estimate.grandTotal__c;
invoice.totalDiscount__c         = estimate.totalDiscount__c;
invoice.Assessment_Troubleshoot__c = estimate.Assessment_Troubleshoot__c;
invoice.Proposal_For_Repairs__c = estimate.Proposal_For_Repairs__c;
invoice.Internal_Estimate_No__c = estimate.Internal_Estimate_No__c;

        insert invoice;

            // Step 2: Fetch related Work Order
            if (invoice.Work_Orders__c == null) {
                return 'Error: Estimate has no associated Work Order.';
            }

        List<Work_Order__c> woList = [
            SELECT Id, Brand__c, Corporate__c ,Sites__c
            FROM Work_Order__c 
            WHERE Id = :invoice.Work_Orders__c 
            LIMIT 1
        ];

        if (woList.isEmpty()) {
            return 'Error: Work Order not found.';
        }

        Work_Order__c workOrder = woList[0];

        Set<Id> userIds = new Set<Id>();

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
        }

      //System.debug("Site"+ " Brand: "  + siteUsers.BrandUser__r.Name + " Corp :" + siteUsers.corpUser__c);

      
            List<Invoice__Share> shares = new List<Invoice__Share>();
            for (Id uid : userIds) {
                Invoice__Share es = new Invoice__Share(
                    ParentId = invoice.Id,
                    UserOrGroupId = uid,
                    AccessLevel = 'Edit',
                    RowCause = Schema.Estimate__Share.RowCause.Manual
                );
                System.debug('Prepared share record: ' + es);
                shares.add(es);
            }
        
            if (!shares.isEmpty()) {
                insert shares;
            }

            String body = ' Invoice has been Submitted for Approval' ;
            String title = 'Invoice Approval' ;
            
            
            List<Id> userIdList = new List<Id>(userIds);
            
            NotificationUtility.sendNotification('InvoiceApproval',  userIdList,  invoice.Id ,body,title);
            Id invoiceId=invoice.Id;
    return invoiceId;

        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }


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
    public static String updateInvoiceStatus(Id invoiceId, String action) {
        System.debug('invoiceId: ' + invoiceId + ', action: ' + action);
    
        Invoice__c invoice = [SELECT Id, Status__c,Work_Orders__c FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];
    
       
            System.debug('Current Status: ' + invoice.Status__c);
            if (invoice.Status__c == 'Pending' || invoice.Status__c=='On Hold') {
                if (action == 'approve') {
                    invoice.Status__c = 'Approved';
                } else if (action == 'reject') {
                    invoice.Status__c = 'Rejected';
                }
                update invoice;
            } else {
                System.debug('Status is not Submitted, skipping update.');
            }
        


            List<Id> userIdList = new List<Id>();

        Invoice__c est = [Select CreatedById from Invoice__c where Id =:invoiceId];

        User u = [SELECT Id,Profile.Name FROM User WHERE Id = :est.CreatedById LIMIT 1];

        if(u.Profile.Name=='Vendor Profile' || u.Profile.Name=='System Administrator'){

            userIdList.add(u.Id);
        }

            // if (invoice.Work_Orders__c == null) {
            //     return 'Error: Estimate has no associated Work Order.';
            // }

            // List<Work_Order__c> woList = [
            //     SELECT Id,Vendor__c
            //     FROM Work_Order__c 
            //     WHERE Id = :invoice.Work_Orders__c 
            //     LIMIT 1
            // ];

            // if (woList.isEmpty()) {
            //     return 'Error: Work Order not found.';
            // }

            // Work_Order__c workOrder = woList[0];

            // Set<Id> userIds = new Set<Id>();

            // // Step 3: Fetch Brand Users
            // if (workOrder.Brand__c != null) {
            //     List<Brand_User__c> brandUsers = [
            //         SELECT User__c 
            //         FROM Brand_User__c 
            //         WHERE Brand__c = :workOrder.Brand__c AND User__c != null
            //     ];
            //     for (Brand_User__c bu : brandUsers) {
            //         userIds.add(bu.User__c);
            //     }
            // }

            // Step 4: Fetch Vendor User
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

System.debug('userIds: ' + userIdList);
            


             // Step 6: Send notification
// Id notifTypeId = [
//     SELECT Id 
//     FROM CustomNotificationType 
//     WHERE DeveloperName = 'EstimateApproval' 
//     LIMIT 1
// ].Id;

// Messaging.CustomNotification notification = new Messaging.CustomNotification();
// notification.setTitle('Invoice ' + invoice.Status__c);
// notification.setBody(' Invoice has been ' +  invoice.Status__c);
// notification.setSenderId(UserInfo.getUserId());
// notification.setNotificationTypeId(notifTypeId);
// notification.setTargetId(invoice.Id); // Clicking opens Estimate

// // Convert to Set<String>
// Set<String> userIdStrings = new Set<String>();
// for (Id uid : userIds) {
//     userIdStrings.add(String.valueOf(uid));
// }

// // Send notification
// notification.send(userIdStrings);
String body = ' Invoice has been ' +  invoice.Status__c ;
String title = 'Invoice ' + invoice.Status__c;


NotificationUtility.sendNotification('InvoiceApproval',  userIdList,  invoice.Id ,body,title);

           
    
        return 'Success: Invoice Finalized';


    }
}