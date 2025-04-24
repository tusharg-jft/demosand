public class VendorTradeRateNotificationHelper {
    public static void sendTradeRateNotifications(Id tradeRateRecordId, Set<Id> corporateUserIds) {
        try {
            // Get the newly created Vendor Trade Rate record
            Vendor_Trade_Rate_Management__c tradeRateRecord = [
                SELECT Id, Name
                FROM Vendor_Trade_Rate_Management__c
                WHERE Id = :tradeRateRecordId
                LIMIT 1
            ];

            if (corporateUserIds.isEmpty()) {
                System.debug('No corporate users found. Skipping notification.');
                return;
            }

            // Get the notification type
            CustomNotificationType notificationType = [
                SELECT Id, DeveloperName 
                FROM CustomNotificationType 
                WHERE DeveloperName = 'TradeRateNotification'
                LIMIT 1
            ];

            // Create and send the notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle(' VTRM REQUESTING APPROVAL');
            notification.setBody('A new vendor trade rate record "' + tradeRateRecord.Name + '" has been created or Updated.');
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(tradeRateRecordId); // ✅ Correct Target ID

            // Convert corporateUserIds to Set<String> for sending
            Set<String> userIdsToNotify = new Set<String>();
            for (Id userId : corporateUserIds) {
                userIdsToNotify.add(String.valueOf(userId));
            }

            notification.send(userIdsToNotify); // ✅ Correct Set<String> format

        } catch (Exception e) {
            System.debug('Error sending trade rate notifications: ' + e.getMessage());
        }
    }
    
    
    
    

    public static void sendTradeRateNotification1(Id tradeRateRecordId, Set<Id> corporateUserIds) {
        try {
            // Step 1: Fetch the Vendor Trade Rate record
            Vendor_Trade_Rate_Management__c tradeRateRecord = [
                SELECT Id, Name
                FROM Vendor_Trade_Rate_Management__c
                WHERE Id = :tradeRateRecordId
                LIMIT 1
            ];

            if (tradeRateRecord == null || corporateUserIds.isEmpty()) {
                System.debug('No valid trade rate record or corporate users found. Skipping notification.');
                return;
            }

            // Step 2: Fetch the Notification Type
            CustomNotificationType notificationType = [
                SELECT Id FROM CustomNotificationType 
                WHERE DeveloperName = '	Decline_Notification'
                LIMIT 1
            ];

            // Step 3: Convert corporateUserIds to Set<String>
            Set<String> userIdsToNotify = new Set<String>();
            for (Id userId : corporateUserIds) {
                userIdsToNotify.add(String.valueOf(userId));
            }

            // Step 4: Send Notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Vendor Trade Rate Declined');
            notification.setBody('Trade Rate "' + tradeRateRecord.Name + '" has been Declined.');
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(tradeRateRecordId);
            notification.send(userIdsToNotify);

            System.debug('Notification sent successfully to corporate users.');
        } catch (Exception e) {
            System.debug('Error sending trade rate notification: ' + e.getMessage());
        }
    }


    
    
    
    
}