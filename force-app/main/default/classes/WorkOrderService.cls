/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 04-24-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class WorkOrderService {
/**
 * Get trades based on user profile
 * @param userId The ID of the current user
 * @param profileName The profile name of the current user
 * @return List of Trade__c records
 */
@AuraEnabled(cacheable=true)
public static List<Trade__c> getTrades(Id userId, String profileName) {
    List<Trade__c> trades = new List<Trade__c>();
    
    // Use existing TradeLookupCntl to get trades
    TradeLookupCntl.TradeLookupRequest request = new TradeLookupCntl.TradeLookupRequest();
    request.userId = userId;
    request.profileName = profileName;
    
    List<TradeLookupCntl.outputVariable> results = TradeLookupCntl.getTrades(new List<TradeLookupCntl.TradeLookupRequest>{request});
    
    if (!results.isEmpty() && results[0].tradeRecords != null) {
        trades = results[0].tradeRecords;
    }
    
    return trades;
}

/**
 * Get classifications based on selected trade
 * @param tradeId The ID of the selected trade
 * @return List of Classification__c records
 */
@AuraEnabled(cacheable=true)
public static List<Classification__c> getClassifications(Id tradeId) {
    return [
        SELECT Id, Name
        FROM Classification__c
        WHERE Trade__c = :tradeId
        ORDER BY Name
    ];
}

/**
 * Get issues based on selected classification
 * @param classificationId The ID of the selected classification
 * @return List of Issue__c records
 */
@AuraEnabled(cacheable=true)
public static List<Issue__c> getIssues(Id classificationId) {
    return [
        SELECT Id, Name
        FROM Issue__c
        WHERE Classification__c = :classificationId
        ORDER BY Name
    ];
}

/**
 * Get priority picklist values from Work_Order__c.Select__c field
 * @return List of priority options with label and value
 */
@AuraEnabled(cacheable=true)
public static List<Map<String, String>> getPriorityOptions() {
    List<Map<String, String>> options = new List<Map<String, String>>();
    
    // Get the picklist values for the Select__c field
    Schema.DescribeFieldResult fieldResult = Work_Order__c.Select__c.getDescribe();
    List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
    
    // Convert to label-value pairs
    for (Schema.PicklistEntry entry : picklistValues) {
        Map<String, String> option = new Map<String, String>();
        option.put('label', entry.getLabel());
        option.put('value', entry.getValue());
        options.add(option);
    }
    
    return options;
}


/**
 * Calculate ETA based on priority
 * @param priorityValue The selected priority value
 * @return Calculated DateTime
 */
@AuraEnabled
public static DateTime calculateETA(String priorityLabel) {
    Datetime now = Datetime.now();
    Datetime updatedDateTime;
    Date today = Date.today();
    Date tomorrow = today.addDays(1); // Get next day's date

    System.debug('priorityLabel====='+ priorityLabel);

    // Logic to add time based on the selected priority label
    if (priorityLabel == 'P2 - Priority 2 hours') {
        updatedDateTime = now.addHours(2);
    } else if (priorityLabel == 'P4 - Priority 4 hours') {
        updatedDateTime = now.addHours(4);
    } else if (priorityLabel == 'P8 - Priority 8 hours') {
        updatedDateTime = now.addHours(8);
    } else if (priorityLabel == 'P24 - Priority 24 hours') {
        updatedDateTime = now.addDays(1);
    } else if (priorityLabel == 'P48 - Priority 48 hours') {
        updatedDateTime = now.addDays(2);
    } else if (priorityLabel == 'NP72 - Non Priority 72 hours') {
        updatedDateTime = now.addDays(3);
    } else if (priorityLabel == 'ND8 - Next Day 8 AM') {
        updatedDateTime = Datetime.newInstance(tomorrow, Time.newInstance(8, 0, 0, 0));
    } else if (priorityLabel == 'ND10 - Next Day 10 AM') {
        updatedDateTime = Datetime.newInstance(tomorrow, Time.newInstance(10, 0, 0, 0));
    } else if (priorityLabel == 'ND2P - Next Day 2 PM') {
        updatedDateTime = Datetime.newInstance(tomorrow, Time.newInstance(14, 0, 0, 0));
    } else if (priorityLabel == 'NPW1 - Non Priority 1 Week') {
        updatedDateTime = now.addDays(7);
    } else if (priorityLabel == 'NPW2 - Non Priority 2 Week') {
        updatedDateTime = now.addDays(14);
    } else if (priorityLabel == 'NPM1 - Non Priority 1 Month') {
        updatedDateTime = now.addMonths(1);
    } else if (priorityLabel == 'NPM2 - Non Priority 2 Month') {
        updatedDateTime = now.addMonths(2);
    } else if (priorityLabel == 'PSM - Priority Service Maintenance 6 Months') {
        updatedDateTime = now.addMonths(6);
    } else {
        updatedDateTime = now; // Default to current datetime if no match
    }
    return updatedDateTime;
}

/**
 * Create a new Work Order record
 * @param workOrderData Map containing the work order field values
 * @return ID of the created Work Order
 */
@AuraEnabled
public static Id createWorkOrder(Map<String, Object> workOrderData) {
    try {
        // Create Work Order record
        Work_Order__c workOrder = new Work_Order__c();

        Id currentUserId = UserInfo.getUserId();

        String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1].Profile.Name;
    
     if (profileName == 'Site Profile') { 
        workOrder.work_Order_Type__c = 'Request';
        workOrder.Request_Status__c = 'Pending Approval';
    } else {
        workOrder.work_Order_Type__c = 'Order';
        workOrder.Request_Status__c = 'Approved';

    }


        
        // Set fields from workOrderData
        if (workOrderData.containsKey('Trade__c')) {
            workOrder.Trade__c = (Id)workOrderData.get('Trade__c');
        }
        
        if (workOrderData.containsKey('Classification__c')) {
            workOrder.Classification__c = (Id)workOrderData.get('Classification__c');
        }
        
        if (workOrderData.containsKey('Issue__c')) {
            workOrder.Issue__c = (Id)workOrderData.get('Issue__c');
        }
        
        if (workOrderData.containsKey('Sites__c')) {
            workOrder.Sites__c = (Id)workOrderData.get('Sites__c');
            
            // Auto-populate Corporate__c and Brand__c based on Sites__c
            Sites__c site = [
                SELECT Corporate__c, Brand__c
                FROM Sites__c
                WHERE Id = :(Id)workOrderData.get('Sites__c')
                LIMIT 1
            ];
        
        }
        
        if (workOrderData.containsKey('Select__c')) {
            workOrder.Select__c = (String)workOrderData.get('Select__c');
        }

        if (workOrderData.containsKey('Original_ETA__c')) {
        String originalEtaString = (String)workOrderData.get('Original_ETA__c');


        // Remove milliseconds and timezone indicator for parsing
        originalEtaString = originalEtaString.replace('Z', '').replace('T', ' ');
        
        // Split into date and time components
        List<String> dateTimeParts = originalEtaString.split(' ');
        List<String> dateParts = dateTimeParts[0].split('-');
        List<String> timeParts = dateTimeParts[1].split(':');
        
        // Handle seconds with potential milliseconds
        List<String> secondsParts = timeParts[2].split('\\.');
        Integer second = Integer.valueOf(secondsParts[0]);
        
        // Parse components to integers
        Integer year = Integer.valueOf(dateParts[0]);
        Integer month = Integer.valueOf(dateParts[1]);
        Integer day = Integer.valueOf(dateParts[2]);
        Integer hour = Integer.valueOf(timeParts[0]);
        Integer minute = Integer.valueOf(timeParts[1]);
        
        // Create GMT datetime (ignore milliseconds as Apex doesn't support them in DateTime)
        DateTime originalEta = DateTime.newInstanceGmt(
            year, month, day, 
            hour, minute, second
        );

        // Save to workOrder
        workOrder.Original_ETA__c = originalEta;
        }
        
        if (workOrderData.containsKey('Request_By_Person__c')) {
            workOrder.Request_By_Person__c = (String)workOrderData.get('Requested_By_Person__c');
        }
        
        if (workOrderData.containsKey('NTE__c')) {
            workOrder.NTE__c = (Decimal)workOrderData.get('NTE__c');
            workOrder.Original_NTE__c = (Decimal)workOrderData.get('NTE__c');
        }
        
        if (workOrderData.containsKey('Description__c')) {
            workOrder.Description__c = (String)workOrderData.get('Description__c');
        }
        
        // Insert the record
        insert workOrder;
        
        // Send notifications
        sendNotifications(workOrder.Id);
        
        return workOrder.Id;
    } catch (Exception e) {
        throw new AuraHandledException('Error creating Work Order: ' + e.getMessage());
    }
}

/**
 * Send notifications to appropriate users
 * @param workOrderId The ID of the created Work Order
 */
private static void sendNotifications(Id workOrderId) {
    Work_Order__c workOrder = [
        SELECT Id, Sites__c
        FROM Work_Order__c
        WHERE Id = :workOrderId
        LIMIT 1
    ];
    
    Sites__c site = [
        SELECT Site_User__c, BrandUser__c, CorpUser__c
        FROM Sites__c
        WHERE Id = :workOrder.Sites__c
        LIMIT 1
    ];
    
    // Get current user's profile
    Id currentUserId = UserInfo.getUserId();
    String profileName = [SELECT Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1].Profile.Name;
    
    Set<String> usersToNotify = new Set<String>();
    
    if (profileName == 'Corporate Profile') {
        // Corporate Profile: Notify Site User and Brand User
        if (site.Site_User__c != null) usersToNotify.add(String.valueOf(site.Site_User__c));
        if (site.BrandUser__c != null) usersToNotify.add(String.valueOf(site.BrandUser__c));
    } else if (profileName == 'Brand Profile') {
        // Brand Profile: Notify Site User and Corporate User
        if (site.Site_User__c != null) usersToNotify.add(String.valueOf(site.Site_User__c));
        if (site.CorpUser__c != null) usersToNotify.add(String.valueOf(site.CorpUser__c));
    } else if (profileName == 'Site Profile') {
        // Site Profile: Notify Site User, Brand User, and Corporate User
        if (site.Site_User__c != null) usersToNotify.add(String.valueOf(site.Site_User__c));
        if (site.BrandUser__c != null) usersToNotify.add(String.valueOf(site.BrandUser__c));
        if (site.CorpUser__c != null) usersToNotify.add(String.valueOf(site.CorpUser__c));
    }
    
    // Send notifications
    if (!usersToNotify.isEmpty()) {
        // Create a custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        
        // Set the notification type
        if (!Test.isRunningTest()) {
            try {
                CustomNotificationType notificationType = [
                    SELECT Id 
                    FROM CustomNotificationType 
                    WHERE DeveloperName = 'Work_Order_Created'
                    LIMIT 1
                ];
                
                notification.setNotificationTypeId(notificationType.Id);
            } catch (Exception e) {
                System.debug('Error getting notification type: ' + e.getMessage());
                return; // Skip notification if type not found
            }
        } else {
            // In test context, we can't query or create CustomNotificationType
            // So we'll just skip this step
            return;
        }
        notification.setTitle('New Work Order Created');
        notification.setBody('A new work order has   been created that requires your attention.');
        notification.setTargetId(workOrderId);
        
        // Send notification to users - use the correct method signature
        try {
            notification.send(usersToNotify);
        } catch (Exception e) {
            System.debug('Error sending notification: ' + e.getMessage());
        }
        
        // Check notification preferences and send emails if enabled
        NotificationCheck.Input input = new NotificationCheck.Input();
        // Convert Set<String> to List<Id>
        List<Id> userIdsList = new List<Id>();
        for (String userIdStr : usersToNotify) {
            userIdsList.add((Id)userIdStr);
        }

        input.userIds = userIdsList;
        input.notificationType = 'Work_Order_Created';
        input.notificationChannel = 'Email';
        
        List<Boolean> emailPreferences = NotificationCheck.checkPreference(new List<NotificationCheck.Input>{input});
        
        if (!emailPreferences.isEmpty() && emailPreferences[0]) {
            // Send email notifications
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(getUserEmails(usersToNotify));
            email.setSubject('New Work Order Created');
            email.setPlainTextBody('A new work order has been created that requires your attention. ' +
                                    'Please log in to review the details.');
            
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        }
    }
}

/**
 * Get email addresses for a list of user IDs
 * @param userIds List of user IDs
 * @return List of email addresses
 */
private static List<String> getUserEmails(Set<String> userIds) {
    List<String> emails = new List<String>();
    
    for (User u : [SELECT Email FROM User WHERE Id IN :userIds AND IsActive = true]) {
        if (u.Email != null) {
            emails.add(u.Email);
        }
    }
    
    return emails;
}
}