public class ReportSelector {
    @TestVisible private static IReportSelector instance = new DefaultReportSelector();
    
    public interface IReportSelector {
        List<Report> getReportsByDeveloperName(String developerName);
    }
    
    private class DefaultReportSelector implements IReportSelector {
        public List<Report> getReportsByDeveloperName(String developerName) {
            return [SELECT Id FROM Report WHERE DeveloperName = :developerName LIMIT 1];
        }
    }
    
    public static List<Report> getReportsByDeveloperName(String developerName) {
        return instance.getReportsByDeveloperName(developerName);
    }
}