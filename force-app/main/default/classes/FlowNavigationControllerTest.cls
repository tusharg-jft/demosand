@isTest
private class FlowNavigationControllerTest {
    @TestSetup
    static void setupTestData() {
        // Create test WorkOrder
        WorkOrder testWorkOrder = new WorkOrder(
            Subject = 'Test Work Order'
        );
        insert testWorkOrder;
    }
    
    @isTest
    static void testSingleWorkOrderUrl() {
        // Setup
        WorkOrder testWorkOrder = [SELECT Id FROM WorkOrder LIMIT 1];
        
        // Act
        Test.startTest();
        List<FlowNavigationController.WorkOrderRedirectResult> results = 
            FlowNavigationController.getWorkOrderRedirectUrl(new List<Id>{testWorkOrder.Id});
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('/' + testWorkOrder.Id, results[0].url, 'URL should match expected format');
    }
    
    @isTest
    static void testMultipleWorkOrderUrls() {
        // Setup
        WorkOrder testWorkOrder1 = new WorkOrder(Subject = 'Test Work Order 1');
        WorkOrder testWorkOrder2 = new WorkOrder(Subject = 'Test Work Order 2');
        insert new List<WorkOrder>{testWorkOrder1, testWorkOrder2};
        
        // Act
        Test.startTest();
        List<FlowNavigationController.WorkOrderRedirectResult> results = 
            FlowNavigationController.getWorkOrderRedirectUrl(new List<Id>{testWorkOrder1.Id, testWorkOrder2.Id});
        Test.stopTest();
        
        // Assert
        System.assertEquals(2, results.size(), 'Should return two results');
        System.assertEquals('/' + testWorkOrder1.Id, results[0].url, 'First URL should match expected format');
        System.assertEquals('/' + testWorkOrder2.Id, results[1].url, 'Second URL should match expected format');
    }
    
    @isTest
    static void testInvalidWorkOrderId() {
        // Setup - Using an invalid ID
        Id invalidId = '0WO000000000000'; // Invalid WorkOrder ID format
        
        // Act
        Test.startTest();
        List<FlowNavigationController.WorkOrderRedirectResult> results = 
            FlowNavigationController.getWorkOrderRedirectUrl(new List<Id>{invalidId});
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('/' + invalidId, results[0].url, 
            'Should still return a URL even for invalid ID as the method does not validate ID existence');
    }
    
    @isTest
    static void testEmptyInput() {
        // Act
        Test.startTest();
        List<FlowNavigationController.WorkOrderRedirectResult> results = 
            FlowNavigationController.getWorkOrderRedirectUrl(new List<Id>());
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }
}