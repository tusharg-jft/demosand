public with sharing class GoogleMapSiteVendorComponent {
  public Work_Order__c workOrder { get; set; }
  public Sites__c site { get; set; }
  public List<VendorWrapper> vendorWrappers { get; set; }
  public List<RangeSettingWrapper> rangeSettings { get; set; }
  public String siteFullAddress { get; set; }

  @RemoteAction
  public static String getNearbyVendors(
    Decimal latitude,
    Decimal longitude,
    String tradeName
  ) {
    try {
      // Google Places API Key – replace with your actual API key.
      String apiKey = 'AIzaSyDVyQvMGkIBhI8p1rrbq_zWqp97QGyAdKI';

      // Format the location query for the Google Places API.
      String location =
        String.valueOf(latitude) +
        ',' +
        String.valueOf(longitude);

      // Define the search radius (in meters).
      Integer radius = 5000; // 5 km radius

      // Encode the trade name to handle spaces or special characters.
      String encodedTradeName = EncodingUtil.urlEncode(tradeName, 'UTF-8');

      // Build the API endpoint URL.
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

      // Check for a successful response.
      if (response.getStatusCode() == 200) {
        // Deserialize the JSON response into an untyped map.
        Map<String, Object> respMap = (Map<String, Object>) JSON.deserializeUntyped(
          response.getBody()
        );
        if (respMap.containsKey('results')) {
          List<Object> resultsList = (List<Object>) respMap.get('results');

          // Loop through each vendor result and compute the distance.
          for (Integer i = 0; i < resultsList.size(); i++) {
            Map<String, Object> vendor = (Map<String, Object>) resultsList[i];
            // Access the vendor's geometry and location.
            Map<String, Object> geometry = (Map<String, Object>) vendor.get(
              'geometry'
            );
            Map<String, Object> loc = (Map<String, Object>) geometry.get(
              'location'
            );
            Decimal vendorLat = (Decimal) loc.get('lat');
            Decimal vendorLng = (Decimal) loc.get('lng');

            // Calculate the distance from the site using our helper.
            Decimal dist = calculateDistanceForGoogle(
              latitude,
              longitude,
              vendorLat,
              vendorLng
            );
            vendor.put('distance', dist);
          }
        }
        return JSON.serialize(respMap);
      } else {
        System.debug('Error: ' + response.getStatus());
        return '{"error": "Failed to fetch vendors"}';
      }
    } catch (Exception e) {
      System.debug('Exception: ' + e.getMessage());
      return '{"error": "' + e.getMessage() + '"}';
    }
  }

  // New helper method to calculate the distance (in km) between two lat/lng points using the Haversine formula.
  public static Decimal calculateDistanceForGoogle(
    Decimal lat1,
    Decimal lon1,
    Decimal lat2,
    Decimal lon2
  ) {
    Decimal R = 6371; // Earth's radius in km
    Decimal dLat = (lat2 - lat1) * Math.PI / 180;
    Decimal dLon = (lon2 - lon1) * Math.PI / 180;
    Decimal a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) *
      Math.cos(lat2 * Math.PI / 180) *
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  // Constructor: gets the work order, its site, and filters vendors by the work order's Trade__c
  public GoogleMapSiteVendorComponent(ApexPages.StandardController controller) {
    Id workOrderId = controller.getId();
    workOrder = [
      SELECT Id, Name, Sites__c, Trade__c, Trade__r.Name
      FROM Work_Order__c
      WHERE Id = :workOrderId
      LIMIT 1
    ];

    if (workOrder.Sites__c != null) {
      site = [
        SELECT
          Id,
          Name,
          Location__Latitude__s,
          Location__Longitude__s,
          Trade__c,
          Address__Street__s,
          Address__City__s,
          Address__StateCode__s,
          Address__PostalCode__s,
          Address__CountryCode__s
        FROM Sites__c
        WHERE Id = :workOrder.Sites__c
        LIMIT 1
      ];
      siteFullAddress =
        (site.Address__Street__s != null
          ? site.Address__Street__s + ', '
          : '') +
        (site.Address__City__s != null ? site.Address__City__s + ', ' : '') +
        (site.Address__StateCode__s != null
          ? site.Address__StateCode__s + ' '
          : '') +
        (site.Address__PostalCode__s != null
          ? site.Address__PostalCode__s + ', '
          : '') +
        (site.Address__CountryCode__s != null
          ? site.Address__CountryCode__s
          : '');
    }

    // Query vendors filtered by the trade on the work order
    List<Vendor__c> vendors = new List<Vendor__c>();
    if (workOrder.Trade__c != null) {
      vendors = [
        SELECT
          Id,
          Name,
          Location__Latitude__s,
          Location__Longitude__s,
          Trade__c,
          Address__Street__s,
          Address__City__s,
          Address__StateCode__s,
          Address__PostalCode__s,
          Address__CountryCode__s
        FROM Vendor__c
        WHERE Trade__c = :workOrder.Trade__c
      ];
    }

    // If a valid site is found, sort vendors by their distance from the site
    if (
      site != null &&
      site.Location__Latitude__s != null &&
      site.Location__Longitude__s != null
    ) {
      vendors.sort(
        new VendorDistanceComparator(
          site.Location__Latitude__s,
          site.Location__Longitude__s
        )
      );
    }

    // Build wrapper list with each vendor’s computed distance from the site
    vendorWrappers = new List<VendorWrapper>();
    for (Vendor__c v : vendors) {
      Decimal dist = calculateDistance(site, v);
      vendorWrappers.add(new VendorWrapper(v, dist));
    }

    // Query the custom metadata for range values
    List<Range_Setting__mdt> rangeRecords = [
      SELECT DeveloperName, Range_Value__c
      FROM Range_Setting__mdt
      ORDER BY Range_Value__c ASC
    ];
    rangeSettings = new List<RangeSettingWrapper>();
    for (Range_Setting__mdt r : rangeRecords) {
      rangeSettings.add(
        new RangeSettingWrapper(r.DeveloperName, r.Range_Value__c)
      );
    }
  }

  // Wrapper class for range metadata
  public class RangeSettingWrapper {
    public String name { get; set; }
    public Decimal rangeValue { get; set; }

    public RangeSettingWrapper(String name, Decimal rangeValue) {
      this.name = name;
      this.rangeValue = rangeValue;
    }
  }

  // Calculates the distance (in km) between the site and vendor using the Haversine formula
  public Decimal calculateDistance(Sites__c s, Vendor__c v) {
    if (
      s == null ||
      v == null ||
      s.Location__Latitude__s == null ||
      s.Location__Longitude__s == null ||
      v.Location__Latitude__s == null ||
      v.Location__Longitude__s == null
    ) {
      return 0;
    }
    Decimal R = 6371; // Earth's radius in km
    Decimal lat1 = s.Location__Latitude__s;
    Decimal lng1 = s.Location__Longitude__s;
    Decimal lat2 = v.Location__Latitude__s;
    Decimal lng2 = v.Location__Longitude__s;
    Decimal dLat = toRadians(lat2 - lat1);
    Decimal dLng = toRadians(lng2 - lng1);
    Decimal a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(toRadians(lat1)) *
      Math.cos(toRadians(lat2)) *
      Math.sin(dLng / 2) * Math.sin(dLng / 2);
    Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  // Helper: converts degrees to radians
  public static Decimal toRadians(Decimal deg) {
    return deg * Math.PI / 180;
  }

  // Wrapper class for vendor records with computed distance
  public class VendorWrapper {
    public Vendor__c vendor { get; set; }
    public Decimal distance { get; set; }
    public String fullAddress { get; set; } // New property

    public VendorWrapper(Vendor__c v, Decimal d) {
      vendor = v;
      distance = d;
      fullAddress =
        (v.Address__Street__s != null ? v.Address__Street__s + ', ' : '') +
        (v.Address__City__s != null ? v.Address__City__s + ', ' : '') +
        (v.Address__StateCode__s != null ? v.Address__StateCode__s + ' ' : '') +
        (v.Address__PostalCode__s != null
          ? v.Address__PostalCode__s + ', '
          : '') +
        (v.Address__CountryCode__s != null ? v.Address__CountryCode__s : '');
    }
  }

  // Comparator to sort Vendor__c records by distance from the given site coordinates
  public class VendorDistanceComparator implements System.Comparator<Vendor__c> {
    public Decimal siteLat;
    public Decimal siteLng;

    public VendorDistanceComparator(Decimal lat, Decimal lng) {
      siteLat = lat;
      siteLng = lng;
    }

    public Integer compare(Vendor__c vendorA, Vendor__c vendorB) {
      Decimal distanceA = calculateDistanceInstance(
        siteLat,
        siteLng,
        vendorA.Location__Latitude__s,
        vendorA.Location__Longitude__s
      );
      Decimal distanceB = calculateDistanceInstance(
        siteLat,
        siteLng,
        vendorB.Location__Latitude__s,
        vendorB.Location__Longitude__s
      );
      if (distanceA == distanceB)
        return 0;
      return distanceA > distanceB ? 1 : -1;
    }

    // Helper method for distance calculation (used in the comparator)
    public Decimal calculateDistanceInstance(
      Decimal lat1,
      Decimal lng1,
      Decimal lat2,
      Decimal lng2
    ) {
      if (lat1 == null || lng1 == null || lat2 == null || lng2 == null)
        return 0;
      Decimal R = 6371;
      Decimal dLat = toRadiansInstance(lat2 - lat1);
      Decimal dLng = toRadiansInstance(lng2 - lng1);
      Decimal a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRadiansInstance(lat1)) *
        Math.cos(toRadiansInstance(lat2)) *
        Math.sin(dLng / 2) * Math.sin(dLng / 2);
      Decimal c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    }

    public Decimal toRadiansInstance(Decimal deg) {
      return deg * Math.PI / 180;
    }
  }
}