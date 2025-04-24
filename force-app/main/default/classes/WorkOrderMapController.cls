public with sharing class WorkOrderMapController {
  // Public property to support the List View
  public List<Work_Order__c> workOrders { get; set; }
  public List<SelectOption> countryOptions { get; set; }
  public List<SelectOption> stateOptions { get; set; }
  public List<SelectOption> tradeOptions { get; set; }
  public List<SelectOption> rangeOptions { get; set; }

  // Constructor: Query work orders along with the related site's location data
  public WorkOrderMapController() {
    countryOptions = getCountryOptions();
    stateOptions = getStateOptions();
    tradeOptions = getTradeOptions();
    rangeOptions = getRangeOptions();
    workOrders = [
      SELECT Id, Name, Status__c, Sites__c, Sites__r.Name , Trade__r.Name , CreatedDate
      FROM Work_Order__c
      WHERE Work_Order_Type__c != 'Child' AND Status__c != 'Resolved'
      ORDER BY CreatedDate DESC
    ];
  }

  @RemoteAction
public static String getFilteredWorkOrders(
  String zip,
  String state,
  String county,
  String city
) {
  System.debug('STATE: ' + state);
  System.debug('COUNTY: ' + county);
  System.debug('CITY: ' + city);

  // Build the query
  String query =
    'SELECT Id, Name, Sites__c, Sites__r.Location__Latitude__s, Sites__r.Location__Longitude__s, ' +
    'Sites__r.Name, Trade__r.Name ' +
    'FROM Work_Order__c WHERE Sites__c != NULL';

  List<String> conditions = new List<String>();

  if (String.isNotBlank(zip)) {
    conditions.add(
      'Sites__r.Address__PostalCode__s = \'' +
        String.escapeSingleQuotes(zip) +
        '\''
    );
  }
  if (String.isNotBlank(state)) {
    conditions.add(
      'Sites__r.Address__StateCode__s = \'' +
        String.escapeSingleQuotes(state) +
        '\''
    );
  }
  if (String.isNotBlank(county)) {
    conditions.add(
      'Sites__r.Address__CountryCode__s = \'' +
        String.escapeSingleQuotes(county) +
        '\''
    );
  }
  if (String.isNotBlank(city)) {
    conditions.add(
      'Sites__r.Address__City__s = \'' +
        String.escapeSingleQuotes(city) +
        '\''
    );
  }

  if (!conditions.isEmpty()) {
    query += ' AND ' + String.join(conditions, ' AND ');
  }

  // Add the query that Work_Order_Type__c not equal to 'Child'
  query += ' AND Work_Order_Type__c != \'Child\'';
  // Add the query that Status__c not equal to 'Resolved'
  query += ' AND Status__c != \'Resolved\'';

  // Execute the query
  List<Work_Order__c> filteredWOs = Database.query(query);

  // Prepare JSON response
  Map<String, Map<String, Object>> siteMap = new Map<String, Map<String, Object>>();

  for (Work_Order__c wo : filteredWOs) {
    if (wo.Sites__c != null && wo.Sites__r != null) {
      if (!siteMap.containsKey(wo.Sites__c)) {
        siteMap.put(
          wo.Sites__c,
          new Map<String, Object>{
            'SiteId' => wo.Sites__c,
            'SiteName' => wo.Sites__r.Name,
            'Latitude' => wo.Sites__r.Location__Latitude__s,
            'Longitude' => wo.Sites__r.Location__Longitude__s,
            'WorkOrders' => new List<Map<String, String>>()
          }
        );
      }

      Map<String, String> workOrder = new Map<String, String>{
        'Id' => wo.Id,
        'Name' => wo.Name,
        'Trade' => wo.Trade__r?.Name != null ? wo.Trade__r.Name : 'Unknown'
      };

      ((List<Map<String, String>>) siteMap.get(wo.Sites__c).get('WorkOrders'))
        .add(workOrder);
    }
  }

  String response = JSON.serialize(siteMap);
  System.debug('RESPONSE: ' + response);
  return response;
}

  // Fetch country picklist values
  public List<SelectOption> getCountryOptions() {
    List<SelectOption> options = new List<SelectOption>();
    // Correct way to describe the field
    Schema.DescribeFieldResult countryFieldDescribe = Schema.Account.fields.BillingCountryCode.getDescribe();

    for (
      Schema.PicklistEntry entry : countryFieldDescribe.getPicklistValues()
    ) {
      options.add(new SelectOption(entry.getValue(), entry.getLabel()));
    }
    return options;
  }

  // Fetch state picklist values
  public List<SelectOption> getStateOptions() {
    List<SelectOption> options = new List<SelectOption>();
    // Correct way to describe the field
    Schema.DescribeFieldResult stateFieldDescribe = Schema.Account.fields.BillingStateCode.getDescribe();

    for (Schema.PicklistEntry entry : stateFieldDescribe.getPicklistValues()) {
      options.add(new SelectOption(entry.getValue(), entry.getLabel()));
    }
    return options;
  }

  // Fetch trade picklist values
  public List<SelectOption> getTradeOptions() {
    tradeOptions = new List<SelectOption>();

    for (Trade__c tradeRec : [SELECT Id, Name FROM Trade__c ORDER BY Name]) {
      tradeOptions.add(new SelectOption(tradeRec.Id, tradeRec.Name));
    }
    return tradeOptions;
  }

  // Fetch range picklist values
  public List<SelectOption> getRangeOptions() {
    // Query the custom metadata for range values
    List<Range_Setting__mdt> rangeRecords = [
      SELECT DeveloperName, Range_Value__c
      FROM Range_Setting__mdt
      ORDER BY Range_Value__c ASC
    ];
    rangeOptions = new List<SelectOption>();
    for (Range_Setting__mdt rangeRec : rangeRecords) {
      rangeOptions.add(
        new SelectOption(
          String.valueOf(rangeRec.Range_Value__c),
          rangeRec.DeveloperName
        )
      );
    }
    return rangeOptions;
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

  @RemoteAction
  public static String getVendorsForSite(String siteId) {
    // 1. Query the Site record (and its location) for the given siteId.
    Sites__c siteRecord = [
      SELECT Id, Name, Location__Latitude__s, Location__Longitude__s
      FROM Sites__c
      WHERE Id = :siteId
      LIMIT 1
    ];

    // 2. Query all Work Orders for this site to extract the trade values.
    List<Work_Order__c> workOrders = [
      SELECT Id, Trade__c, Trade__r.Name
      FROM Work_Order__c
      WHERE Sites__c = :siteId
    ];

    // Get unique trade IDs (assuming Trade__c is a lookup field)
    Set<Id> tradeIds = new Set<Id>();
    for (Work_Order__c wo : workOrders) {
      if (wo.Trade__c != null) {
        tradeIds.add(wo.Trade__c);
      }
    }

    // 3. Query local vendors matching any of the trade IDs.
    List<Vendor__c> localVendors = new List<Vendor__c>();
    if (!tradeIds.isEmpty()) {
      localVendors = [
        SELECT Id, Name, Location__Latitude__s, Location__Longitude__s, Trade__c , Trade__r.Name
        FROM Vendor__c
        WHERE Trade__c IN :tradeIds
      ];
    }

    // Prepare a list for the local vendors response.
    List<Map<String, Object>> localVendorsList = new List<Map<String, Object>>();
    for (Vendor__c v : localVendors) {
      if (
        v.Location__Latitude__s != null &&
        v.Location__Longitude__s != null &&
        siteRecord.Location__Latitude__s != null &&
        siteRecord.Location__Longitude__s != null
      ) {
        Map<String, Object> vendorData = new Map<String, Object>();
        vendorData.put('Id', v.Id);
        vendorData.put('Name', v.Name);
        vendorData.put('Latitude', v.Location__Latitude__s);
        vendorData.put('Longitude', v.Location__Longitude__s);
        vendorData.put('Trade', v.Trade__r.Name);
        // Calculate distance in kilometers
        Double distance = calculateDistance(
          siteRecord.Location__Latitude__s,
          siteRecord.Location__Longitude__s,
          v.Location__Latitude__s,
          v.Location__Longitude__s
        );
        vendorData.put('Distance', distance);
        localVendorsList.add(vendorData);
      }
    }

    // 4. Perform Google Places API search to get additional vendors by trade.
    // For this example, we'll use the first trade found (if any) to search.
    List<Map<String, Object>> googleVendorsList = new List<Map<String, Object>>();
    if (
      !tradeIds.isEmpty() &&
      siteRecord.Location__Latitude__s != null &&
      siteRecord.Location__Longitude__s != null
    ) {
      // For demonstration, assume we use the first trade from the set.
      String tradeForSearch = workOrders[0].Trade__r.Name;
      // Build the Google Places API URL (update YOUR_API_KEY accordingly)
      String googleApiKey = 'AIzaSyDVyQvMGkIBhI8p1rrbq_zWqp97QGyAdKI';
      String location =
        String.valueOf(siteRecord.Location__Latitude__s) +
        ',' +
        String.valueOf(siteRecord.Location__Longitude__s);
      // Define a search radius in meters (e.g., 5000m)
      Integer radius = 5000;
      // Use the trade for search as keyword (you might need to do a separate query to get the trade name)
      String encodedKeyword = EncodingUtil.urlEncode(tradeForSearch, 'UTF-8');
      String endpoint =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=' +
        location +
        '&radius=' +
        radius +
        '&keyword=' +
        encodedKeyword +
        '&key=' +
        googleApiKey;

      // Perform HTTP callout (ensure your class is configured for callouts)
      Http http = new Http();
      HttpRequest req = new HttpRequest();
      req.setEndpoint(endpoint);
      req.setMethod('GET');
      HttpResponse res;
      try {
        res = http.send(req);
      } catch (Exception e) {
        System.debug('HTTP callout error: ' + e.getMessage());
        // If callout fails, leave googleVendorsList empty.
        res = null;
      }
      if (res != null && res.getStatusCode() == 200) {
        // Parse the response JSON
        Map<String, Object> placesResponse = (Map<String, Object>) JSON.deserializeUntyped(
          res.getBody()
        );
        if (placesResponse.containsKey('results')) {
          List<Object> resultsList = (List<Object>) placesResponse.get(
            'results'
          );
          for (Object r : resultsList) {
            Map<String, Object> vendorResult = (Map<String, Object>) r;
            // Get geometry details
            Map<String, Object> geometry = (Map<String, Object>) vendorResult.get(
              'geometry'
            );
            Map<String, Object> locationMap = (Map<String, Object>) geometry.get(
              'location'
            );
            Double lat = (Double) locationMap.get('lat');
            Double lng = (Double) locationMap.get('lng');

            // Build vendor info
            Map<String, Object> vendorData = new Map<String, Object>();
            vendorData.put('Name', vendorResult.get('name'));
            vendorData.put('Address', vendorResult.get('vicinity'));
            vendorData.put('Latitude', lat);
            vendorData.put('Longitude', lng);
            vendorData.put('Trade', tradeForSearch); // Use the trade for search
            // Calculate distance from the site
            Double distance = calculateDistance(
              siteRecord.Location__Latitude__s,
              siteRecord.Location__Longitude__s,
              lat,
              lng
            );
            vendorData.put('Distance', distance);
            googleVendorsList.add(vendorData);
          }
        }
      }
    }

    // 5. Prepare final JSON response with both local and google vendors.
    Map<String, Object> finalResponse = new Map<String, Object>{
      'localVendors' => localVendorsList,
      'googleVendors' => googleVendorsList
    };

    return JSON.serialize(finalResponse);
  }

  // Haversine formula to calculate distance (in kilometers) between two lat/long points.
  public static Double calculateDistance(
    Decimal lat1,
    Decimal lon1,
    Decimal lat2,
    Decimal lon2
  ) {
    // Convert degrees to radians:
    Double radLat1 = lat1.doubleValue() * Math.PI / 180;
    Double radLat2 = lat2.doubleValue() * Math.PI / 180;
    Double deltaLat = (lat2.doubleValue() - lat1.doubleValue()) * Math.PI / 180;
    Double deltaLon = (lon2.doubleValue() - lon1.doubleValue()) * Math.PI / 180;

    // Haversine formula
    Double a =
      Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
      Math.cos(radLat1) * Math.cos(radLat2) * Math.sin(deltaLon / 2) *
      Math.sin(deltaLon / 2);
    Double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    // Earth radius in kilometers (6371 km)
    Double distance = 6371 * c;
    return Math.round(distance * 100) / 100.0;

  }
}