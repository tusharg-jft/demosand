public class FlowNavigationController {
    
    @InvocableMethod(label='Get Object Redirect URL' description='Returns the Object record URL')
    public static List<WorkOrderRedirectResult> getWorkOrderRedirectUrl(List<Id> TripId) {
        List<WorkOrderRedirectResult> results = new List<WorkOrderRedirectResult>();
        
        for (Id TripIds : TripId) {
            WorkOrderRedirectResult result = new WorkOrderRedirectResult();
            try {
                // Construct the URL for the newly created WorkOrder
                result.url = '/' + TripId;
            } catch (Exception e) {
                result.url = 'Error: ' + e.getMessage();
            }
            results.add(result);
        }
        
        return results;
    }

    public class WorkOrderRedirectResult {
        @InvocableVariable
        public String url;
    }
}