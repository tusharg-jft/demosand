public with sharing class InvoiceApprovalController {
    @AuraEnabled
    public static string submitInvoiceForApproval(Id invoiceId){
        try {
            

            Invoice__c invoice = [SELECT Id,Work_Orders__c,Status__c FROM Invoice__c WHERE Id =:invoiceId];
            
            Work_Order__c woList = [
                SELECT Id, Brand__c, Corporate__c ,Sites__c,Vendor__c
                FROM Work_Order__c 
                WHERE Id = :invoice.Work_Orders__c 
                LIMIT 1
            ];
         
            //WorkOrderStatusFunction.checkWithWOStatus(woList.Id);

            Vendor__c v =[Select Name from Vendor__c where  Id=:woList.Vendor__c];
            
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

        String body = ' Invoice '+invoice.Name +' has been Submitted for Approval by '+ v.Name;
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
            SELECT Id, Work_Orders__c, Status__c, Estimate_Data__c, Incurred_Data__c, Email__c,
                   Estimate_Date__c, Grand_total__c, Net_Total__c, Tax_Amount__c, Value__c, 
                   Description__c, Account__c, netPrice__c, grandTotal__c, totalDiscount__c,
                   Internal_Estimate_No__c, Assessment_Troubleshoot__c, Proposal_For_Repairs__c
            FROM Estimate__c 
            WHERE Id = :estimateId
            LIMIT 1
        ];

        if (estimateList.isEmpty()) {
            return 'Error: Estimate not found.';
        }

        Estimate__c estimate = estimateList[0];

        if (estimate.Status__c == 'Pending') {
            return 'Waiting For Estimate Approval';
        }

        // Step 2: Create Invoice
        Invoice__c invoice = new Invoice__c();
        invoice.Estimate__c = estimateId;
        invoice.Work_Orders__c = estimate.Work_Orders__c;
        invoice.Status__c = 'Pending';
        invoice.Email__c = estimate.Email__c;
        invoice.Estimate_Date__c = estimate.Estimate_Date__c;
        invoice.Tax_Amount__c = estimate.Tax_Amount__c;
        invoice.Value__c = estimate.Value__c;
        invoice.Description__c = estimate.Description__c;
        invoice.Account__c = estimate.Account__c;
        invoice.netTotal__c = estimate.netPrice__c;
        invoice.grandTotal__c = estimate.grandTotal__c;
        invoice.totalDiscount__c = estimate.totalDiscount__c;
        invoice.Assessment_Troubleshoot__c = estimate.Assessment_Troubleshoot__c;
        invoice.Proposal_For_Repairs__c = estimate.Proposal_For_Repairs__c;
        invoice.Internal_Invoice_No__c = estimate.Internal_Estimate_No__c;

        insert invoice;

 
        List<Work_Order__c> woList = [
            SELECT Id, ParentWO__c, Invoices__c
            FROM Work_Order__c
            WHERE Id = :estimate.Work_Orders__c
            LIMIT 1
        ];

        if (woList.isEmpty()) {
            return 'Error: Work Order not found.';
        }

        Work_Order__c wo = woList[0];
        
        //WorkOrderStatusFunction.checkWithWOStatus(wo.Id);
        
        
        
        // wo.Invoices__c = invoice.Id;

        // if (wo.ParentWO__c != null) {
        //     List<Work_Order__c> parentList = [
        //         SELECT Id, Invoices__c
        //         FROM Work_Order__c
        //         WHERE Id = :wo.ParentWO__c
        //         LIMIT 1
        //     ];
        //     if (!parentList.isEmpty()) {
        //         Work_Order__c parentWO = parentList[0];
        //         parentWO.Invoices__c = invoice.Id;
        //         update parentWO;
        //     }
        // }

        // update wo;

        if (invoice.Work_Orders__c == null) {
            return 'Error: Estimate has no associated Work Order.';
        }

        // Step 4: Refetch WO for extra fields
        List<Work_Order__c> workOrderList = [
            SELECT Id, Brand__c, Corporate__c, Sites__c, Vendor__c
            FROM Work_Order__c 
            WHERE Id = :invoice.Work_Orders__c 
            LIMIT 1
        ];

        if (workOrderList.isEmpty()) {
            return 'Error: Work Order not found.';
        }

        Work_Order__c workOrder = workOrderList[0];

        // Step 5: Fetch Vendor
        Vendor__c v;
        if (Schema.sObjectType.Vendor__c.isAccessible() &&
            Schema.sObjectType.Vendor__c.fields.Name.isAccessible() &&
            workOrder.Vendor__c != null) {

            List<Vendor__c> vendors = [
                SELECT Name 
                FROM Vendor__c 
                WHERE Id = :workOrder.Vendor__c 
                LIMIT 1
            ];

            if (vendors.isEmpty()) {
                return 'Error: Vendor not found.';
            }

            v = vendors[0];
        } else {
            return 'Error: You do not have access to Vendor data or Vendor not linked.';
        }

        // Step 6: Get users from site
        Set<Id> userIds = new Set<Id>();
        if (workOrder.Sites__c != null) {
            List<Sites__c> siteList = [
                SELECT CorpUser__c, BrandUser__c
                FROM Sites__c 
                WHERE Id = :workOrder.Sites__c 
                LIMIT 1
            ];

            if (!siteList.isEmpty()) {
                Sites__c siteUsers = siteList[0];
                if (siteUsers.BrandUser__c != null) userIds.add(siteUsers.BrandUser__c);
                if (siteUsers.CorpUser__c != null) userIds.add(siteUsers.CorpUser__c);
            }
        }
        
        System.debug('Estimate Id: ' + estimateId);
System.debug('Estimate.Work_Orders__c: ' + estimate.Work_Orders__c);
System.debug('Vendor Id: ' + workOrder.Vendor__c);
System.debug('Site Id: ' + workOrder.Sites__c);


        // Step 7: Share invoice with users
        List<Invoice__Share> shares = new List<Invoice__Share>();
        for (Id uid : userIds) {
            shares.add(new Invoice__Share(
                ParentId = invoice.Id,
                UserOrGroupId = uid,
                AccessLevel = 'Edit',
                RowCause = Schema.Invoice__Share.RowCause.Manual
            ));
        }

        if (!shares.isEmpty()) {
            insert shares;
        }

        // Step 8: Send notification
        String body = 'Invoice ' + invoice.Name + ' has been Submitted for Approval by ' + v.Name;
        String title = 'Invoice Approval';
        List<Id> userIdList = new List<Id>(userIds);

        NotificationUtility.sendNotification('InvoiceApproval', userIdList, invoice.Id, body, title);

        return invoice.Id;

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
    
        Invoice__c invoice = [SELECT Id,Name, Status__c,Work_Orders__c FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];
    
       
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

            List<Work_Order__c> woList = [
                SELECT Id,Vendor__c
                FROM Work_Order__c 
                WHERE Id = :invoice.Work_Orders__c 
                LIMIT 1
            ];

            if (woList.isEmpty()) {
                return 'Error: Work Order not found.';
            }

            Work_Order__c workOrder = woList[0];

           // WorkOrderStatusFunction.checkWithWOStatus(workOrder.Id);

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
String body = ' Invoice ' + invoice.Name+' has been ' +  invoice.Status__c + ' by '+ UserInfo.getName() ;
String title = 'Invoice ' + invoice.Status__c;


NotificationUtility.sendNotification('InvoiceApproval',  userIdList,  invoice.Id ,body,title);

           
    
        return 'Success: Invoice Finalized';


    }
}