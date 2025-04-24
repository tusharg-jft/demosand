trigger CorporateTrigger on Corporate__c (after insert, after update) {
    List<Corporate__Share> shares = new List<Corporate__Share>();
    
    // Delete existing shares on update
    if(Trigger.isUpdate) {
        delete [SELECT Id FROM Corporate__Share 
               WHERE ParentId IN :Trigger.newMap.keySet() 
               AND RowCause = 'Manual'];
    }
    
    // Create shares based on Corporate__c.User__c field
    for(Corporate__c corp : Trigger.new) {
        if(corp.User__c != null && corp.User__c != UserInfo.getUserId()) {
            shares.add(SharingHelper.createCorporateShare(corp.Id, corp.User__c));
        }
    }
    
    if(!shares.isEmpty()) {
        insert shares;
    }
}