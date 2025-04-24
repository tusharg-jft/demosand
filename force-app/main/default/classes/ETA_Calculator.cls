public with sharing class ETA_Calculator {
    @InvocableMethod(label='Calculate ETA' description='Calculates the ETA based on priority and current date/time')
    public static List<DateTime> calculateETA(List<ETARequest> requests) {
        List<DateTime> results = new List<DateTime>();

        for (ETARequest req : requests) {
            DateTime eta = req.currentDateTime;
            String priority = req.priority;

            if (String.isNotBlank(priority) && eta != null) {
                switch on priority {
                    when 'P2 - Priority 2 hours' { eta = eta.addHours(2); }
                    when 'P4 - Priority 4 hours' { eta = eta.addHours(4); }
                    when 'P8 - Priority 8 hours' { eta = eta.addHours(8); }
                    when 'P24 - Priority 24 hours' { eta = eta.addHours(24); }
                    when 'P48 - Priority 48 hours' { eta = eta.addHours(48); }
                    when 'NP72 - Non Priority 72 hours' { eta = eta.addHours(72); }
                    when 'ND8 - Next Day 8 AM' { eta = getNextDayTime(eta, 8); }
                    when 'ND10 - Next Day 10 AM' { eta = getNextDayTime(eta, 10); }
                    when 'ND2P - Next Day 2 PM' { eta = getNextDayTime(eta, 14); }
                    when 'NPW1 - Non Priority 1 Week' { eta = eta.addDays(7); }
                    when 'NPW2 - Non Priority 2 Week' { eta = eta.addDays(14); }
                    when 'NPM1 - Non Priority 1 Month' { eta = eta.addMonths(1); }
                    when 'NPM2 - Non Priority 2 Month' { eta = eta.addMonths(2); }
                    when 'PSM - Priority- Service - Maintenance 6 Months' { eta = eta.addMonths(6); }
                    when 'MWO - Material Work Order' { eta = null; }
                    when else { eta = null; }
                }
            }
            results.add(eta);
        }
        return results;
    }

    private static DateTime getNextDayTime(DateTime dt, Integer hour) {
        Date nextDay = dt.date().addDays(1);
        return DateTime.newInstance(nextDay, Time.newInstance(hour, 0, 0, 0));
    }

    public class ETARequest {
        @InvocableVariable(label='Priority' required=true)
        public String priority;

        @InvocableVariable(label='Current Date/Time' required=true)
        public DateTime currentDateTime;
    }
}