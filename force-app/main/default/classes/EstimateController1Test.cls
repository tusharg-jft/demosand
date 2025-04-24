@isTest
private class EstimateController1Test {
    @TestSetup
    static void setupTestData() {
        // Create test Trade
        Trade__c testTrade = new Trade__c(Name = 'Test Trade');
        insert testTrade;
        
        // Create test Classification
        Classification__c testClassification = new Classification__c(Name = 'Test Classification');
        insert testClassification;
        
        // Create test Issue
        Issue__c testIssue = new Issue__c(Name = 'Test Issue');
        insert testIssue;
        
        // Create test Work Order
        Work_Order__c testWorkOrder = new Work_Order__c(
            Trade__c = testTrade.Id,
            Classification__c = testClassification.Id,
            Issue__c = testIssue.Id
        );
        insert testWorkOrder;
        
        // Create test Estimate
        Estimate__c testEstimate = new Estimate__c(
            Name = 'Test Estimate',
            Work_Orders__c = testWorkOrder.Id,
            Status__c = 'Draft',
            Tax_Amount__c = 100,
            Proposal_For_Repairs__c = 'Test Proposal'
        );
        insert testEstimate;
        
        // Create test Labor records
        List<Labor__c> testLabors = new List<Labor__c>{
            new Labor__c(
                Estimates__c = testEstimate.Id,
                Type__c = 'Incurred for Estimate',
                Quantity__c = 2,
                Technician_Quantity__c = 1,
                Details__c = 'Test Incurred Labor',
                Unit_Price__c = 100
            ),
            new Labor__c(
                Estimates__c = testEstimate.Id,
                Type__c = 'Estimate',
                Quantity__c = 3,
                Technician_Quantity__c = 2,
                Details__c = 'Test Estimate Labor',
                Unit_Price__c = 150
            )
        };
        insert testLabors;
    }
    
    @isTest
    static void testConstructorInitialization() {
        // Setup
        Estimate__c testEstimate = [SELECT Id FROM Estimate__c LIMIT 1];
        
        Test.startTest();
        // Initialize page and controller
        PageReference pageRef = Page.Estimate1;
        pageRef.getParameters().put('id', testEstimate.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testEstimate);
        EstimateController1 controller = new EstimateController1(sc);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, controller.estimate, 'Estimate should be initialized');
        System.assertEquals('Test Estimate', controller.estimate.Name, 'Estimate name should match');
        System.assertEquals(1, controller.incurredLabor.size(), 'Should have one incurred labor record');
        System.assertEquals(1, controller.estimateLabor.size(), 'Should have one estimate labor record');
        
        // Verify labor details
        Labor__c incurredLabor = controller.incurredLabor[0];
        System.assertEquals(2, incurredLabor.Quantity__c, 'Incurred labor quantity should match');
        System.assertEquals(200, incurredLabor.Quantity__c * incurredLabor.Unit_Price__c, 'Incurred labor net price should match');
        
        Labor__c estimateLabor = controller.estimateLabor[0];
        System.assertEquals(3, estimateLabor.Quantity__c, 'Estimate labor quantity should match');
        System.assertEquals(450, estimateLabor.Quantity__c * estimateLabor.Unit_Price__c, 'Estimate labor net price should match');
    }
    
    @isTest
    static void testSaveAsPDFSuccess() {
        // Setup
        Estimate__c testEstimate = [SELECT Id FROM Estimate__c LIMIT 1];
        
        Test.startTest();
        // Initialize page and controller
        PageReference pageRef = Page.Estimate1;
        pageRef.getParameters().put('id', testEstimate.Id);
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(testEstimate);
        EstimateController1 controller = new EstimateController1(sc);
        
        // Test PDF generation
        PageReference result = controller.saveAsPDF();
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, result, 'Should return null to stay on same page');
        
        // Verify ContentVersion was created
        List<ContentVersion> versions = [
            SELECT Id, Title 
            FROM ContentVersion 
            WHERE FirstPublishLocationId = :testEstimate.Id
        ];
        System.assertEquals(1, versions.size(), 'Should create one ContentVersion');
        System.assert(versions[0].Title.startsWith('Test Estimate_Estimate_'), 
            'File name should start with estimate name');
        
        // Verify ContentDocumentLink was created
        List<ContentDocumentLink> links = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :testEstimate.Id
        ];
        System.assertEquals(1, links.size(), 'Should create one ContentDocumentLink');
        
        // Verify success message
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'Should have one message');
        System.assertEquals(ApexPages.Severity.CONFIRM, messages[0].getSeverity(), 
            'Should be a confirmation message');
    }
    
    @isTest
    static void testSaveAsPDFError() {
        // Setup - Create an invalid estimate ID to force an error
        Id invalidId = '001000000000000'; // Invalid ID
        
        Test.startTest();
        // Initialize page and controller with invalid ID
        PageReference pageRef = Page.Estimate1;
        pageRef.getParameters().put('id', invalidId);
        Test.setCurrentPage(pageRef);
        
        Estimate__c invalidEstimate = new Estimate__c(Id = invalidId);
        ApexPages.StandardController sc = new ApexPages.StandardController(invalidEstimate);
        
        try {
            EstimateController1 controller = new EstimateController1(sc);
            PageReference result = controller.saveAsPDF();
        } catch (Exception e) {
            // Verify error handling
            List<ApexPages.Message> messages = ApexPages.getMessages();
            System.assert(!messages.isEmpty(), 'Should have error messages');
            
            Boolean hasErrorMessage = false;
            for (ApexPages.Message msg : messages) {
                if (msg.getSeverity() == ApexPages.Severity.ERROR) {
                    hasErrorMessage = true;
                    break;
                }
            }
            System.assert(hasErrorMessage, 'Should have an error message');
        }
        Test.stopTest();
    }
}