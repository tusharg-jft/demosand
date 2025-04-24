public with sharing class prefferedVendorController {
    @AuraEnabled(cacheable=true)
    public static List<Trade__c> getTradeForSite(Id siteId) {
            return new List<Trade__c>{[SELECT Id, Name FROM Trade__c]};
    }

    @AuraEnabled(cacheable=true)
    public static List<TradeVendor__c> getVendorsForTrade(String tradeId) {
        if (String.isEmpty(tradeId)) {
            return new List<TradeVendor__c>(); 
        }
        
        List<TradeVendor__c> vendors = [SELECT Vendor__c, Vendor__r.Name FROM TradeVendor__c WHERE Trade__c = :tradeId];
        System.debug('Fetched vendors: ' + vendors);
        return vendors; 
    }

    @AuraEnabled
    public static void updateVendorsOnSite(Id siteId, Id primaryVendorId, Id secondaryVendorId, Id thirdVendorId) {
        Sites__c siteRecord = [SELECT Id, primary_vendor__c, secondary_vendor__c, tertiary_vendor__c FROM Sites__c WHERE Id = :siteId LIMIT 1];
        
        siteRecord.primary_vendor__c = primaryVendorId != null ? primaryVendorId : siteRecord.primary_vendor__c;
        siteRecord.secondary_vendor__c = secondaryVendorId != null ? secondaryVendorId : siteRecord.secondary_vendor__c;
        siteRecord.tertiary_vendor__c = thirdVendorId != null ? thirdVendorId : siteRecord.tertiary_vendor__c;
        
        try {
            update siteRecord;
            System.debug('Updated Site record: ' + siteRecord);
        } catch (Exception e) {
            System.debug('Error updating Site record: ' + e.getMessage());
            throw new AuraHandledException('Error updating Site record: ' + e.getMessage());
        }
    }
    
       @AuraEnabled
    public static void updateRestrictedVendorsOnSite(Id siteId, String restrictedVendors) {
        Sites__c site = [SELECT Id, Restricted_Vendors__c FROM Sites__c WHERE Id = :siteId LIMIT 1];
        site.Restricted_Vendors__c = restrictedVendors;
        update site;
    }
}