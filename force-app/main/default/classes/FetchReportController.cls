public with sharing class FetchReportController {
    
    @AuraEnabled(cacheable=true)
    public static String getReportIdByApiName(String reportApiName) {
        List<Report> reports = ReportSelector.getReportsByDeveloperName(reportApiName);
        if (reports.isEmpty()) {
            throw new AuraHandledException('Report not found for the provided API name: ' + reportApiName);
        }
        return reports[0].Id;
    }
}