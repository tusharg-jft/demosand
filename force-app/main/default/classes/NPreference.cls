public with sharing class NPreference {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPreferences() {
        String userId = UserInfo.getUserId();
        System.debug('User ID: ' + userId);
        
        String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;
        System.debug('User Profile Name: ' + userProfileName);
        
        List<Notification_Preference__c> preferences = [
            SELECT Id, Name, Email_Notification__c, Push_Notification__c, Applicable_Profiles__c,
            (SELECT Notification_Preference__c, Is_Email_Notification__c, Push_Notification__c
             FROM User_Notifications__r
             WHERE User__c = :userId)
            FROM Notification_Preference__c
            WHERE Applicable_Profiles__c INCLUDES (:userProfileName)
        ];
        System.debug('Fetched Preferences: ' + preferences);
        
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        
        for (Notification_Preference__c pref : preferences) {
            System.debug('Processing Preference: ' + pref.Id + ', ' + pref.Name);
            
            Map<String, Object> prefMap = new Map<String, Object>();
            prefMap.put('Id', pref.Id);
            prefMap.put('Name', pref.Name);
            
            if (!pref.User_Notifications__r.isEmpty()) {
                User_Notification__c userNotif = pref.User_Notifications__r[0]; // Assuming there’s only one User_Notification record per preference
                System.debug('User Notification Found for Preference: ' + pref.Id);
                
                prefMap.put('EmailNotificationEnabled', userNotif.Is_Email_Notification__c);
                prefMap.put('PushNotificationEnabled', userNotif.Push_Notification__c);
            } else {
                System.debug('No User Notification Found for Preference. Using Default Values.');
                
                prefMap.put('EmailNotificationEnabled', pref.Email_Notification__c);
                prefMap.put('PushNotificationEnabled', pref.Push_Notification__c);
            }
            
            System.debug('Final Preference Map: ' + prefMap);
            result.add(prefMap);
        }
        
        System.debug('Final Result: ' + result);
        return result;
    }
    
    @AuraEnabled
    public static void updatePreference(Id prefId, String type, Boolean enabled, Boolean emailValue, Boolean pushValue) {
        String userId = UserInfo.getUserId();
        
        List<User_Notification__c> existingNotifications = [
            SELECT Id, Is_Email_Notification__c, Push_Notification__c
            FROM User_Notification__c
            WHERE Notification_Preference__c = :prefId AND User__c = :userId
            LIMIT 1
        ];
        
        if (!existingNotifications.isEmpty()) {
            User_Notification__c existingNotification = existingNotifications[0];
            existingNotification.Is_Email_Notification__c = emailValue;
            existingNotification.Push_Notification__c = pushValue;
            update existingNotification;
        } else {
            User_Notification__c newNotification = new User_Notification__c();
            newNotification.Notification_Preference__c = prefId;
            newNotification.User__c = userId;
            newNotification.Is_Email_Notification__c = emailValue;
            newNotification.Push_Notification__c = pushValue;
            insert newNotification;
        }
    }
}