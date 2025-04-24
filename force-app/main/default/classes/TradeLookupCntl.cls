/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-23-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class TradeLookupCntl {
    @InvocableMethod(label='Get Trades' category='Trade')
    public static List<outputVariable> getTrades(List<TradeLookupRequest> requests) {
        List<outputVariable> outputList = new List<outputVariable>();
        System.debug('Entering getTrades method.');

        if (requests == null || requests.isEmpty()) {
            System.debug('Requests list is null or empty. Returning empty list.');
            return outputList; 
        }

        for (TradeLookupRequest req : requests) {
            System.debug('Processing request for userId: ' + req.userId + ', profileName: ' + req.profileName);

            try {
                List<Trade__c> trades = new List<Trade__c>(); 

                // Commenting out profile-specific logic to return all trades regardless of profile
                /*
                if (req.profileName == 'Site Profile') {
                    System.debug('Profile is FM Site User. Calling getTradesForFMSiteUser.');
                    trades = getTradesForFMSiteUser(req.userId);
                    System.debug('Found ' + trades.size() + ' trades for FM Site User.');
                } else if (req.profileName == 'Corporate Profile') {
                    System.debug('Profile is Corporate. Calling getTradesForCorporateUser.');
                    trades = getTradesForCorporateUser(req.userId);
                    System.debug('Found ' + trades.size() + ' trades for Corporate.');
                } else if (req.profileName == 'Brand Profile') {
                    System.debug('Profile is Brand. Calling getTradesForBrandUser.');
                    trades = getTradesForBrandUser(req.userId);
                    System.debug('Found ' + trades.size() + ' trades for Brand.');
                } else {
                    System.debug('Profile not recognized: ' + req.profileName);
                }
                */

                // Fetch all trade records regardless of user profile
                trades = [
                    SELECT Id, Name
                    FROM Trade__c
                ];
                System.debug('Retrieved ' + trades.size() + ' trades for all profiles');

                outputVariable output = new outputVariable();
                output.tradeRecords = trades;
                outputList.add(output); 

            } catch (Exception e) {
                System.debug('Error for user ' + req.userId + ' and profile ' + req.profileName + ': ' + e.getMessage());
                System.debug('Stack Trace: ' + e.getStackTraceString());
            }
        }

        System.debug('Returning ' + outputList.size() + ' output records.');
        return outputList; 
    }

    // Commented out profile-specific method to preserve for future use
    /*
    public static List<Trade__c> getTradesForFMSiteUser(Id userId) {
        List<Trade__c> trades = new List<Trade__c>();
        System.debug('Entering getTradesForFMSiteUser for userId: ' + userId);

        try {
            Sites__c site = [SELECT Corporate__c FROM Sites__c WHERE Site_User__c = :userId LIMIT 1];
            System.debug('Retrieved site for userId ' + userId + ': ' + site);
            if (site != null) {
                trades = [
                    SELECT Id, Name
                    FROM Trade__c
                    WHERE Corporate__c = :site.Corporate__c
                ];
                System.debug('Retrieved ' + trades.size() + ' trades for Corporate: ' + site.Corporate__c);
            } else {
                System.debug('No site found for userId ' + userId);
            }
        } catch (Exception e) {
            System.debug('Error fetching trades for Site User: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }

        return trades;
    }
    */

    // Commented out profile-specific method to preserve for future use
    /*
    public static List<Trade__c> getTradesForCorporateUser(Id userId) {
        List<Trade__c> trades = new List<Trade__c>();
        System.debug('Entering getTradesForCorporateUser for userId: ' + userId);

        try {
            Corporate__c corp = [SELECT Id FROM Corporate__c WHERE User__c = :userId LIMIT 1];
            System.debug('Retrieved Corporate for userId ' + userId + ': ' + corp);

            if (corp != null) {
                trades = [
                    SELECT Id, Name
                    FROM Trade__c
                    WHERE Corporate__c = :corp.Id
                ];
                System.debug('Retrieved ' + trades.size() + ' trades for Corporate: ' + corp.Id);
            } else {
                System.debug('No Corporate found for userId ' + userId);
            }
        } catch (Exception e) {
            System.debug('Error fetching trades for Corporate User: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }
        return trades;
    }
    */

    // Commented out profile-specific method to preserve for future use
    /*
    public static List<Trade__c> getTradesForBrandUser(Id userId) {
        List<Trade__c> trades = new List<Trade__c>();
        System.debug('Entering getTradesForBrandUser for userId: ' + userId);

        try {
            trades = [
                SELECT Id, Name
                FROM Trade__c
            ];
            System.debug('Retrieved ' + trades.size() + ' trades for Brand Profile');
        } catch (Exception e) {
            System.debug('Error fetching trades for Brand User: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }

        return trades;
    }
    */

    public class TradeLookupRequest {
        @InvocableVariable(label='User Id')
        public Id userId;

        @InvocableVariable(label='Profile Name')
        public String profileName;
    }

    public class outputVariable {
        @InvocableVariable(label='Trade Records')
        public List<Trade__c> tradeRecords; 
    }
}