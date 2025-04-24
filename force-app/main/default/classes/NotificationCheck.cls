public class NotificationCheck {
    @InvocableMethod(label='Check Notification Preference')
    public static List<Boolean> checkPreference(List<Input> inputs) {
        List<Boolean> results = new List<Boolean>();

        Set<Id> userIds = new Set<Id>();
        Set<String> notificationTypes = new Set<String>();
        
        for (Input input : inputs) {
            if (input.userIds != null) {
                userIds.addAll(input.userIds);
            } else {
                userIds.add(input.userId);
            }
            notificationTypes.add(input.notificationType);
        }

        Map<Id, Map<String, User_Notification__c>> userPreferencesMap = new Map<Id, Map<String, User_Notification__c>>();
        for (User_Notification__c userPref : [
            SELECT User__c, Preference_Name__c, Is_Email_Notification__c, Push_Notification__c
            FROM User_Notification__c
            WHERE User__c IN :userIds AND Preference_Name__c IN :notificationTypes
        ]) {
            if (!userPreferencesMap.containsKey(userPref.User__c)) {
                userPreferencesMap.put(userPref.User__c, new Map<String, User_Notification__c>());
            }
            userPreferencesMap.get(userPref.User__c).put(userPref.Preference_Name__c, userPref);
        }

        Map<String, Notification_Preference__c> defaultPreferencesMap = new Map<String, Notification_Preference__c>();
        for (Notification_Preference__c defaultPref : [
            SELECT Name, Email_Notification__c, Push_Notification__c
            FROM Notification_Preference__c
            WHERE Name IN :notificationTypes
        ]) {
            defaultPreferencesMap.put(defaultPref.Name, defaultPref);
        }

        for (Input input : inputs) {
            Boolean sendNotification = shouldSendNotification(input.userId, input.notificationType, input.notificationChannel,
                userPreferencesMap, defaultPreferencesMap);
            results.add(sendNotification);
        }

        return results;
    }

    public class Input {
        @InvocableVariable(required=false)
        public Id userId;  
        
        @InvocableVariable(required=false)
        public List<Id> userIds;  
        
        @InvocableVariable(required=true)
        public String notificationType;
        
        @InvocableVariable(required=true)
        public String notificationChannel;
    }

    private static Boolean shouldSendNotification(Id userId, String notificationType, String notificationChannel,
        Map<Id, Map<String, User_Notification__c>> userPreferencesMap, 
        Map<String, Notification_Preference__c> defaultPreferencesMap) {

        if (userPreferencesMap.containsKey(userId) && userPreferencesMap.get(userId).containsKey(notificationType)) {
            User_Notification__c userPref = userPreferencesMap.get(userId).get(notificationType);
            if (notificationChannel == 'Email') {
                return userPref.Is_Email_Notification__c;
            } else if (notificationChannel == 'Push') {
                return userPref.Push_Notification__c;
            }
        }

        if (defaultPreferencesMap.containsKey(notificationType)) {
            Notification_Preference__c defaultPref = defaultPreferencesMap.get(notificationType);
            if (notificationChannel == 'Email') {
                return defaultPref.Email_Notification__c;
            } else if (notificationChannel == 'Push') {
                return defaultPref.Push_Notification__c;
            }
        }
        return false;  
    }
}