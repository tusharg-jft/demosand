public with sharing class WorkRequestService {

    @AuraEnabled
    public static Id createWorkRequest(Map<String, Object> workOrderRequestData) {
        try {
            System.debug('Starting createWorkRequest method.');

            Work_Order_Request__c workRequest = new Work_Order_Request__c();
            List<Id> userIds = new List<Id>();
            Id currentUserId = UserInfo.getUserId();

            System.debug('Current User ID: ' + currentUserId);

            // Fetch current user details
            User currentUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :currentUserId LIMIT 1];
            String profileName = currentUser.Profile.Name;
            String currentUserName = currentUser.Name;

            System.debug('Current User Name: ' + currentUserName);
            System.debug('User Profile Name: ' + profileName);

            workRequest.Status__c = 'In Progress';

            // Set fields from workOrderData
            if (workOrderRequestData.containsKey('Trade__c')) {
                workRequest.Trade__c = (Id)workOrderRequestData.get('Trade__c');
                System.debug('Trade__c: ' + workRequest.Trade__c);
            }

            if (workOrderRequestData.containsKey('Classification__c')) {
                workRequest.Classification__c = (Id)workOrderRequestData.get('Classification__c');
                System.debug('Classification__c: ' + workRequest.Classification__c);
            }

            if (workOrderRequestData.containsKey('Issue__c')) {
                workRequest.Issue__c = (Id)workOrderRequestData.get('Issue__c');
                System.debug('Issue__c: ' + workRequest.Issue__c);
            }

            String siteName = ''; // Initialize to store site name for message
            if (workOrderRequestData.containsKey('Sites__c')) {
                workRequest.Sites__c = (Id)workOrderRequestData.get('Sites__c');

                // Fetch site info to get related users and name
                Sites__c site = [
                    SELECT Name, Corporate__c, Brand__c, BrandUser__c, CorpUser__c
                    FROM Sites__c
                    WHERE Id = :workRequest.Sites__c
                    LIMIT 1
                ];

                siteName = site.Name;

                System.debug('Site Name: ' + siteName);

                // Add users for notification
                if (site.BrandUser__c != null) {
                    userIds.add(site.BrandUser__c);
                    System.debug('Added BrandUser__c: ' + site.BrandUser__c);
                }
                if (site.CorpUser__c != null) {
                    userIds.add(site.CorpUser__c);
                    System.debug('Added CorpUser__c: ' + site.CorpUser__c);
                }
            }

            if (workOrderRequestData.containsKey('Requested_By_Person__c')) {
                workRequest.Request_By_Person__c = (String)workOrderRequestData.get('Requested_By_Person__c');
                System.debug('Requested_By_Person__c: ' + workRequest.Request_By_Person__c);
            }

            if (workOrderRequestData.containsKey('Description__c')) {
                workRequest.Description__c = (String)workOrderRequestData.get('Description__c');
                System.debug('Description__c: ' + workRequest.Description__c);
            }

            // Insert Work Request
            insert workRequest;
            System.debug('Work Order Request inserted with ID: ' + workRequest.Id);

            // Prepare message
            String notificationTitle = 'Work Request Created Successfully';
            String notificationMessage = siteName + ' (Created by ' + currentUserName + ') has created a work request '+ workRequest.Name+' and is asking for approval.';

            // Send notification
            NotificationUtility.sendNotification(
                'Work_Request_Created',
                userIds,
                workRequest.Id,
                notificationTitle,
                notificationMessage
            );

            return workRequest.Id;

        } catch (Exception e) {
            System.debug('Error creating Work Order: ' + e.getMessage());
            throw new AuraHandledException('Error creating Work Order: ' + e.getMessage());
        }
    }
}