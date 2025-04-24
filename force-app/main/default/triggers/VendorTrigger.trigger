trigger VendorTrigger on Vendor__c (after insert) {
    System.debug('VendorTrigger: Trigger executed with operation: ' + Trigger.operationType);
    System.debug('VendorTrigger: Number of records in Trigger.new: ' + Trigger.new.size());
    
    // Create a list to hold records that need geocoding
    List<Vendor__c> vendorsToUpdate = new List<Vendor__c>();
    
    for (Vendor__c vendor : Trigger.new) {
        System.debug('VendorTrigger: Processing vendor with ID: ' + vendor.Id);
        system.debug('Address'+ vendor.Address__City__s);
        
        // For inserts, add all records with an address
        if (vendor.Address__City__s != null) {
            System.debug('VendorTrigger: New vendor with address: ' + vendor.Id);
            vendorsToUpdate.add(vendor);
        } else {
            System.debug('VendorTrigger: New vendor without address: ' + vendor.Id);
        }
    }
    
    System.debug('VendorTrigger: Found ' + vendorsToUpdate.size() + ' vendors that need location updates');
    
    if (!vendorsToUpdate.isEmpty()) {
        Set<Id> vendorIds = new Set<Id>();
        for (Vendor__c vendor : vendorsToUpdate) {
            vendorIds.add(vendor.Id);
        }
        
        System.debug('VendorTrigger: Calling VendorLocationUpdater.updateVendorLocations with ' + vendorIds.size() + ' vendor IDs');
        VendorLocationUpdater.updateVendorLocations(vendorIds);
        System.debug('VendorTrigger: Successfully called future method');
    } else {
        System.debug('VendorTrigger: No vendors need location updates');
    }
    
    System.debug('VendorTrigger: Trigger execution completed');
}