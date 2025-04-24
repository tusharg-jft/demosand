public class TripSharingTriggerHandler {
    public static void handleAfterInsert(List<Trip__c> newTrips) {
        Id CorporateUserId;
        Id BrandUserId;
        List<Trip__c> tripWithRelatedData = [
            SELECT Id, Vendor__c, Vendor__r.User__c, Work_Orders__r.sites__r.CorpUser__c, 
            Work_Orders__r.sites__r.BrandUser__c, CreatedBy.Profile.Name, CreatedById, Primary_Technician__r.User__r.Id 
            FROM Trip__c 
            WHERE Id IN :newTrips
        ];
        
        List<Trip__Share> sharesToCreate = new List<Trip__Share>();
        
        for (Trip__c trip : tripWithRelatedData) {
            CorporateUserId = trip.Work_Orders__r.sites__r.CorpUser__c;
            BrandUserId = trip.Work_Orders__r.sites__r.BrandUser__c;
            
            // Share with brand user
            if (trip.CreatedBy.Profile.Name == 'Vendor Profile') {
                if (trip.Work_Orders__c != null && BrandUserId != null) {
                    sharesToCreate.add(SharingHelper.createTripShare(trip.Id, BrandUserId));
                    
                    // Share with Corporate user
                    if (CorporateUserId != null) {
                        sharesToCreate.add(SharingHelper.createTripShare(trip.Id, CorporateUserId));
                    }
                    
                    // Share with Primary Technician
                    if (trip.Primary_Technician__c != null && trip.Primary_Technician__r.User__r.Id != null) {
                        sharesToCreate.add(SharingHelper.createTripShare(trip.Id, trip.Primary_Technician__r.User__r.Id));
                    }
                }
            }
        }
        
        if (!sharesToCreate.isEmpty()) {
            Database.insert(sharesToCreate, false);
        }
    }
}