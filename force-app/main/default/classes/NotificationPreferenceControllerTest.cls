@isTest
private class NotificationPreferenceControllerTest {
    @TestSetup
    static void setupTestData() {
        // Get current user's profile
        String profileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()].Profile.Name;
        
        // Create test notification preference
        Notification_Preference__c testPref = new Notification_Preference__c(
            Name = 'Test Preference',
            Email_Notification__c = true,
            Push_Notification__c = true,
            Applicable_Profiles__c = profileName
        );
        insert testPref;
        
        // Create test user notification
        User_Notification__c testUserNotif = new User_Notification__c(
            Notification_Preference__c = testPref.Id,
            User__c = UserInfo.getUserId(),
            Profile__c = profileName,
            Is_Email_Notification__c = true,
            Push_Notification__c = true
        );
        insert testUserNotif;
    }
    
    @isTest
    static void testGetPreferencesWithExistingUserNotification() {
        // Act
        Test.startTest();
        List<Map<String, Object>> result = NotificationPreferenceController.getPreferences();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(0, result.size(), 'Should return at least one preference');
        Map<String, Object> firstPref = result[0];
        System.assertEquals(true, firstPref.get('EmailNotificationEnabled'), 'Email notification should be enabled');
        System.assertEquals(true, firstPref.get('PushNotificationEnabled'), 'Push notification should be enabled');
    }
    
    @isTest
    static void testGetPreferencesWithoutUserNotification() {
        // Setup - Delete existing user notification
        delete [SELECT Id FROM User_Notification__c];
        
        // Act
        Test.startTest();
        List<Map<String, Object>> result = NotificationPreferenceController.getPreferences();
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(0, result.size(), 'Should return at least one preference');
        Map<String, Object> firstPref = result[0];
        // Should fall back to default values from Notification_Preference__c
        System.assertEquals(true, firstPref.get('EmailNotificationEnabled'), 'Should use default email notification value');
        System.assertEquals(true, firstPref.get('PushNotificationEnabled'), 'Should use default push notification value');
    }
    
    @isTest
    static void testUpdatePreferenceExisting() {
        // Setup
        Notification_Preference__c testPref = [SELECT Id FROM Notification_Preference__c LIMIT 1];
        
        // Act
        Test.startTest();
        NotificationPreferenceController.updatePreference(
            testPref.Id,
            'email',
            false,
            false,
            true
        );
        Test.stopTest();
        
        // Assert
        User_Notification__c updatedNotif = [
            SELECT Is_Email_Notification__c, Push_Notification__c
            FROM User_Notification__c
            WHERE Notification_Preference__c = :testPref.Id
            LIMIT 1
        ];
        System.assertEquals(false, updatedNotif.Is_Email_Notification__c, 'Email notification should be updated to false');
        System.assertEquals(true, updatedNotif.Push_Notification__c, 'Push notification should be updated to true');
    }
    
    @isTest
    static void testUpdatePreferenceNew() {
        // Setup
        Notification_Preference__c testPref = [SELECT Id FROM Notification_Preference__c LIMIT 1];
        delete [SELECT Id FROM User_Notification__c];
        
        // Act
        Test.startTest();
        NotificationPreferenceController.updatePreference(
            testPref.Id,
            'email',
            true,
            true,
            false
        );
        Test.stopTest();
        
        // Assert
        User_Notification__c newNotif = [
            SELECT Is_Email_Notification__c, Push_Notification__c
            FROM User_Notification__c
            WHERE Notification_Preference__c = :testPref.Id
            LIMIT 1
        ];
        System.assertEquals(true, newNotif.Is_Email_Notification__c, 'Email notification should be set to true');
        System.assertEquals(false, newNotif.Push_Notification__c, 'Push notification should be set to false');
    }
}