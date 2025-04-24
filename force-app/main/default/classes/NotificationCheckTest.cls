@isTest
private class NotificationCheckTest {
    @TestSetup
    static void setupTestData() {
        // Create test notification preferences
        List<Notification_Preference__c> preferences = new List<Notification_Preference__c>{
            new Notification_Preference__c(
                Name = 'Test_Notification',
                Email_Notification__c = true,
                Push_Notification__c = false
            ),
            new Notification_Preference__c(
                Name = 'Another_Notification',
                Email_Notification__c = false,
                Push_Notification__c = true
            )
        };
        insert preferences;
        
        // Create test users
        List<User> testUsers = new List<User>();
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        for(Integer i = 0; i < 2; i++) {
            User u = new User(
                FirstName = 'Test',
                LastName = 'User ' + i,
                Email = 'testuser' + i + '@test.com',
                Username = 'testuser' + i + '@test.com' + System.currentTimeMillis(),
                ProfileId = p.Id,
                Alias = 'tuser' + i,
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Los_Angeles'
            );
            testUsers.add(u);
        }
        insert testUsers;
        
        // Create user notifications for first user only
        List<User_Notification__c> userNotifications = new List<User_Notification__c>{
            new User_Notification__c(
                User__c = testUsers[0].Id,
                Notification_Preference__c = preferences[0].Id,
                Is_Email_Notification__c = false,
                Push_Notification__c = true
            ),
            new User_Notification__c(
                User__c = testUsers[0].Id,
                Notification_Preference__c = preferences[1].Id,
                Is_Email_Notification__c = true,
                Push_Notification__c = false
            )
        };
        insert userNotifications;
    }
    
    @isTest
    static void testSingleUserWithCustomPreference() {
        // Setup
        User testUser = [SELECT Id FROM User WHERE LastName = 'User 0' LIMIT 1];
        
        NotificationCheck.Input input = new NotificationCheck.Input();
        input.userId = testUser.Id;
        input.notificationType = 'Test_Notification';
        input.notificationChannel = 'Push';
        
        // Act
        Test.startTest();
        List<Boolean> results = NotificationCheck.checkPreference(new List<NotificationCheck.Input>{input});
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0], 'Should return true for push notification');
        
        // Test email channel
        input.notificationChannel = 'Email';
        results = NotificationCheck.checkPreference(new List<NotificationCheck.Input>{input});
        System.assertEquals(false, results[0], 'Should return false for email notification');
    }
    
    @isTest
    static void testMultipleUsers() {
        // Setup
        List<User> testUsers = [SELECT Id FROM User WHERE LastName LIKE 'User %' ORDER BY LastName];
        
        NotificationCheck.Input input = new NotificationCheck.Input();
        input.userIds = new List<Id>{testUsers[0].Id, testUsers[1].Id};
        input.notificationType = 'Test_Notification';
        input.notificationChannel = 'Email';
        
        // Act
        Test.startTest();
        List<Boolean> results = NotificationCheck.checkPreference(new List<NotificationCheck.Input>{input});
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0], 'Should return false for first user email notification');
    }
    
    @isTest
    static void testFallbackToDefaultPreference() {
        // Setup
        User testUser = [SELECT Id FROM User WHERE LastName = 'User 1' LIMIT 1];
        
        NotificationCheck.Input input = new NotificationCheck.Input();
        input.userId = testUser.Id;
        input.notificationType = 'Test_Notification';
        input.notificationChannel = 'Email';
        
        // Act
        Test.startTest();
        List<Boolean> results = NotificationCheck.checkPreference(new List<NotificationCheck.Input>{input});
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(true, results[0], 'Should return true from default preference');
    }
    
    @isTest
    static void testInvalidNotificationType() {
        // Setup
        User testUser = [SELECT Id FROM User WHERE LastName = 'User 0' LIMIT 1];
        
        NotificationCheck.Input input = new NotificationCheck.Input();
        input.userId = testUser.Id;
        input.notificationType = 'Invalid_Notification';
        input.notificationChannel = 'Email';
        
        // Act
        Test.startTest();
        List<Boolean> results = NotificationCheck.checkPreference(new List<NotificationCheck.Input>{input});
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0], 'Should return false for invalid notification type');
    }
    
    @isTest
    static void testDifferentNotificationTypes() {
        // Setup
        User testUser = [SELECT Id FROM User WHERE LastName = 'User 0' LIMIT 1];
        
        List<NotificationCheck.Input> inputs = new List<NotificationCheck.Input>();
        
        NotificationCheck.Input input1 = new NotificationCheck.Input();
        input1.userId = testUser.Id;
        input1.notificationType = 'Test_Notification';
        input1.notificationChannel = 'Push';
        inputs.add(input1);
        
        NotificationCheck.Input input2 = new NotificationCheck.Input();
        input2.userId = testUser.Id;
        input2.notificationType = 'Another_Notification';
        input2.notificationChannel = 'Email';
        inputs.add(input2);
        
        // Act
        Test.startTest();
        List<Boolean> results = NotificationCheck.checkPreference(inputs);
        Test.stopTest();
        
        // Assert
        System.assertEquals(2, results.size(), 'Should return two results');
        System.assertEquals(true, results[0], 'Should return true for Test_Notification push');
        System.assertEquals(true, results[1], 'Should return true for Another_Notification email');
    }
}