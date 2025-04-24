/**
* @description       : 
* @author            : ChangeMeIn@UserSettingsUnder.SFDoc
* @group             : 
* @last modified on  : 04-09-2025
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class VendorController {
    // Wrapper Class for Vendors with Distance
    public class VendorWrapper {
        @AuraEnabled
        public Id vendorId;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String address;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public Decimal latitude;
        @AuraEnabled
        public Decimal longitude;
        @AuraEnabled
        public Decimal distance;
        
        // Constructor
        public VendorWrapper(Vendor__c vendor, Decimal distance) {
            this.vendorId = vendor.Id;
            this.name = vendor.Name;
            this.address =
                vendor.Address__Street__s +
                ', ' +
                vendor.Address__City__s +
                ', ' +
                vendor.Address__StateCode__s +
                ', ' +
                vendor.Address__PostalCode__s +
                ', ' +
                vendor.Address__CountryCode__s;
            this.status = vendor.Status__c;
            this.latitude = vendor.Location__Latitude__s;
            this.longitude = vendor.Location__Longitude__s;
            this.distance = distance;
        }
    }
    
    // Fetch Vendors and Calculate Distance
    @AuraEnabled(cacheable=true)
    public static List<VendorWrapper> getVendorsByWorkOrder(Id workOrderId) {
        // Fetch Work Order and associated Site
        Work_Order__c workOrder = [
            SELECT Id, Trade__c, Sites__c
            FROM Work_Order__c
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        
        if (
            workOrder == null ||
            workOrder.Trade__c == null ||
            workOrder.Sites__c == null
        ) {
            throw new AuraHandledException(
                'Invalid Work Order: Missing Trade or Site'
            );
        }
        
        // Fetch Site Location
        Sites__c site = [
            SELECT Id, Location__Latitude__s, Location__Longitude__s
            FROM Sites__c
            WHERE Id = :workOrder.Sites__c
            LIMIT 1
        ];
        
        if (
            site == null ||
            site.Location__Latitude__s == null ||
            site.Location__Longitude__s == null
        ) {
            throw new AuraHandledException('Site location is missing.');
        }
        
        // Fetch Vendors matching Trade
        List<Vendor__c> vendors = [
            SELECT
            Id,
            Name,
            Address__Street__s,
            Address__City__s,
            Address__StateCode__s,
            Address__PostalCode__s,
            Address__CountryCode__s,
            Status__c,
            Location__Latitude__s,
            Location__Longitude__s
            FROM Vendor__c
            WHERE Trade__c = :workOrder.Trade__c
            ORDER BY Name ASC
        ];
        
        List<VendorWrapper> vendorList = new List<VendorWrapper>();
        
        // Calculate Distance for each Vendor
        for (Vendor__c vendor : vendors) {
            Decimal distance = (vendor.Location__Latitude__s != null &&
                                vendor.Location__Longitude__s != null)
                ? calculateDistance(
                    site.Location__Latitude__s,
                    site.Location__Longitude__s,
                    vendor.Location__Latitude__s,
                    vendor.Location__Longitude__s
                )
                : null;
            
            vendorList.add(new VendorWrapper(vendor, distance));
        }
        
        return vendorList;
    }
    
    // Fetch Site by Work Order
    @AuraEnabled(cacheable=true)
    public static Sites__c getSiteByWorkOrder(Id workOrderId) {
        Work_Order__c workOrder = [
            SELECT Id, Sites__c
            FROM Work_Order__c
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        
        if (workOrder.Sites__c == null) {
            throw new AuraHandledException('No Site found on this Work Order.');
        }
        
        Sites__c site = [
            SELECT Id, Location__Latitude__s, Location__Longitude__s
            FROM Sites__c
            WHERE Id = :workOrder.Sites__c
            LIMIT 1
        ];
        
        if (
            site.Location__Latitude__s == null ||
            site.Location__Longitude__s == null
        ) {
            throw new AuraHandledException('Site location is missing.');
        }
        
        return site;
    }
    
    // Fetch Nearby Vendors from Google Places API
    @AuraEnabled
    public static String getGoogleVendors(Id workOrderId) {
        Sites__c site = getSiteByWorkOrder(workOrderId);
        
        Work_Order__c workOrder = [
            SELECT Id, Trade__c, Trade__r.Name
            FROM Work_Order__c
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        
        if (workOrder.Trade__c == null) {
            throw new AuraHandledException('No Trade specified on this Work Order.');
        }
        
        return getNearbyVendors(
            site.Location__Latitude__s,
            site.Location__Longitude__s,
            workOrder.Trade__r.Name
        );
    }
    
    // Call Google Places API
    private static String getNearbyVendors(
        Decimal latitude,
        Decimal longitude,
        String tradeName
    ) {
        try {
            String apiKey = 'AIzaSyDVyQvMGkIBhI8p1rrbq_zWqp97QGyAdKI';
            String location =
                String.valueOf(latitude) +
                ',' +
                String.valueOf(longitude);
            Integer radius = 5000; // 5 km radius
            String encodedTradeName = EncodingUtil.urlEncode(tradeName, 'UTF-8');
            
            String endpoint =
                'https://maps.googleapis.com/maps/api/place/nearbysearch/json?' +
                'location=' +
                location +
                '&radius=' +
                radius +
                '&keyword=' +
                encodedTradeName +
                '&key=' +
                apiKey;
            
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(
                    response.getBody()
                );
                
                if (respMap.containsKey('results')) {
                    List<Object> resultsList = (List<Object>) respMap.get('results');
                    List<Object> limitedResults = new List<Object>();
                    
                    Integer maxResults = Math.min(10, resultsList.size()); // Ensure we do not exceed available vendors
                    
                    for (Integer i = 0; i < maxResults; i++) {
                        Map<String, Object> vendor = (Map<String, Object>) resultsList[i];
                        Map<String, Object> geometry = (Map<String, Object>) vendor.get(
                            'geometry'
                        );
                        Map<String, Object> loc = (Map<String, Object>) geometry.get(
                            'location'
                        );
                        
                        Decimal vendorLat = (Decimal) loc.get('lat');
                        Decimal vendorLng = (Decimal) loc.get('lng');
                        
                        Decimal dist = calculateDistance(
                            latitude,
                            longitude,
                            vendorLat,
                            vendorLng
                        );
                        vendor.put('distance', dist);
                        
                        limitedResults.add(vendor);
                    }
                    
                    respMap.put('results', limitedResults);
                }
                
                return JSON.serialize(respMap);
            } else {
                return '{"error": "Failed to fetch vendors"}';
            }
        } catch (Exception e) {
            return '{"error": "' + e.getMessage() + '"}';
        }
    }
    
    // Distance Calculation (Haversine Formula)
    private static Decimal calculateDistance(
        Decimal lat1,
        Decimal lon1,
        Decimal lat2,
        Decimal lon2
    ) {
        Decimal R = 6371; // Earth radius in km
        Decimal dLat = degreesToRadians(lat2 - lat1);
        Decimal dLon = degreesToRadians(lon2 - lon1);
        Decimal a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(degreesToRadians(lat1)) *
            Math.cos(degreesToRadians(lat2)) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
    
    // Convert Degrees to Radians
    private static Decimal degreesToRadians(Decimal degrees) {
        Decimal pi = 3.141592653589793;
        return degrees * pi / 180;
    }
    @AuraEnabled
    public static void createTaskForVendor(Id workOrderId) {
        work_Order__c wO = [Select id,Sites__c from work_Order__c where id =:workOrderId];
        system.debug('work order'+wO);
        List<sites__c> site =[select id, brandUser__c,CorpUser__c from Sites__c Where id =:wO.Sites__c];
                system.debug('site'+site);

        Id BrandUserId = site[0].BrandUser__c;
        system.debug('BrandUserId'+BrandUserId);
        List<Id> userIds = new List<Id>();
        for(Sites__c sites :site){
            userIds.add( sites.BrandUser__c);
            userIds.add( sites.CorpUser__c);       
        }
        system.debug('userIds'+userIds);
        Task t = new Task(
            Subject = 'External vendor is assigned to work order please take necessary actions',
            Priority = 'High',
            Status = 'In Progress',
            WhatId = workOrderId
        );
        insert t;
        NotificationUtility.sendNotification('External_Vendor_Assigned',  userIds,  workOrderId ,'External Vendor is Assigned to the work Order','External Vendor Assigned');
        
    }
}