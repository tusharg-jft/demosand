trigger BrandTrigger on Brand__c (before insert, after insert, after update) {
    List<Brand__Share> shares = new List<Brand__Share>();

    System.debug('### BrandTrigger Execution Started ###');
    System.debug('Trigger Context - isBefore: ' + Trigger.isBefore + ', isAfter: ' + Trigger.isAfter + ', isInsert: ' + Trigger.isInsert + ', isUpdate: ' + Trigger.isUpdate);

    // Before Insert: Assign the current user as CorporateUser__c
    if (Trigger.isBefore && Trigger.isInsert) {
        for (Brand__c brand : Trigger.new) {
            System.debug('Processing Brand__c ID: ' + brand.Id + ' | Current CorporateUser__c: ' + brand.CorporateUser__c);
            if (brand.CorporateUser__c == null) {
                brand.CorporateUser__c = UserInfo.getUserId();
            }
        }
    }

    // After Insert/Update: Handle Sharing
    if (Trigger.isAfter) {

        if (Trigger.isUpdate) {
            System.debug('Deleting existing Brand__Share records for updated Brands...');
            delete [SELECT Id FROM Brand__Share 
                    WHERE ParentId IN :Trigger.newMap.keySet() 
                    AND RowCause = 'Manual'];
        }

        for (Brand__c brand : Trigger.new) {    
         
            // Brand Owner sharing
              if (brand.BrandOwner__c != null && brand.BrandOwner__c != brand.OwnerId) {
                Brand__Share ownerShare = SharingHelper.createBrandShare(brand.Id, brand.BrandOwner__c);
                shares.add(ownerShare);
            }
        }


        if (!shares.isEmpty()) {
            insert shares;
        }
    }

    System.debug('BrandTrigger Execution Completed');
}