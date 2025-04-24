trigger TradeRateTrigger on Vendor_Trade_Rate_Management__c (after insert) {
    List<TradeRateCreated__e> events = new List<TradeRateCreated__e>();

    for (Vendor_Trade_Rate_Management__c tradeRate : Trigger.new) {
        TradeRateCreated__e event = new TradeRateCreated__e(
            RecordId__c = tradeRate.Id,
            Message__c = 'New Vendor Trade Rate Created!',
            VendorName__c = tradeRate.Vendor__r.Name,    // Assuming lookup to Vendor
            TradeName__c = tradeRate.Trade__r.Name       // Assuming lookup to Trade
        );
        events.add(event);
    }

    if (!events.isEmpty()) {
        EventBus.publish(events);
    }
}