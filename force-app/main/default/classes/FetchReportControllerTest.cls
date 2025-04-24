@isTest
private class FetchReportControllerTest {
    @isTest
    static void testGetReportIdSuccess() {
        // Setup
        String reportName = 'Test_Report';
        String reportId = '00OB0000000XXXX'; // Dummy report Id
        
        // Create a mock Report record
        Report mockReport = (Report)JSON.deserialize(
            '{"Id": "' + reportId + '", "DeveloperName": "' + reportName + '"}',
            Report.class
        );
        
        // Set up the mock
        Test.startTest();
        MockReportSelector mockSelector = new MockReportSelector(new List<Report>{mockReport});
        ReportSelector.instance = mockSelector;
        
        // Act
        String result = FetchReportController.getReportIdByApiName(reportName);
        Test.stopTest();
        
        // Assert
        System.assertEquals(reportId, result, 'Should return the correct report ID');
    }
    
    @isTest
    static void testGetReportIdNotFound() {
        // Set up the mock with empty list
        Test.startTest();
        MockReportSelector mockSelector = new MockReportSelector(new List<Report>());
        ReportSelector.instance = mockSelector;
        
        try {
            String result = FetchReportController.getReportIdByApiName('Nonexistent_Report');
            System.assert(false, 'Should throw an exception for nonexistent report');
        } catch (AuraHandledException e) {
            System.assertEquals('Report not found for the provided API name: Nonexistent_Report', 
                e.getMessage(), 'Should throw correct error message');
        }
        Test.stopTest();
    }
    
    // Mock class for Report selector
    private class MockReportSelector implements ReportSelector.IReportSelector {
        private List<Report> reports;
        
        public MockReportSelector(List<Report> reports) {
            this.reports = reports;
        }
        
        public List<Report> getReportsByDeveloperName(String developerName) {
            List<Report> results = new List<Report>();
            for (Report r : reports) {
                if (r.DeveloperName == developerName) {
                    results.add(r);
                }
            }
            return results;
        }
    }
}