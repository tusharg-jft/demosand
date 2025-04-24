public class VendorWoTriggerHandler {
    public static void handleAfterInsert(List<VendorWo__c> newVendorWo) {
        List<VendorWO__c> vendorWithRelatedData = [
            SELECT Id, Vendor__c, Vendor__r.User__c, Vendor__r.User__r.Id, Related_Work_Order__c, CreatedBy.Profile.Name, CreatedById
            FROM VendorWO__c 
            WHERE Id IN :newVendorWo
        ];
        system.debug(vendorWithRelatedData);
        List<Work_Order__Share> sharesToCreate = new List<Work_Order__Share>();
        
        for (VendorWO__c vendor : vendorWithRelatedData) {
            // Share with brand user
            if (vendor.CreatedBy.Profile.Name == 'Brand Profile' && vendor.Related_Work_Order__c != null) {
                sharesToCreate.add(SharingHelper.createVendorShare(vendor.Related_Work_Order__c, vendor.Vendor__r.User__r.Id));
            }
            system.debug('sharing record'+ vendor.Vendor__r.User__r.Id);
                        system.debug('sharing related work order record'+ vendor.Related_Work_Order__c);

        }
        
        if (!sharesToCreate.isEmpty()) {
            Database.insert(sharesToCreate, false);
        }
    }
}