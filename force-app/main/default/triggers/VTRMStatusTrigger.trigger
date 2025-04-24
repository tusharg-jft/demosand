trigger VTRMStatusTrigger on Vendor_Trade_Rate_Management__c (after update) {
    Set<Id> updatedVTRMIds = new Set<Id>();
    Id v ;

    for (Vendor_Trade_Rate_Management__c vtrm : Trigger.new) {
        Vendor_Trade_Rate_Management__c oldVTRM = Trigger.oldMap.get(vtrm.Id);
        v= vtrm.Id;

        // Check if Status__c was updated
        if (vtrm.Status__c != oldVTRM.Status__c && (vtrm.Status__c == 'Approved' || vtrm.Status__c == 'Declined')) {
            updatedVTRMIds.add(vtrm.Id);
       
       Vendor_Trade_Rate_Management__c vtm = [select Vendor__c From Vendor_Trade_Rate_Management__c where Id =: v];

       Vendor__c vendor = [select Id, User__c from Vendor__c where Id =: vtm.Vendor__c];
        

       List<Id> userIdList = new List<Id>();


       userIdList.add(vendor.User__c);
    String body = ' Status Updated' ;
            String title = 'Status Updated' ;
            
            
        
            
            NotificationUtility.sendNotification('InvoiceApproval',  userIdList,  v ,body,title);

    // if (!updatedVTRMIds.isEmpty()) {
    //     List<String> vtrmIdList = new List<String>();
    //     for (Id vtrmId : updatedVTRMIds) {
    //         vtrmIdList.add(String.valueOf(vtrmId)); // ✅ Correctly converting Ids to Strings
    //     }
    //     String vtrmIdString = String.join(vtrmIdList, ','); // ✅ Now valid

    //     VTRMNotificationHandler.sendStatusUpdateNotification(vtrmIdString);
    // }
}
}
}