trigger VendorTradeRateTrigger on Vendor_Trade_Rate_Management__c (after insert, after update) {
    Set<Id> tradeIds = new Set<Id>();

    // Collect Trade__c IDs from new Vendor Trade Rate records
    for (Vendor_Trade_Rate_Management__c tradeRate : Trigger.new) {
        if (tradeRate.Trade__c != null) {
            tradeIds.add(tradeRate.Trade__c);
        }
    }

    if (!tradeIds.isEmpty()) {
        // Fetch Corporate__c IDs related to the trades
        Map<Id, Id> tradeToCorporateMap = new Map<Id, Id>();
        for (Trade__c trade : [SELECT Id, Corporate__c FROM Trade__c WHERE Id IN :tradeIds]) {
            if (trade.Corporate__c != null) {
                tradeToCorporateMap.put(trade.Id, trade.Corporate__c);
            }
        }

        // Fetch Corporate Users (User__c) from Corporate__c
        Set<Id> corporateUserIds = new Set<Id>();
        for (Corporate__c corp : [SELECT Id, User__c FROM Corporate__c WHERE Id IN :tradeToCorporateMap.values()]) {
            if (corp.User__c != null) {
                corporateUserIds.add(corp.User__c);
            }
        }
        
      

        // Send notifications for each new Vendor Trade Rate record
        if (!corporateUserIds.isEmpty()) {
            for (Vendor_Trade_Rate_Management__c tradeRate : Trigger.new) {
                VendorTradeRateNotificationHelper.sendTradeRateNotifications(tradeRate.Id, corporateUserIds); // ✅ Now correctly calling static method
            }
        }
    }
    
}