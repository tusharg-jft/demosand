public with sharing class NotificationPreferenceController {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPreferences() {
        //fetching the current user Id
        String userId = UserInfo.getUserId();
        // getting the current user profile name
        String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;
        
        //nested query to get the user notification based on the current user and the notifcation available for the current user profile. 
        List<Notification_Preference__c> preferences = [
            SELECT Id, Name, Email_Notification__c, Push_Notification__c, Applicable_Profiles__c,
            (SELECT Notification_Preference__c, Is_Email_Notification__c, Push_Notification__c
             FROM User_Notifications__r
             WHERE User__c = :userId)
            FROM Notification_Preference__c
            WHERE Applicable_Profiles__c INCLUDES (:userProfileName)
        ];
        
        // the final map to store the result. 
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        
        for (Notification_Preference__c pref : preferences) {
            
            //map to store the neccasary feidls of preference to filter user notification
            Map<String, Object> prefMap = new Map<String, Object>();
            prefMap.put('Id', pref.Id);
            prefMap.put('Name', pref.Name);
            
            if (!pref.User_Notifications__r.isEmpty()) {
                User_Notification__c userNotif = pref.User_Notifications__r[0];
                
                //if user notification is found pass the neccsary values from user notification to the component.
                prefMap.put('EmailNotificationEnabled', userNotif.Is_Email_Notification__c);
                prefMap.put('PushNotificationEnabled', userNotif.Push_Notification__c);
                
                // if no user notification record found pass the default values to the component.
            } else {
                System.debug('No User Notification Found for Preference. Using Default Values.');
                
                prefMap.put('EmailNotificationEnabled', pref.Email_Notification__c);
                prefMap.put('PushNotificationEnabled', pref.Push_Notification__c);
            }
            
            result.add(prefMap);
        }
        
        return result;
    }
    
    //method to create or update the user_notification__c record accordingly.
    @AuraEnabled
    public static void updatePreference(Id prefId, String type, Boolean enabled, Boolean emailValue, Boolean pushValue) {
        String userId = UserInfo.getUserId();
        String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :userId].Profile.Name;
        
        
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
            newNotification.Profile__c = userProfileName;
            newNotification.Is_Email_Notification__c = emailValue;
            newNotification.Push_Notification__c = pushValue;
            insert newNotification;
        }
    }
}