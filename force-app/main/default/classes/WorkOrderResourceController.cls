public with sharing class WorkOrderResourceController {

   @AuraEnabled(cacheable=true)
    public static List<Field_Resource__c> getTechnicianResources(Id tripId) {
        try {
            // Fetch the OwnerId from the Trip record
            Trip__c tripRecord = [SELECT Name, Work_Order__c, OwnerId FROM Trip__c WHERE Id = :tripId LIMIT 1];
            Id tripOwnerId = tripRecord.OwnerId;      
            
            // Check if the current user is an Admin
        String currentUserProfile = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        Boolean isAdmin = currentUserProfile.contains('System Administrator'); // Adjust as per your Admin profile name
            
            // Query Field Resources
        List<Field_Resource__c> fieldResources;
        if (isAdmin) {
            // Admin: Fetch all Technician resources
            fieldResources = [
                SELECT Id, Name, Resource_Type__c, IsActive__c
                FROM Field_Resource__c
                WHERE Resource_Type__c = 'Technician' AND IsActive__c = true
            ];
        } else {
            // Non-Admin: Fetch only resources owned by the Trip owner
            fieldResources = [
                SELECT Id, Name, Resource_Type__c, IsActive__c
                FROM Field_Resource__c
                WHERE Resource_Type__c = 'Technician' AND IsActive__c = true
                AND OwnerId = :tripOwnerId
            ];
        }
        return fieldResources;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to load technician records: ' + e.getMessage());
        }
    }
    
  /*  @AuraEnabled(cacheable=true)
    public static List<Field_Resource__c> getTechnicianResources(Id tripId) {
        try {
            // Fetch the OwnerId from the Trip record
            Trip__c tripRecord = [SELECT Name, Work_Order__c, OwnerId FROM Trip__c WHERE Id = :tripId LIMIT 1];
            Id tripOwnerId = tripRecord.OwnerId;            
            
            // Query Field Resources for the technician type where the owner matches the Trip's owner
            return [
                SELECT Id, Name, Resource_Type__c,IsActive__c
                FROM Field_Resource__c
                WHERE Resource_Type__c = 'Technician' AND IsActive__c = true
                AND OwnerId = :tripOwnerId
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Failed to load technician records: ' + e.getMessage());
        }
    }
    */
    @AuraEnabled
    public static void createTripTechnicians(Id tripId, Id workOrderId, List<Id> fieldResourceIds) {
        try {
            List<Trip_Technician__c> tripTechnicians = new List<Trip_Technician__c>();
            
            // For each selected technician, create a new TripTechnician record
            for (Id resourceId : fieldResourceIds) {
                Trip_Technician__c tripTechnician = new Trip_Technician__c(
                    Trip__c = tripId,
                    Field_Resource__c = resourceId);
                tripTechnicians.add(tripTechnician);
            }
            
            // Insert the TripTechnician records
            insert tripTechnicians;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to create TripTechnician records: ' + e.getMessage());
        }
    }
}