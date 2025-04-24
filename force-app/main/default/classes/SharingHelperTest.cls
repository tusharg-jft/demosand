@isTest
private class SharingHelperTest {
    @TestSetup
    static void setupTestData() {
        // Create test profiles
        Profile brandProfile = [SELECT Id FROM Profile WHERE Name = 'Brand Profile' LIMIT 1];
        Profile siteProfile = [SELECT Id FROM Profile WHERE Name = 'Site Profile' LIMIT 1];
        Profile corporateProfile = [SELECT Id FROM Profile WHERE Name = 'Corporate Profile' LIMIT 1];
        
        // Create test users
        List<User> testUsers = new List<User>();
        
        User brandUser = new User(
            FirstName = 'Test',
            LastName = 'Brand User',
            Email = 'testbrand@test.com',
            Username = 'testbrand@test.com' + System.currentTimeMillis(),
            ProfileId = brandProfile.Id,
            Alias = 'tbrand',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        testUsers.add(brandUser);
        
        User siteUser = new User(
            FirstName = 'Test',
            LastName = 'Site User',
            Email = 'testsite@test.com',
            Username = 'testsite@test.com' + System.currentTimeMillis(),
            ProfileId = siteProfile.Id,
            Alias = 'tsite',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        testUsers.add(siteUser);
        
        User corporateUser = new User(
            FirstName = 'Test',
            LastName = 'Corporate User',
            Email = 'testcorp@test.com',
            Username = 'testcorp@test.com' + System.currentTimeMillis(),
            ProfileId = corporateProfile.Id,
            Alias = 'tcorp',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Los_Angeles'
        );
        testUsers.add(corporateUser);
        
        insert testUsers;
    }
    
    @isTest
    static void testCreateSiteShare() {
        // Setup
        Sites__c testSite = new Sites__c(Name = 'Test Site');
        insert testSite;
        
        User testUser = [SELECT Id FROM User WHERE LastName = 'Brand User' LIMIT 1];
        
        // Act
        Test.startTest();
        Sites__Share siteShare = SharingHelper.createSiteShare(testSite.Id, testUser.Id);
        insert siteShare;
        Test.stopTest();
        
        // Assert
        Sites__Share insertedShare = [SELECT AccessLevel, RowCause 
                                    FROM Sites__Share 
                                    WHERE ParentId = :testSite.Id 
                                    AND UserOrGroupId = :testUser.Id];
        System.assertEquals('Edit', insertedShare.AccessLevel, 'Access level should be Edit');
        System.assertEquals('Manual', insertedShare.RowCause, 'Row cause should be Manual');
    }
    
    @isTest
    static void testCreateBrandShare() {
        // Setup
        Brand__c testBrand = new Brand__c(Name = 'Test Brand');
        insert testBrand;
        
        User testUser = [SELECT Id FROM User WHERE LastName = 'Brand User' LIMIT 1];
        
        // Act
        Test.startTest();
        Brand__Share brandShare = SharingHelper.createBrandShare(testBrand.Id, testUser.Id);
        insert brandShare;
        Test.stopTest();
        
        // Assert
        Brand__Share insertedShare = [SELECT AccessLevel, RowCause 
                                    FROM Brand__Share 
                                    WHERE ParentId = :testBrand.Id 
                                    AND UserOrGroupId = :testUser.Id];
        System.assertEquals('Edit', insertedShare.AccessLevel, 'Access level should be Edit');
        System.assertEquals('Manual', insertedShare.RowCause, 'Row cause should be Manual');
    }
    
    @isTest
    static void testCreateCorporateShare() {
        // Setup
        Corporate__c testCorporate = new Corporate__c(Name = 'Test Corporate');
        insert testCorporate;
        
        User testUser = [SELECT Id FROM User WHERE LastName = 'Brand User' LIMIT 1];
        
        // Act
        Test.startTest();
        Corporate__Share corporateShare = SharingHelper.createCorporateShare(testCorporate.Id, testUser.Id);
        insert corporateShare;
        Test.stopTest();
        
        // Assert
        Corporate__Share insertedShare = [SELECT AccessLevel, RowCause 
                                        FROM Corporate__Share 
                                        WHERE ParentId = :testCorporate.Id 
                                        AND UserOrGroupId = :testUser.Id];
        System.assertEquals('Read', insertedShare.AccessLevel, 'Access level should be Read');
        System.assertEquals('Manual', insertedShare.RowCause, 'Row cause should be Manual');
    }
    
    @isTest
    static void testGetUsersByProfile() {
        // Act
        Test.startTest();
        List<User> brandUsers = SharingHelper.getBrandUsers();
        List<User> siteUsers = SharingHelper.getSiteUsers();
        List<User> corporateUsers = SharingHelper.getCorporateUsers();
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, brandUsers.size(), 'Should find one brand user');
        System.assertEquals(1, siteUsers.size(), 'Should find one site user');
        System.assertEquals(1, corporateUsers.size(), 'Should find one corporate user');
        
        System.assertEquals('Brand User', brandUsers[0].LastName, 'Should find the brand user');
        System.assertEquals('Site User', siteUsers[0].LastName, 'Should find the site user');
        System.assertEquals('Corporate User', corporateUsers[0].LastName, 'Should find the corporate user');
    }
    
    @isTest
    static void testHasProfileMethods() {
        // Setup
        User brandUser = [SELECT Id FROM User WHERE LastName = 'Brand User' LIMIT 1];
        User siteUser = [SELECT Id FROM User WHERE LastName = 'Site User' LIMIT 1];
        User corporateUser = [SELECT Id FROM User WHERE LastName = 'Corporate User' LIMIT 1];
        
        // Act & Assert
        Test.startTest();
        
        // Test brand profile checks
        System.assert(SharingHelper.hasBrandProfile(brandUser.Id), 'Should identify brand profile');
        System.assert(!SharingHelper.hasBrandProfile(siteUser.Id), 'Should not identify non-brand profile as brand');
        
        // Test site profile checks
        System.assert(SharingHelper.hasSiteProfile(siteUser.Id), 'Should identify site profile');
        System.assert(!SharingHelper.hasSiteProfile(brandUser.Id), 'Should not identify non-site profile as site');
        
        // Test corporate profile checks
        System.assert(SharingHelper.hasCorporateProfile(corporateUser.Id), 'Should identify corporate profile');
        System.assert(!SharingHelper.hasCorporateProfile(brandUser.Id), 'Should not identify non-corporate profile as corporate');
        
        Test.stopTest();
    }
}