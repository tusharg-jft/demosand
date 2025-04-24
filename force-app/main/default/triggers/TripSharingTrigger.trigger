trigger TripSharingTrigger on Trip__c (after insert) {
    if(Trigger.isAfter && Trigger.isInsert) {
        TripSharingTriggerHandler.handleAfterInsert(Trigger.new);
    }
}