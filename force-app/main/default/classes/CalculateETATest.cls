@isTest
private class CalculateETATest {
    @isTest
    static void testCalculateETAInstantiation() {
        // Test instantiation of empty class
        Test.startTest();
        CalculateETA calculator = new CalculateETA();
        Test.stopTest();
        
        // Assert the instance was created
        System.assertNotEquals(null, calculator, 'Should be able to instantiate CalculateETA class');
    }
}