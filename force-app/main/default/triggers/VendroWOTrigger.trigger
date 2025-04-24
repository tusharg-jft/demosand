trigger VendroWOTrigger on VendorWO__c (after insert) {
if(Trigger.isAfter && Trigger.isInsert) {
        VendorWoTriggerHandler.handleAfterInsert(Trigger.new);
    }
}