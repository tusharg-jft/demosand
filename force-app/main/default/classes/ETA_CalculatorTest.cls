@isTest
private class ETA_CalculatorTest {
    
    @isTest
    static void testHourBasedPriorities() {
        // Setup
        DateTime currentDateTime = DateTime.newInstance(2025, 3, 19, 10, 0, 0);
        
        List<ETA_Calculator.ETARequest> requests = new List<ETA_Calculator.ETARequest>();
        Map<String, Integer> priorityHours = new Map<String, Integer>{
            'P2 - Priority 2 hours' => 2,
            'P4 - Priority 4 hours' => 4,
            'P8 - Priority 8 hours' => 8,
            'P24 - Priority 24 hours' => 24,
            'P48 - Priority 48 hours' => 48,
            'NP72 - Non Priority 72 hours' => 72
        };
        
        for(String priority : priorityHours.keySet()) {
            ETA_Calculator.ETARequest req = new ETA_Calculator.ETARequest();
            req.priority = priority;
            req.currentDateTime = currentDateTime;
            requests.add(req);
        }
        
        // Act
        Test.startTest();
        List<DateTime> results = ETA_Calculator.calculateETA(requests);
        Test.stopTest();
        
        // Assert
        for(Integer i = 0; i < results.size(); i++) {
            String priority = requests[i].priority;
            Integer expectedHours = priorityHours.get(priority);
            DateTime expectedDateTime = currentDateTime.addHours(expectedHours);
            System.assertEquals(expectedDateTime, results[i], 
                'ETA for ' + priority + ' should be ' + expectedHours + ' hours from current time');
        }
    }
    
    @isTest
    static void testNextDayPriorities() {
        // Setup
        DateTime currentDateTime = DateTime.newInstance(2025, 3, 19, 15, 0, 0); // 3 PM
        Date nextDay = currentDateTime.date().addDays(1);
        
        List<ETA_Calculator.ETARequest> requests = new List<ETA_Calculator.ETARequest>();
        Map<String, Integer> priorityHours = new Map<String, Integer>{
            'ND8 - Next Day 8 AM' => 8,
            'ND10 - Next Day 10 AM' => 10,
            'ND2P - Next Day 2 PM' => 14
        };
        
        for(String priority : priorityHours.keySet()) {
            ETA_Calculator.ETARequest req = new ETA_Calculator.ETARequest();
            req.priority = priority;
            req.currentDateTime = currentDateTime;
            requests.add(req);
        }
        
        // Act
        Test.startTest();
        List<DateTime> results = ETA_Calculator.calculateETA(requests);
        Test.stopTest();
        
        // Assert
        for(Integer i = 0; i < results.size(); i++) {
            String priority = requests[i].priority;
            Integer expectedHour = priorityHours.get(priority);
            DateTime expectedDateTime = DateTime.newInstance(nextDay, Time.newInstance(expectedHour, 0, 0, 0));
            System.assertEquals(expectedDateTime, results[i], 
                'ETA for ' + priority + ' should be next day at ' + expectedHour + ':00');
        }
    }
    
    @isTest
    static void testExtendedPeriodPriorities() {
        // Setup
        DateTime currentDateTime = DateTime.newInstance(2025, 3, 19, 10, 0, 0);
        
        List<ETA_Calculator.ETARequest> requests = new List<ETA_Calculator.ETARequest>();
        
        // Test 1 week priority
        ETA_Calculator.ETARequest weekReq = new ETA_Calculator.ETARequest();
        weekReq.priority = 'NPW1 - Non Priority 1 Week';
        weekReq.currentDateTime = currentDateTime;
        requests.add(weekReq);
        
        // Test 2 weeks priority
        ETA_Calculator.ETARequest twoWeekReq = new ETA_Calculator.ETARequest();
        twoWeekReq.priority = 'NPW2 - Non Priority 2 Week';
        twoWeekReq.currentDateTime = currentDateTime;
        requests.add(twoWeekReq);
        
        // Test 1 month priority
        ETA_Calculator.ETARequest monthReq = new ETA_Calculator.ETARequest();
        monthReq.priority = 'NPM1 - Non Priority 1 Month';
        monthReq.currentDateTime = currentDateTime;
        requests.add(monthReq);
        
        // Test 2 months priority
        ETA_Calculator.ETARequest twoMonthReq = new ETA_Calculator.ETARequest();
        twoMonthReq.priority = 'NPM2 - Non Priority 2 Month';
        twoMonthReq.currentDateTime = currentDateTime;
        requests.add(twoMonthReq);
        
        // Test 6 months priority
        ETA_Calculator.ETARequest sixMonthReq = new ETA_Calculator.ETARequest();
        sixMonthReq.priority = 'PSM - Priority- Service - Maintenance 6 Months';
        sixMonthReq.currentDateTime = currentDateTime;
        requests.add(sixMonthReq);
        
        // Act
        Test.startTest();
        List<DateTime> results = ETA_Calculator.calculateETA(requests);
        Test.stopTest();
        
        // Assert
        System.assertEquals(currentDateTime.addDays(7), results[0], 'ETA should be 1 week from current time');
        System.assertEquals(currentDateTime.addDays(14), results[1], 'ETA should be 2 weeks from current time');
        System.assertEquals(currentDateTime.addMonths(1), results[2], 'ETA should be 1 month from current time');
        System.assertEquals(currentDateTime.addMonths(2), results[3], 'ETA should be 2 months from current time');
        System.assertEquals(currentDateTime.addMonths(6), results[4], 'ETA should be 6 months from current time');
    }
    
    @isTest
    static void testMaterialWorkOrder() {
        // Setup
        DateTime currentDateTime = DateTime.newInstance(2025, 3, 19, 10, 0, 0);
        
        ETA_Calculator.ETARequest req = new ETA_Calculator.ETARequest();
        req.priority = 'MWO - Material Work Order';
        req.currentDateTime = currentDateTime;
        
        // Act
        Test.startTest();
        List<DateTime> results = ETA_Calculator.calculateETA(new List<ETA_Calculator.ETARequest>{req});
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, results[0], 'ETA should be null for Material Work Order');
    }
    
    @isTest
    static void testInvalidPriority() {
        // Setup
        DateTime currentDateTime = DateTime.newInstance(2025, 3, 19, 10, 0, 0);
        
        ETA_Calculator.ETARequest req = new ETA_Calculator.ETARequest();
        req.priority = 'Invalid Priority';
        req.currentDateTime = currentDateTime;
        
        // Act
        Test.startTest();
        List<DateTime> results = ETA_Calculator.calculateETA(new List<ETA_Calculator.ETARequest>{req});
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, results[0], 'ETA should be null for invalid priority');
    }
    
    @isTest
    static void testNullValues() {
        // Setup
        ETA_Calculator.ETARequest req = new ETA_Calculator.ETARequest();
        req.priority = null;
        req.currentDateTime = null;
        
        // Act
        Test.startTest();
        List<DateTime> results = ETA_Calculator.calculateETA(new List<ETA_Calculator.ETARequest>{req});
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, results[0], 'ETA should be null for null inputs');
    }
    
    @isTest
    static void testBlankPriority() {
        // Setup
        DateTime currentDateTime = DateTime.newInstance(2025, 3, 19, 10, 0, 0);
        
        ETA_Calculator.ETARequest req = new ETA_Calculator.ETARequest();
        req.priority = '';
        req.currentDateTime = currentDateTime;
        
        // Act
        Test.startTest();
        List<DateTime> results = ETA_Calculator.calculateETA(new List<ETA_Calculator.ETARequest>{req});
        Test.stopTest();
        
        // Assert
        System.assertEquals(null, results[0], 'ETA should be null for blank priority');
    }
}