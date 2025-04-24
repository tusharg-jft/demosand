public with sharing class VendorTechnicianController {
    // This getter method returns all Vendor__c records.
    // You can reference it in your Visualforce page as {!vendors}.
    public List<Vendor__c> getVendors() {
        return [SELECT Id, Name, Location__Latitude__s, Location__Longitude__s FROM Vendor__c ORDER BY Name];
    }
    
    // RemoteAction method to get technicians by vendor Id.
    // This can be invoked via JavaScript remoting in your Visualforce page.
    @RemoteAction
    public static List<Technician__c> getTechniciansByVendor(String vendorId) {
        return [
            SELECT Id, Name, Location__Latitude__s, Location__Longitude__s FROM Technician__c WHERE Vendor__c = :vendorId
        ];
    }
}