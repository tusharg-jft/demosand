public class VendorLocationUpdater {
    
    @future(callout=true)
    public static void updateVendorLocations(Set<Id> vendorIds) {
        System.debug('VendorLocationUpdater.updateVendorLocations: Starting location update for vendors: ' + vendorIds);
        
        // Query the vendors with their addresses
        List<Vendor__c> vendors = [
            SELECT Id, Name, Address__c,
                   Address__Street__s, Address__City__s,
                   Address__StateCode__s, Address__PostalCode__s,
                   Address__CountryCode__s,
                   Location__Latitude__s, Location__Longitude__s
            FROM Vendor__c 
            WHERE Id IN :vendorIds
        ];
        
        List<Vendor__c> vendorsToUpdate = new List<Vendor__c>();
        
        for (Vendor__c vendor : vendors) {
            if (vendor.Address__c == null) {
                continue;
            }
            
            String addressStr = buildAddressString(
                vendor.Address__Street__s,
                vendor.Address__City__s,
                vendor.Address__StateCode__s,
                vendor.Address__PostalCode__s,
                vendor.Address__CountryCode__s
            );
            
            if (String.isBlank(addressStr)) {
                continue;
            }
            
            Location loc = getGeocodeFromAddress(addressStr);
            
            if (loc != null) {
                vendor.Location__Latitude__s = loc.getLatitude();
                vendor.Location__Longitude__s = loc.getLongitude();
                vendorsToUpdate.add(vendor);
            }
        }
        
        if (!vendorsToUpdate.isEmpty()) {
            update vendorsToUpdate;
            System.debug('VendorLocationUpdater.updateVendorLocations: Successfully updated ' + vendorsToUpdate.size() + ' vendors');
        }
    }
    
    private static String buildAddressString(String street, String city, String state, String postalCode, String country) {
        List<String> addressParts = new List<String>();
        
        if (!String.isBlank(street)) addressParts.add(street);
        if (!String.isBlank(city)) addressParts.add(city);
        if (!String.isBlank(state)) addressParts.add(state);
        if (!String.isBlank(postalCode)) addressParts.add(postalCode);
        if (!String.isBlank(country)) addressParts.add(country);
        
        return String.join(addressParts, ', ');
    }
    
    private static Location getGeocodeFromAddress(String address) {
        String encodedAddress = EncodingUtil.urlEncode(address, 'UTF-8');
        String apiKey = getGoogleMapsApiKey();
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:GoogleMapsAPI/maps/api/geocode/json?address=' + encodedAddress + '&key=' + apiKey);
        req.setMethod('GET');
        
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                
                if (responseMap.containsKey('results') && !((List<Object>)responseMap.get('results')).isEmpty()) {
                    Map<String, Object> result = (Map<String, Object>) ((List<Object>)responseMap.get('results'))[0];
                    Map<String, Object> geometry = (Map<String, Object>) result.get('geometry');
                    Map<String, Object> locationMap = (Map<String, Object>) geometry.get('location');
                    
                    Double lat = (Double) locationMap.get('lat');
                    Double lng = (Double) locationMap.get('lng');
                    
                    return Location.newInstance(lat, lng);
                }
            }
            return null;
        } catch (Exception e) {
            System.debug('Error in geocoding: ' + e.getMessage());
            return null;
        }
    }
    
    private static String getGoogleMapsApiKey() {
        try {
            API_Key__mdt apiKey = [SELECT Key_Value__c FROM API_Key__mdt WHERE DeveloperName = 'Google_Maps_API' LIMIT 1];
            return apiKey != null && String.isNotBlank(apiKey.Key_Value__c) ? apiKey.Key_Value__c : '';
        } catch (Exception e) {
            System.debug('Error retrieving API key: ' + e.getMessage());
            return '';
        }
    }
}