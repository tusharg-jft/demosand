public with sharing class VendorTradeController {

    @AuraEnabled(cacheable=true)
    public static List<Trade__c> getTrades() {
        return [SELECT Id, Name FROM Trade__c];
    }

    // Updated method to return currency fields in a List of Map format
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getCurrencyFields() {
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Vendor_Trade_Rate_Management__c').getDescribe().fields.getMap();
        List<Map<String, String>> currencyFields = new List<Map<String, String>>();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
            
            if (fieldDesc.getType() == Schema.DisplayType.Currency) {
                Map<String, String> fieldInfo = new Map<String, String>();
                fieldInfo.put('apiName', fieldName);
                fieldInfo.put('label', fieldDesc.getLabel());
                currencyFields.add(fieldInfo);
            }
        }
        return currencyFields;
    }

    @AuraEnabled
    public static void saveVendorTradeRate(String vendorId, String tradeId, String corporateId, Map<String, Decimal> currencyValues) {
        // Ensure that the vendor and trade records exist
        List<Vendor__c> vendors = [SELECT Id FROM Vendor__c WHERE Id = :vendorId LIMIT 1];
        if (vendors.isEmpty()) {
            throw new AuraHandledException('Vendor not found.');
        }
        
        List<Trade__c> trades = [SELECT Id FROM Trade__c WHERE Id = :tradeId LIMIT 1];
        if (trades.isEmpty()) {
            throw new AuraHandledException('Trade not found.');
        }
    
        Vendor_Trade_Rate_Management__c rate = new Vendor_Trade_Rate_Management__c();
        rate.Vendor__c = vendorId;
        rate.Trade__c = tradeId;
        
        if (String.isNotBlank(corporateId)) {
            rate.Corporate__c = corporateId;
        }
    
        try {
            // Map the currency values to the rate object
            for (String fieldName : currencyValues.keySet()) {
                if (currencyValues.get(fieldName) != null) {
                    rate.put(fieldName, currencyValues.get(fieldName));
                }
            }
            insert rate;
        } catch (DmlException e) {
            System.debug('Error saving Vendor Trade Rate: ' + e.getMessage());
            System.debug('Error Stack Trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving Vendor Trade Rate: ' + e.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<Trade__c> getVendorTrades(Id vendorId) {
        if (!Schema.sObjectType.Trade__c.isAccessible()) {
            throw new SecurityException('You do not have access to view Trade records.');
        }

        // Query trades linked to the specific vendor via TradeVendor__c
        List<Trade__c> vendorTrades = [
            SELECT Id, Name 
            FROM Trade__c
            WHERE Id IN (
                SELECT Trade__c 
                FROM TradeVendor__c
                WHERE Vendor__c = :vendorId
            )
        ];

        return vendorTrades;
    }

    @AuraEnabled(cacheable=true)
public static List<Trade__c> getTradesByVendor(Id vendorId) {
    if (vendorId == null) {
        throw new IllegalArgumentException('Vendor ID cannot be null');
    }
    
    return [
        SELECT Id, Name
        FROM Trade__c
        WHERE Id IN (
            SELECT Trade__c
            FROM TradeVendor__c
            WHERE Vendor__c = :vendorId
        )
    ];
}

    
    @AuraEnabled(cacheable=true)
public static Map<String, Decimal> getExistingTradeRate(String vendorId, String tradeId) {
    Map<String, Decimal> rateMap = new Map<String, Decimal>();

    List<Vendor_Trade_Rate_Management__c> rates = [
        SELECT Id, Trade__c, Vendor__c
        FROM Vendor_Trade_Rate_Management__c
        WHERE Vendor__c = :vendorId AND Trade__c = :tradeId
    ];

    if (!rates.isEmpty()) {
        Vendor_Trade_Rate_Management__c rate = rates[0];

        // Loop through currency fields and add them to the map
        Map<String, Schema.SObjectField> fieldMap = 
            Schema.getGlobalDescribe().get('Vendor_Trade_Rate_Management__c').getDescribe().fields.getMap();

        for (String fieldName : fieldMap.keySet()) {
            Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();

            // Only add currency fields
            if (fieldDesc.getType() == Schema.DisplayType.Currency && rate.get(fieldName) != null) {
                rateMap.put(fieldName, (Decimal)rate.get(fieldName));
            }
        }
    }

    return rateMap;
}

    
  //VTRM APPROVAL HANDELER
  //
  //
  //
  //
  //

      @AuraEnabled(cacheable=true)
    public static String getVtrmStatus(Id recordId) {
        Vendor_Trade_Rate_Management__c vtrm = [
            SELECT Status__c FROM Vendor_Trade_Rate_Management__c 
            WHERE Id = :recordId 
            LIMIT 1
        ];
        return vtrm.Status__c;
    }
    
    
   @AuraEnabled(cacheable=true)
    public static Boolean isCorporateUser(Id recordId) {
        System.debug('>>> Checking Corporate User or Admin for VTRM ID: ' + recordId);

        Id currentUserId = UserInfo.getUserId();
        String currentUserProfileName;

        try {
            currentUserProfileName = [
                SELECT Profile.Name FROM User WHERE Id = :currentUserId
                LIMIT 1
            ].Profile.Name;
        } catch (Exception e) {
            System.debug('>>> Error fetching User Profile: ' + e.getMessage());
            return false;
        }

        System.debug('>>> Current User Profile: ' + currentUserProfileName);
        System.debug('>>> Current User ID: ' + currentUserId);

        if (currentUserProfileName == 'System Administrator') {
            System.debug('>>> User is an Admin. Showing buttons.');
            return true;
        }

        // Id tradeId;
        // try {
        //     tradeId = [
        //         SELECT Trade__c FROM Vendor_Trade_Rate_Management__c WHERE Id = :recordId LIMIT 1
        //     ].Trade__c;
        // } catch (Exception e) {
        //     System.debug('>>> Error fetching Trade ID: ' + e.getMessage());
        //     return false;
        // }

        // System.debug('>>> Trade ID: ' + tradeId);
        // if (tradeId == null) {
        //     System.debug('>>> No Trade found for this VTRM.');
        //     return false;
        // }

        Id corporateId;
        try {
            corporateId = [
                SELECT Corporate__c FROM Vendor_Trade_Rate_Management__c WHERE Id = :recordId LIMIT 1
            ].Corporate__c;
        } catch (Exception e) {
            System.debug('>>> Error fetching Corporate ID: ' + e.getMessage());
            return false;
        }

        System.debug('>>> Corporate ID: ' + corporateId);
        if (corporateId == null) {
            System.debug('>>> No Corporate found for this Trade.');
            return false;
        }

        Id corporateUserId;
        try {
            corporateUserId = [
                SELECT User__c FROM Corporate__c WHERE Id = :corporateId LIMIT 1
            ].User__c;
        } catch (Exception e) {
            System.debug('>>> Error fetching Corporate User ID: ' + e.getMessage());
            return false;
        }

        System.debug('>>> Corporate User ID: ' + corporateUserId);

        if (corporateUserId == null) {
            System.debug('>>> No Corporate User found.');
            return false;
        }

        Boolean isAuthorized = (corporateUserId == currentUserId);
        System.debug('>>> Final Decision: isCorporateUserOrAdmin = ' + isAuthorized);

        return isAuthorized;
    }


    @AuraEnabled(cacheable=true)
    public static List<Corporate__c> getAllCorporates() {
        return [SELECT Id, Name FROM Corporate__c];
    }

    @AuraEnabled
    public static void processApproval(Id vtrmId, Boolean isApproved) {
        List<Vendor_Trade_Rate_Management__c> vtrmList = [
            SELECT Id, Status__c, Vendor__c, Name
            FROM Vendor_Trade_Rate_Management__c 
            WHERE Id = :vtrmId 
            LIMIT 1
        ];
        
        if (vtrmList.isEmpty()) {
            throw new AuraHandledException('VTRM record not found or inaccessible.');
        }
    
        Vendor_Trade_Rate_Management__c vtrm = vtrmList[0];
        vtrm.Status__c = isApproved ? 'Approved' : 'Declined';
        update vtrm;
    
        // Safe vendor fetch
        List<Vendor__c> vendorList = [SELECT User__c FROM Vendor__c WHERE Id = :vtrm.Vendor__c LIMIT 1];
        if (vendorList.isEmpty()) {
            throw new AuraHandledException('Vendor record not found or inaccessible.');
        }
    
        Id vendorUserId = vendorList[0].User__c;
    
        String  body= 'Trade Rate ' + vtrm.Name + ' has been ' + vtrm.Status__c + ' by ' + UserInfo.getName();
        String title = 'Trade Rate ' + vtrm.Status__c;
    
        NotificationUtility.sendNotification(
            'InvoiceApproval',
            new List<Id>{ vendorUserId },
            vtrmId,
            body,
            title
        );
    }
    
    
}