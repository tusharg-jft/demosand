trigger WorkOrderTrigger on Work_Order__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        // Create a list to store work orders that are not of type 'Child'
        List<Work_Order__c> nonChildWorkOrders = new List<Work_Order__c>();
        
        // Iterate through Trigger.new to filter out 'Child' work orders
        for (Work_Order__c wo : Trigger.new) {
            if (wo.Work_Order_Type__c != 'Child') {
                nonChildWorkOrders.add(wo);
            }
        }
        
        // Call the handler only if there are non-child work orders to process
        if (!nonChildWorkOrders.isEmpty()) {
            WorkOrderTriggerHandler.handleAfterInsert(nonChildWorkOrders);
        }
    }
}