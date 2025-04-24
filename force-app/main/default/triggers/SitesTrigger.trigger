trigger SitesTrigger on Sites__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert) {
        SitesTriggerHandler.handleAfterInsert(Trigger.new);
    }
}