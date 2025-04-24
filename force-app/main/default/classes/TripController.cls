public with sharing class TripController {
    
    @AuraEnabled(cacheable=true)
    public static List<Trip__c> getTripsForParentWorkOrder(Id parentWOId) {
        if (parentWOId == null) {
            return new List<Trip__c>();
        }

        return [
            SELECT Name, Vendor__c, Vendor__r.Name, Status__c, Date_Time_ETA__c,
                   CheckInTime__c, CheckOutTime__c, Work_Orders__c, Work_Orders__r.Name
            FROM Trip__c
            WHERE Work_Orders__c IN (
                SELECT Id FROM Work_Order__c WHERE ParentWO__c = :parentWOId
            )
        ];
    }
   

        @AuraEnabled(cacheable=true)
        public static List<Trip__c> getTripsForWorkOrder(Id workOrderId) {
            if (workOrderId == null) {
                return new List<Trip__c>();
            }
    
            return [
                SELECT Name, Vendor__c, Vendor__r.Name, Status__c, Date_Time_ETA__c,
                       CheckInTime__c, CheckOutTime__c, Work_Orders__c
                FROM Trip__c
                WHERE Work_Orders__c = :workOrderId
            ];
        }
    }
    

