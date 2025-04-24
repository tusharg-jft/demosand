@isTest
private class EstimateControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test contact
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            MailingStreet = '123 Test St',
            MailingCity = 'Test City',
            MailingState = 'Test State',
            MailingPostalCode = '12345',
            MailingCountry = 'Test Country'
        );
        insert testContact;
        
        // Create test estimate
        Estimate__c testEstimate = new Estimate__c(
            Contact__c = testContact.Id,
            Email__c = 'test@example.com',
            Estimate_Date__c = Date.today(),
            Status__c = 'Draft',
            Tax__c = 10
        );
        insert testEstimate;
        
        // Create test products
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true
        );
        insert testProduct;
        
        // Create test estimate line items
        Estimate_Line_Items__c lineItem = new Estimate_Line_Items__c(
            Estimate__c = testEstimate.Id,
            Product__c = testProduct.Id,
            Quantity__c = 2,
            Unit_Price__c = 100
        );
        insert lineItem;
    }
    
    @isTest
    static void testConstructorInitialization() {
        // Setup
        Estimate__c testEstimate = [SELECT Id FROM Estimate__c LIMIT 1];
        
        Test.startTest();
        // Initialize page parameters
        PageReference pageRef = Page.Estimate;
        pageRef.getParameters().put('id', testEstimate.Id);
        Test.setCurrentPage(pageRef);
        
        // Create controller instance
        ApexPages.StandardController sc = new ApexPages.StandardController(testEstimate);
        EstimateController controller = new EstimateController(sc);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, controller.objEstimate, 'Estimate should be initialized');
        System.assertNotEquals(null, controller.estItemList, 'Estimate line items should be initialized');
        System.assertEquals(1, controller.estItemList.size(), 'Should have one line item');
    }
    
    @isTest
    static void testSaveAndEmailFunctionality() {
        // Setup
        Estimate__c testEstimate = [SELECT Id FROM Estimate__c LIMIT 1];
        
        Test.startTest();
        // Initialize page parameters
        PageReference pageRef = Page.Estimate;
        pageRef.getParameters().put('id', testEstimate.Id);
        Test.setCurrentPage(pageRef);
        
        // Create controller instance
        ApexPages.StandardController sc = new ApexPages.StandardController(testEstimate);
        EstimateController controller = new EstimateController(sc);
        
        // Test save method
        controller.save();
        Test.stopTest();
        
        // Assert
        List<ContentDocumentLink> attachments = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :testEstimate.Id
        ];
        System.assertEquals(1, attachments.size(), 'Should create one attachment');
        
        // Verify email was sent
        Integer emailInvocations = Limits.getEmailInvocations();
        System.assertEquals(1, emailInvocations, 'Should send one email');
    }
    
    @isTest
    static void testSaveWithExistingAttachments() {
        // Setup
        Estimate__c testEstimate = [SELECT Id FROM Estimate__c LIMIT 1];
        
        // Create an initial attachment
        ContentVersion initialVersion = new ContentVersion(
            Title = 'R00',
            PathOnClient = 'R00.pdf',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            ContentLocation = 'S'
        );
        insert initialVersion;
        
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :initialVersion.Id].ContentDocumentId;
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testEstimate.Id,
            ContentDocumentId = docId,
            ShareType = 'V'
        );
        insert cdl;
        
        Test.startTest();
        // Initialize page parameters
        PageReference pageRef = Page.Estimate;
        pageRef.getParameters().put('id', testEstimate.Id);
        Test.setCurrentPage(pageRef);
        
        // Create controller instance
        ApexPages.StandardController sc = new ApexPages.StandardController(testEstimate);
        EstimateController controller = new EstimateController(sc);
        
        // Test save method
        controller.save();
        Test.stopTest();
        
        // Assert
        List<ContentDocumentLink> attachments = [
            SELECT ContentDocument.Title 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :testEstimate.Id
            ORDER BY ContentDocument.Title
        ];
        System.assertEquals(2, attachments.size(), 'Should have two attachments');
    }
    
    @isTest
    static void testGetEstimateLine() {
        // Setup
        Estimate__c testEstimate = [SELECT Id FROM Estimate__c LIMIT 1];
        
        Test.startTest();
        // Initialize page parameters
        PageReference pageRef = Page.Estimate;
        pageRef.getParameters().put('id', testEstimate.Id);
        Test.setCurrentPage(pageRef);
        
        // Create controller instance
        ApexPages.StandardController sc = new ApexPages.StandardController(testEstimate);
        EstimateController controller = new EstimateController(sc);
        
        // Test getEstimateLine method
        controller.getEstimateLine(testEstimate.Id);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, controller.estItemList, 'Should retrieve estimate line items');
        System.assertEquals(1, controller.estItemList.size(), 'Should have one line item');
    }
    
    @isTest
    static void testSendMethod() {
        // Setup
        Estimate__c testEstimate = [SELECT Id FROM Estimate__c LIMIT 1];
        
        Test.startTest();
        // Initialize page parameters
        PageReference pageRef = Page.Estimate;
        pageRef.getParameters().put('id', testEstimate.Id);
        Test.setCurrentPage(pageRef);
        
        // Create controller instance
        ApexPages.StandardController sc = new ApexPages.StandardController(testEstimate);
        EstimateController controller = new EstimateController(sc);
        
        // Test send method
        PageReference result = controller.send();
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, result, 'Send method should return null');
    }
}