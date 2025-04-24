trigger VendorTradeRateSharing on Vendor_Trade_Rate_Management__c (after insert, after update) {
    System.debug('⚡ Trigger Running for VTRM Records: ' + Trigger.new);

    Set<Id> tradeIds = new Set<Id>();
    for (Vendor_Trade_Rate_Management__c tradeRate : Trigger.new) {
        if (tradeRate.Trade__c != null) {
            tradeIds.add(tradeRate.Trade__c);
        }
    }

    System.debug('🔎 Extracted Trade IDs: ' + tradeIds);

    if (!tradeIds.isEmpty()) {
        VendorTradeRateSharingBatch batchJob = new VendorTradeRateSharingBatch(tradeIds);
        System.debug('🚀 Executing Batch Job...');
        Database.executeBatch(batchJob, 200);
    } else {
        System.debug('❌ No Trade IDs found. Trigger exiting.');
    }
}