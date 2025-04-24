public class VendorTradeRateSharingBatch implements Database.Batchable<SObject> {
    private Set<Id> tradeIds; // Store Trade IDs

    // ✅ Constructor to accept Trade IDs
    public VendorTradeRateSharingBatch(Set<Id> tradeIds) {
        this.tradeIds = tradeIds;
    }

    public Database.QueryLocator start(Database.BatchableContext BC) {
        // Query Vendor Trade Rate Management records related to the trade IDs
        return Database.getQueryLocator([
            SELECT Id, Trade__c FROM Vendor_Trade_Rate_Management__c WHERE Trade__c IN :tradeIds
        ]);
    }

    public void execute(Database.BatchableContext BC, List<Vendor_Trade_Rate_Management__c> records) {
        List<Vendor_Trade_Rate_Management__Share> shares = new List<Vendor_Trade_Rate_Management__Share>();

        // Retrieve related corporate users
        Map<Id, Id> tradeToCorporateMap = new Map<Id, Id>();
        for (Trade__c trade : [SELECT Id, Corporate__c FROM Trade__c WHERE Id IN :tradeIds]) {
            if (trade.Corporate__c != null) {
                tradeToCorporateMap.put(trade.Id, trade.Corporate__c);
            }
        }

        Map<Id, Id> corporateToUserMap = new Map<Id, Id>();
        for (Corporate__c corp : [SELECT Id, User__c FROM Corporate__c WHERE Id IN :tradeToCorporateMap.values()]) {
            if (corp.User__c != null) {
                corporateToUserMap.put(corp.Id, corp.User__c);
            }
        }

        // Generate sharing records
        for (Vendor_Trade_Rate_Management__c vtrm : records) {
            Id corporateId = tradeToCorporateMap.get(vtrm.Trade__c);
            if (corporateId != null && corporateToUserMap.containsKey(corporateId)) {
                Id userId = corporateToUserMap.get(corporateId);
                Vendor_Trade_Rate_Management__Share share = new Vendor_Trade_Rate_Management__Share();
                share.ParentId = vtrm.Id;
                share.UserOrGroupId = userId;
                share.AccessLevel = 'Edit'; // ✅ Correct Picklist Value
                share.RowCause = Schema.Vendor_Trade_Rate_Management__Share.RowCause.Manual;
                shares.add(share);
            }
        }

        if (!shares.isEmpty()) {
            try {
                insert shares;
            } catch (DmlException e) {
                System.debug('❌ Error inserting sharing records: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext BC) {
        System.debug('✅ Batch Job Completed Successfully');
    }
}