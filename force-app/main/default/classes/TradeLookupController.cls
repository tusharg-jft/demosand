public class TradeLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<Trade__c> getFilteredTrades(Id workOrderId, String userProfile) {
        Id corporateId = null;
        
        if (userProfile == 'FM - Site User') {
            Sites__c userSite = [SELECT Corporate__r.Id FROM Sites__c WHERE Site_User__c = :UserInfo.getUserId() LIMIT 1];
            corporateId = userSite.Corporate__r.Id;
        } else if (userProfile == 'System Administrator') {
            if (workOrderId != null) {
                WorkOrder workOrders = [SELECT Corporate__c FROM workOrder WHERE Id = :workOrderId LIMIT 1];
                corporateId = workOrders.Corporate__c;
            }
        }
        
        List<Trade__c> filteredTrades = [SELECT Id, Name FROM Trade__c WHERE Corporate__r.Id = :corporateId];
        return filteredTrades;
    }
}