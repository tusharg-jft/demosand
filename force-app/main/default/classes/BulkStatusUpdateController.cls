public with sharing class BulkStatusUpdateController {
    @AuraEnabled(cacheable=true)
    public static List<sObject> getRecords(String objectApiName) {
        String query = 'SELECT Id, Name, Status__c FROM ' + objectApiName + ' LIMIT 50';
        return Database.query(query);
    }

    @AuraEnabled
    public static void updateRecords(List<Id> recordIds, String newStatus) {
        List<sObject> recordsToUpdate = new List<sObject>();
        Schema.SObjectType objType = recordIds[0].getSObjectType();
        
        for (Id recordId : recordIds) {
            sObject record = objType.newSObject(recordId);
            record.put('Status__c', newStatus);
            recordsToUpdate.add(record);
        }

        update recordsToUpdate;
    }
}