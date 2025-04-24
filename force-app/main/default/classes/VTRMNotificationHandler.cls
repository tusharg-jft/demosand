public with sharing class VTRMNotificationHandler {
    @AuraEnabled
    public static void sendStatusUpdateNotification(String vtrmIdString) {
        if (String.isEmpty(vtrmIdString)) {
            System.debug('No VTRM record ID received.');
            return;
        }

        // Convert single ID to List<Id>
        Id vtrmId;
        try {
            vtrmId = Id.valueOf(vtrmIdString);
        } catch (Exception e) {
            System.debug('Invalid VTRM ID format: ' + vtrmIdString);
            return;
        }

        // Fetch VTRM record along with Vendor & User lookup
        Vendor_Trade_Rate_Management__c vtrm = [
            SELECT Id, Name, Status__c, Vendor__r.User__c 
            FROM Vendor_Trade_Rate_Management__c 
            WHERE Id = :vtrmId 
            LIMIT 1
        ];

        if (vtrm.Vendor__r == null || vtrm.Vendor__r.User__c == null) {
            System.debug('No vendor user found for VTRM ID: ' + vtrm.Id);
            return;
        }

        Id recipientUserId = vtrm.Vendor__r.User__c; // Vendor's associated user
        Set<String> recipientUserIds = new Set<String>{recipientUserId}; // Convert to Set<String>

        // Get Custom Notification Type ID
        Id notificationTypeId;
        try {
            notificationTypeId = [
                SELECT Id FROM CustomNotificationType 
                WHERE DeveloperName = 'VTRMStatusUpdate' 
                LIMIT 1
            ].Id;
        } catch (Exception e) {
            System.debug('Error fetching notification type: ' + e.getMessage());
            return;
        }

        // Send Notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
        notification.setTitle('VTRM Status Update');
        notification.setBody('VTRM "' + vtrm.Name + '" has been ' + vtrm.Status__c + '.');
        notification.setNotificationTypeId(notificationTypeId);
        notification.setTargetId(vtrm.Id); // Clicking opens the VTRM record
        notification.send(recipientUserIds); // ✅ CORRECTED - Uses Set<String>

        System.debug('Notification sent to Vendor User: ' + recipientUserId);
    }
}