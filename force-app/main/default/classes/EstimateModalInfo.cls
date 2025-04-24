public with sharing class EstimateModalInfo {
    @AuraEnabled(Cacheable = true)
    public static Map<String, Object> getEstimateModalInfo(String workorderid) {
        Map<String, Object> response = new Map<String, Object>();

        // Fetch Work Order and validate
        List<Work_Order__c> workOrders = [SELECT Name, Sites__c, Vendor__c FROM Work_Order__c WHERE Id = :workorderid];
        if (workOrders.isEmpty()) {
            throw new AuraHandledException('No Work Order found for the provided ID.');
        }
        Work_Order__c workOrder = workOrders[0];

        // Initialize variables
        Vendor__c vendoruser = null;
        Sites__c siteuser = null;

        // Fetch Vendor Info (Only if Vendor__c is not null)
        if (workOrder.Vendor__c != null) {
            List<Vendor__c> vendors = [SELECT Id, Name, Phone__c, Address__c FROM Vendor__c WHERE Id = :workOrder.Vendor__c];
            if (!vendors.isEmpty()) {
                vendoruser = vendors[0];
            }
        }

        // Fetch Site Info (Only if Sites__c is not null)
        if (workOrder.Sites__c != null) {
            List<Sites__c> sites = [SELECT Id, Name,    Phone__c, Address__c FROM Sites__c WHERE Id = :workOrder.Sites__c];
            if (!sites.isEmpty()) {
                siteuser = sites[0];
            }
        }

        // Add results to response map
        response.put('wo', workOrder);
        response.put('vendoruser', vendoruser);
        response.put('siteuser', siteuser);

        return response;
    }
}
