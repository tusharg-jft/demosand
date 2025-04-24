public with sharing class VendorWoController {
    
    @AuraEnabled(cacheable=true)
    public static List<VendorWO__c> getVendorWoRecords(Id workOrderId) {
        try {
            return [
                SELECT Id, 
                Vendor__c, 
                Vendor__r.Name, 
                Vendor_Status__c,
                Trade__c,
                Trade__r.Name,
                Work_Order__r.WorkOrderNumber 
                FROM VendorWO__c 
                WHERE Work_Order__c = :workOrderId
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Vendor Work Orders: ' + e.getMessage());
        }
    }
}