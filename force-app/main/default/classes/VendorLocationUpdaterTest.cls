@isTest
public class VendorLocationUpdaterTest {
    
    @isTest
    static void testUpdateVendorLocations() {
        // Create a test vendor with an address
        Vendor__c vendor = new Vendor__c(
            Name = 'Test Vendor',
            Address__Street__s = '1 Market St',
            Address__City__s = 'San Francisco',
            Address__StateCode__s = 'CA',
            Address__PostalCode__s = '94105',
            Address__CountryCode__s = 'US'
        );
        insert vendor;
        
        // Set up the mock callout
        Test.setMock(HttpCalloutMock.class, new GoogleMapsCalloutMock());
        
        // Start the test
        Test.startTest();
        
        // Call the method to update vendor locations
        Set<Id> vendorIds = new Set<Id>{vendor.Id};
        VendorLocationUpdater.updateVendorLocations(vendorIds);
        
        // End the test
        Test.stopTest();
        
        // Query the vendor to check if the location was updated
        Vendor__c updatedVendor = [SELECT Id, Location__Latitude__s, Location__Longitude__s FROM Vendor__c WHERE Id = :vendor.Id];
        
        // Assert that the location was updated
        // Since we're using a mock, we expect the mock values to be set
        System.assertEquals(37.7749, updatedVendor.Location__Latitude__s, 'Latitude should be updated');
        System.assertEquals(-122.4194, updatedVendor.Location__Longitude__s, 'Longitude should be updated');
    }
    
    // Test the case where the address is null
    @isTest
    static void testUpdateVendorLocationsNullAddress() {
        // Create a test vendor with no address
        Vendor__c vendor = new Vendor__c(
            Name = 'Test Vendor No Address'
        );
        insert vendor;
        
        // Start the test
        Test.startTest();
        
        // Call the method to update vendor locations
        Set<Id> vendorIds = new Set<Id>{vendor.Id};
        VendorLocationUpdater.updateVendorLocations(vendorIds);
        
        // End the test
        Test.stopTest();
        
        // Query the vendor to check if the location was updated
        Vendor__c updatedVendor = [SELECT Id, Location__Latitude__s, Location__Longitude__s FROM Vendor__c WHERE Id = :vendor.Id];
        
        // Assert that the location was not updated (should still be null)
        System.assertEquals(null, updatedVendor.Location__Latitude__s, 'Latitude should not be updated');
        System.assertEquals(null, updatedVendor.Location__Longitude__s, 'Longitude should not be updated');
    }
    
    // Mock class for the Google Maps API callout
    public class GoogleMapsCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            
            // Set the response body to a mock Google Maps API response
            String responseBody = '{"results":[{"geometry":{"location":{"lat":37.7749,"lng":-122.4194}}}],"status":"OK"}';
            response.setBody(responseBody);
            
            return response;
        }
    }
}