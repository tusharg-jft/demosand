/*public with sharing class CalendarController {
    
    @AuraEnabled(cacheable=true)
    public static List<Brand__c> getBrands() {
        return [SELECT Id, Name FROM Brand__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<Trip__c> getTrips(String searchText, String brandId) {
        String LikeValue = '%' + searchText + '%';

        String query = 'SELECT Id, Name, Work_Order__c, Work_Order__r.WorkOrderNumber, Date_Time_ETA__c, Status__c, Brand__c, Brand__r.Name ' +
                       'FROM Trip__c ' +
                       'WHERE (Name LIKE :LikeValue OR Status__c LIKE :LikeValue)';

        if (String.isNotBlank(brandId)) {
            query += ' AND Brand__c = :brandId';  // Ensure this line is correct
        }

        // Execute the query
        return Database.query(query);
    }
}
*/
public with sharing class CalendarController {

    @AuraEnabled(cacheable=true)
    public static List<Brand__c> getBrands() {
        return [SELECT Id, Name FROM Brand__c];
    }
    
     @AuraEnabled(cacheable=true)
    public static List<Sites__c> getSites() {
        return [SELECT Id, Name FROM Sites__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<Vendor__c> getVendors() {
        return [SELECT Id, Name FROM Vendor__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<Trade__c> getTrades() {
        return [SELECT Id, Name FROM Trade__c];
    }

    @AuraEnabled(cacheable=true)
    public static List<Trip__c> getTrips(String searchText, String brandId, String siteId, String vendorId, String tradeId) {
        String LikeValue = '%' + searchText + '%';

        String query = 'SELECT Id, Name, Work_Order__c, Work_Order__r.WorkOrderNumber, Date_Time_ETA__c, Status__c, Brand__c, Brand__r.Name, Sites__c, Sites__r.Name, Vendor__c, Vendor__r.Name, Trade__c, Trade__r.Name ' +
                       'FROM Trip__c ' +
                       'WHERE (Name LIKE :LikeValue OR Status__c LIKE :LikeValue)';

        if (String.isNotBlank(brandId)) {
            query += ' AND Brand__c = :brandId';
        }

        if (String.isNotBlank(siteId)) {
            query += ' AND Sites__c = :siteId';
        }

        if (String.isNotBlank(vendorId)) {
            query += ' AND Vendor__c = :vendorId';
        }

        if (String.isNotBlank(tradeId)) {
            query += ' AND Trade__c = :tradeId';
        }

        return Database.query(query);
    }

}