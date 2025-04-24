/**
* @description Service class to handle business logic related to Service Channel integration.
* Orchestrates interactions between Salesforce and the Service Channel API.
*/
public without sharing class ServiceChannelService {
    
    private static final String EVENT_WO_CREATED = 'WorkOrderCreated';
    private static final String SERVICE_CHANNEL_BASE_URL = 'https://sb2api.servicechannel.com/v3';
    
    private static final String EVENT_WO_STATUS_CHANGED = 'WorkOrderStatusChanged';
    private static final String EVENT_WO_NOTE_ADDED = 'WorkOrderNoteAdded';
    // Add other event types as needed
    
    /**
* @description Processes an incoming webhook payload from Service Channel.
* Delegates to specific handler methods based on EventType.
* @param payloadJson The deserialized webhook payload as JSON string.
* @return void (due to @future).
*/
    @future(callout=true)
    public static void processWebhook(String payloadJson) {
        Map<String, Object> payload;
        try {
            payload = (Map<String, Object>) JSON.deserializeUntyped(payloadJson);
            System.debug('Deserialized Payload: ' + JSON.serializePretty(payload));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Invalid JSON format: ' + e.getMessage() + '. Payload: ' + payloadJson);
            return;
        }
        
        if (!payload.containsKey('EventType')) {
            System.debug(LoggingLevel.ERROR, 'Missing EventType key. Payload: ' + payloadJson);
            return;
        }
        
        String eventType = (String) payload.get('EventType');
        if (String.isBlank(eventType)) {
            System.debug(LoggingLevel.ERROR, 'EventType is empty. Payload: ' + payloadJson);
            return;
        }
        
        try {
            if (eventType == EVENT_WO_CREATED) {
                Map<String, Object> eventObject = (Map<String, Object>) payload.get('Object');
                if (eventObject == null) {
                    System.debug(LoggingLevel.ERROR, 'Missing Object key for WorkOrderCreated event. Payload: ' + payloadJson);
                    return;
                }
                handleWorkOrderCreated(eventObject);
            } else {
                System.debug(LoggingLevel.WARN, 'Unhandled EventType received: ' + eventType);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error processing webhook event ' + eventType + '. Error: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
        }
    }
    /**
* @description Handles the 'WorkOrderCreated' event. Creates Corporate__c, Sites__c, and Work_Order__c records if they don't exist.
* @param woData The 'Object' part of the webhook payload.
*/
    /**
* @description Handles the 'WorkOrderCreated' event. Creates Corporate__c, Brand__c, Sites__c, and Work_Order__c records if they don't exist.
* @param woData The 'Object' part of the webhook payload.
*/
    /**
* @description Handles the 'WorkOrderCreated' event. Creates Corporate__c and Brand__c synchronously,
* then delegates Site__c and Work_Order__c creation to a Future Method.
* @param woData The 'Object' part of the webhook payload.
*/
    /**
* @description Handles the 'WorkOrderCreated' event. Creates Corporate__c, Brand__c, Sites__c, and Work_Order__c records.
* Runs within the Future context of processWebhook, allowing callouts after initial DML.
* @param woData The 'Object' part of the webhook payload.
*/
    public static void handleWorkOrderCreated(Map<String, Object> woData) {
        String scWorkOrderId = String.valueOf(woData.get('Id'));
        System.debug('Handling WorkOrderCreated for SC WO ID: ' + scWorkOrderId);
        
        // Check for existing Work Order
        List<Work_Order__c> existingWOs = [SELECT Id FROM Work_Order__c WHERE External_WO_ID__c = :scWorkOrderId LIMIT 1];
        if (!existingWOs.isEmpty()) {
            System.debug('Work Order already exists for SC WO ID: ' + scWorkOrderId + '. SF ID: ' + existingWOs[0].Id);
            return;
        }
        
        // Extract Subscriber, Location, and Provider info from payload
        Map<String, Object> subscriberInfo = (Map<String, Object>) woData.get('Subscriber');
        Map<String, Object> locationInfo = (Map<String, Object>) woData.get('Location');
        Map<String, Object> providerInfo = (Map<String, Object>) woData.get('Provider');
        
        if (subscriberInfo == null || locationInfo == null || providerInfo == null) {
            System.debug(LoggingLevel.ERROR, 'Missing Subscriber, Location, or Provider info for SC WO ID: ' + scWorkOrderId);
            return;
        }
        
        String scSubscriberId = String.valueOf(subscriberInfo.get('Id')); // e.g., "2014917243"
        String scLocationId = String.valueOf(locationInfo.get('Id'));     // e.g., "2006085096"
        String scStoreId = String.valueOf(locationInfo.get('StoreId'));   // e.g., "102"
        String scProviderId = String.valueOf(providerInfo.get('Id'));     // e.g., "2000090505"
        
         // Since we're in a Future context, we can perform the callout here after initial DML
        Map<String, Object> detailedLocationInfo = fetchLocationDetails(scLocationId);
        if (detailedLocationInfo == null) {
            System.debug(LoggingLevel.ERROR, 'Failed to fetch detailed location info for SC Location ID: ' + scLocationId);
            return;
        }
        System.debug('Fetched location details: ' + JSON.serialize(detailedLocationInfo));       
        
        // Create/Get Corporate__c using payload data
        Corporate__c corporate = getOrCreateCorporate(scSubscriberId, subscriberInfo);
        if (corporate == null) {
            System.debug(LoggingLevel.ERROR, 'Failed to get or create Corporate__c for SC WO ID: ' + scWorkOrderId);
            return;
        }
        System.debug('Corporate__c processed. ID: ' + corporate.Id);
        
        // Create/Get Brand__c using payload data with Corporate__c reference
        Brand__c brand = getOrCreateBrand(scSubscriberId, subscriberInfo, corporate.Id);
        if (brand == null) {
            System.debug(LoggingLevel.ERROR, 'Failed to get or create Brand__c for SC WO ID: ' + scWorkOrderId);
            return;
        }
        System.debug('Brand__c processed. ID: ' + brand.Id);
        
        // Create/Get Sites__c using API response
        Sites__c site = getOrCreateSite(scStoreId, scLocationId, detailedLocationInfo, corporate.Id, brand.Id);
        if (site == null) {
            System.debug(LoggingLevel.ERROR, 'Failed to get or create Sites__c for SC WO ID: ' + scWorkOrderId);
            return;
        }
        System.debug('Sites__c processed. ID: ' + site.Id);
        
        // Create Work_Order__c using original payload
        Work_Order__c newWorkOrder = ServiceChannelMapper.mapWorkOrderToSF(woData, null, corporate.Id, site.Id);
        Database.SaveResult sr = Database.insert(newWorkOrder, false);
        if (sr.isSuccess()) {
            System.debug('Successfully created Work_Order__c ID: ' + sr.getId() + ' for SC WO ID: ' + scWorkOrderId);
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Work_Order__c for SC WO ID: ' + scWorkOrderId + '. Errors: ' + sr.getErrors());
        }
    }
    /**
* @description Future Method to fetch location details and create Sites__c (from API response) and Work_Order__c (from payload).
* @param scLocationId The Service Channel Location ID.
* @param scStoreId The Service Channel Store ID.
* @param corporateId The Salesforce ID of the Corporate__c record.
* @param brandId The Salesforce ID of the Brand__c record.
* @param woDataJson The serialized webhook payload data.
*/
    @future(callout=true)
    public static void createSiteAndWorkOrderFuture(String scLocationId, String scStoreId, Id corporateId, Id brandId, String woDataJson) {
        // Deserialize woData for Work Order creation
        Map<String, Object> woData = (Map<String, Object>) JSON.deserializeUntyped(woDataJson);
        String scWorkOrderId = String.valueOf(woData.get('Id'));
        System.debug('Future Method started for SC WO ID: ' + scWorkOrderId);
        
        // Fetch detailed location info from API for Site creation
        Map<String, Object> detailedLocationInfo = fetchLocationDetails(scLocationId);
        if (detailedLocationInfo == null) {
            System.debug(LoggingLevel.ERROR, 'Failed to fetch detailed location info for SC Location ID: ' + scLocationId);
            return;
        }
        System.debug('Fetched location details: ' + JSON.serialize(detailedLocationInfo));
        
        // Create/Get Sites__c using API response (detailedLocationInfo)
        Sites__c site = getOrCreateSite(scStoreId, scLocationId, detailedLocationInfo, corporateId, brandId);
        if (site == null) {
            System.debug(LoggingLevel.ERROR, 'Failed to get or create Sites__c for SC WO ID: ' + scWorkOrderId);
            return;
        }
        System.debug('Sites__c processed in Future Method. ID: ' + site.Id);
        
        // Create Work_Order__c using original payload (woData)
        Work_Order__c newWorkOrder = ServiceChannelMapper.mapWorkOrderToSF(woData, null, corporateId, site.Id);
        Database.SaveResult sr = Database.insert(newWorkOrder, false);
        if (sr.isSuccess()) {
            System.debug('Successfully created Work_Order__c ID: ' + sr.getId() + ' for SC WO ID: ' + scWorkOrderId);
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Work_Order__c for SC WO ID: ' + scWorkOrderId + '. Errors: ' + sr.getErrors());
        }
    }
    /**
* @description Handles the 'WorkOrderNoteAdded' event. Creates a CaseComment related to the Work_Order__c.
* @param noteData The 'Object' part of the webhook payload containing note details.
* @param scWorkOrderId The Service Channel Work Order ID associated with the note.
* @note Assumes CaseComment is the correct object to store notes against Work_Order__c.
* @note Assumes CaseComment has a custom field ServiceChannel_Note_ID__c (External ID).
*/
    private static void handleWorkOrderNoteAdded(Map<String, Object> noteData, String scWorkOrderId) {
        String scNoteId = String.valueOf(noteData.get('Id')); // SC Note ID
        System.debug('Handling WorkOrderNoteAdded for SC WO ID: ' + scWorkOrderId + ', SC Note ID: ' + scNoteId);
        
        // 1. Find existing Work Order
        List<Work_Order__c> existingWOs = [SELECT Id FROM Work_Order__c WHERE External_WO_ID__c = :scWorkOrderId LIMIT 1];
        if (existingWOs.isEmpty()) {
            System.debug(LoggingLevel.ERROR, 'Work Order not found for SC WO ID: ' + scWorkOrderId + ' while trying to add note ID: ' + scNoteId);
            return;
        }
        Id workOrderId = existingWOs[0].Id;
        
        // 2. Check if comment already exists using SC Note ID
        // TODO: Verify if ServiceChannel_Note_ID__c field exists and is External ID on CaseComment. Commenting out check for now.
        /*
List<CaseComment> existingComments = [SELECT Id FROM CaseComment WHERE ServiceChannel_Note_ID__c = :scNoteId LIMIT 1];
if (!existingComments.isEmpty()) {
System.debug('CaseComment already exists for SC Note ID: ' + scNoteId + '. SF ID: ' + existingComments[0].Id);
*/
        Boolean commentExists = false; // Assume comment doesn't exist if check is commented out
        if (commentExists) {
            return;
        }
        
        // 3. Map and Create CaseComment
        CaseComment newComment = ServiceChannelMapper.mapNoteToCaseComment(noteData, workOrderId);
        
        // 4. Insert CaseComment
        Database.SaveResult sr = Database.insert(newComment, false);
        if (sr.isSuccess()) {
            System.debug('Successfully created CaseComment ID: ' + sr.getId() + ' for SC Note ID: ' + scNoteId);
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to insert CaseComment for SC Note ID: ' + scNoteId + '. Errors: ' + sr.getErrors());
            // Log errors more formally
        }
    }
    
    // --- Placeholder methods for outbound actions (called from Triggers/Flows/etc.) ---
    
    /**
* @description Sends a CaseComment to Service Channel as a Note. Typically called from a trigger/flow.
* @param commentId The ID of the CaseComment record to send.
* @note Assumes CaseComment.ParentId points to a Work_Order__c record.
* @note Assumes CaseComment has ServiceChannel_Note_ID__c field to store the returned ID.
*/
    @future(callout=true)
    public static void sendCommentToSC(Id commentId) {
        System.debug('Attempting to send CaseComment ID: ' + commentId + ' to Service Channel.');
        // TODO: Verify ServiceChannel_Note_ID__c field exists on CaseComment. Removed from query.
        // TODO: Verify Parent relationship field name if Parent.External_WO_ID__c causes issues.
        CaseComment comment = [SELECT Id, CommentBody, ParentId, Parent.Id, Parent.Type FROM CaseComment WHERE Id = :commentId LIMIT 1];
        
        if (comment == null) {
            System.debug(LoggingLevel.ERROR, 'sendCommentToSC: CaseComment not found for ID: ' + commentId);
            return;
        }
        
        // TODO: Uncomment this check if ServiceChannel_Note_ID__c field exists
        /*
if (String.isNotBlank(comment.ServiceChannel_Note_ID__c)) {
System.debug(LoggingLevel.INFO, 'sendCommentToSC: CaseComment ID: ' + commentId + ' already has SC Note ID: ' + comment.ServiceChannel_Note_ID__c + '. Skipping send.');
return; // Avoid sending duplicates
}
*/
        
        // Get External_WO_ID__c safely from the Parent Work_Order__c
        String scWorkOrderId = null;
        if (comment.ParentId != null && comment.Parent.Type == 'Work_Order__c') {
            // Query the parent Work_Order__c separately to get the External_WO_ID__c
            List<Work_Order__c> parentWOs = [SELECT External_WO_ID__c FROM Work_Order__c WHERE Id = :comment.ParentId LIMIT 1];
            if (!parentWOs.isEmpty()) {
                scWorkOrderId = parentWOs[0].External_WO_ID__c;
            }
        }
        
        if (String.isBlank(scWorkOrderId)) {
            System.debug(LoggingLevel.ERROR, 'sendCommentToSC: Could not find External_WO_ID__c on parent Work_Order__c (' + comment.ParentId + ') for CaseComment ID: ' + commentId);
            return;
        }
        
        // 2. Map CaseComment to SC Note format
        // Determine 'mailsTo' if needed - might require querying related users/contacts
        String mailsTo = null; // Placeholder - add logic to determine recipient if required by SC API
        Map<String, Object> notePayload = ServiceChannelMapper.mapCommentToSCNote(comment, mailsTo);
        
        // 3. Call ServiceChannelHelper to add the note
        Map<String, Object> response = ServiceChannelHelper.addNote(scWorkOrderId, notePayload);
        
        // 4. Update CaseComment with SC Note ID if successful
        if (response != null && response.containsKey('id')) { // Check the actual key for the note ID in the SC response
            String scNoteId = String.valueOf(response.get('id'));
            // TODO: Uncomment if ServiceChannel_Note_ID__c field exists on CaseComment
            // comment.ServiceChannel_Note_ID__c = scNoteId;
            // Database.SaveResult sr = Database.update(comment, false);
            // if (sr.isSuccess()) {
            System.debug('Successfully received SC Note ID: ' + scNoteId + ' for CaseComment ID: ' + commentId + '. Update skipped as field is missing/commented.');
            // } else {
            //     System.debug(LoggingLevel.ERROR, 'Failed to update CaseComment ID: ' + commentId + ' with SC Note ID: ' + scNoteId + '. Errors: ' + sr.getErrors());
            // }
            // Removed erroneous else block from commented code
        } else { // <<< This 'else' corresponds to the outer 'if (response != null ...)'
            System.debug(LoggingLevel.ERROR, 'Failed to send CaseComment ID: ' + commentId + ' to Service Channel or response did not contain ID. Response: ' + JSON.serialize(response));
        }
    }
    
    /**
* @description Sends an Invoice__c record to Service Channel.
* @param invoiceId The ID of the Invoice__c record.
* @note Assumes Invoice__c has a lookup to Work_Order__c (e.g., Work_Order__c field).
* @note Assumes Invoice__c has a field ServiceChannel_Invoice_ID__c to store the returned ID.
*/
    @future(callout=true)
    public static void sendInvoiceToSC(Id invoiceId) {
        System.debug('Attempting to send Invoice ID: ' + invoiceId + ' to Service Channel.');
        // 1. Query Invoice__c, related Work_Order__c (for SC WO ID), and line items
        // TODO: Verify Work_Order__c lookup field name/existence on Invoice__c. Removed from query.
        // TODO: Verify ServiceChannel_Invoice_ID__c field existence on Invoice__c. Removed from query.
        // TODO: Verify Invoice_Line_Items__r relationship name and fields.
        Invoice__c invoice = [SELECT Id, Name, Tax_Amount__c, Total_Amount__c, Description__c FROM Invoice__c WHERE Id = :invoiceId LIMIT 1];
        
        if (invoice == null) {
            System.debug(LoggingLevel.ERROR, 'sendInvoiceToSC: Invoice not found for ID: ' + invoiceId);
            return;
        }
        
        // TODO: Uncomment if ServiceChannel_Invoice_ID__c field exists
        /*
if (String.isNotBlank(invoice.ServiceChannel_Invoice_ID__c)) {
System.debug(LoggingLevel.INFO, 'sendInvoiceToSC: Invoice ID: ' + invoiceId + ' already has SC Invoice ID: ' + invoice.ServiceChannel_Invoice_ID__c + '. Skipping send.');
return; // Avoid sending duplicates
}
*/
        
        // TODO: Need to query Work_Order__c separately if the lookup field is confirmed
        String scWorkOrderId = null; // Placeholder - Requires querying the related Work Order
        // Example:
        // List<Work_Order__c> parentWOs = [SELECT External_WO_ID__c FROM Work_Order__c WHERE Id = :invoice.Work_Order__c LIMIT 1];
        // if (!parentWOs.isEmpty()) scWorkOrderId = parentWOs[0].External_WO_ID__c;
        
        if (String.isBlank(scWorkOrderId)) {
            System.debug(LoggingLevel.ERROR, 'sendInvoiceToSC: Could not determine External_WO_ID__c for Invoice ID: ' + invoiceId + '. Ensure Work_Order__c lookup exists and is populated.');
            return;
        }
        
        // 2. Map Invoice__c and lines to SC Invoice format
        // TODO: Ensure Invoice_Line_Items__r are queried if needed by mapInvoiceToSC
        Map<String, Object> invoicePayload = ServiceChannelMapper.mapInvoiceToSC(invoice, scWorkOrderId);
        
        // 3. Call ServiceChannelHelper to add the invoice
        Map<String, Object> response = ServiceChannelHelper.addInvoice(invoicePayload);
        
        // 4. Update Invoice__c with SC Invoice ID if successful
        if (response != null && response.containsKey('Id')) { // Check the actual key for the invoice ID in the SC response
            String scInvoiceId = String.valueOf(response.get('Id'));
            // TODO: Uncomment if ServiceChannel_Invoice_ID__c field exists
            // invoice.ServiceChannel_Invoice_ID__c = scInvoiceId; // Assumed field
            // Database.SaveResult sr = Database.update(invoice, false);
            // if (sr.isSuccess()) {
            System.debug('Successfully received SC Invoice ID: ' + scInvoiceId + ' for Invoice ID: ' + invoiceId + '. Update skipped as field is missing/commented.');
            // } else {
            //     System.debug(LoggingLevel.ERROR, 'Failed to update Invoice ID: ' + invoiceId + ' with SC Invoice ID: ' + scInvoiceId + '. Errors: ' + sr.getErrors());
            // }
            // Removed erroneous else block from commented code
        } else { // <<< This 'else' corresponds to the outer 'if (response != null ...)'
            System.debug(LoggingLevel.ERROR, 'Failed to send Invoice ID: ' + invoiceId + ' to Service Channel or response did not contain ID. Response: ' + JSON.serialize(response));
        }
    }
    
    /**
* @description Sends an Estimate__c PDF as an attachment to Service Channel.
* @param estimateId The ID of the Estimate__c record.
* @note Assumes Estimate__c has a lookup to Work_Order__c (e.g., Work_Order__c field).
* @note Assumes the PDF is stored as a ContentVersion linked via FirstPublishLocationId.
*/
    @future(callout=true)
    public static void sendEstimateToSC(Id estimateId) {
        System.debug('Attempting to send Estimate PDF for ID: ' + estimateId + ' to Service Channel.');
        // 1. Query Estimate__c and related Work_Order__c (for SC WO ID)
        // TODO: Verify Work_Order__c lookup field name/existence on Estimate__c. Removed from query.
        Estimate__c estimate = [SELECT Id, Name FROM Estimate__c WHERE Id = :estimateId LIMIT 1];
        
        if (estimate == null) {
            System.debug(LoggingLevel.ERROR, 'sendEstimateToSC: Estimate not found for ID: ' + estimateId);
            return;
        }
        
        // TODO: Need to query Work_Order__c separately if the lookup field is confirmed
        String scWorkOrderId = null; // Placeholder - Requires querying the related Work Order
        // Example:
        // List<Work_Order__c> parentWOs = [SELECT External_WO_ID__c FROM Work_Order__c WHERE Id = :estimate.Work_Order__c LIMIT 1];
        // if (!parentWOs.isEmpty()) scWorkOrderId = parentWOs[0].External_WO_ID__c;
        
        if (String.isBlank(scWorkOrderId)) {
            System.debug(LoggingLevel.ERROR, 'sendEstimateToSC: Could not determine External_WO_ID__c for Estimate ID: ' + estimateId + '. Ensure Work_Order__c lookup exists and is populated.');
            return;
        }
        
        // 2. Get the Estimate PDF ContentVersion
        ContentVersion pdfVersion = [SELECT Id, Title, VersionData FROM ContentVersion WHERE FirstPublishLocationId = :estimateId AND FileExtension IN ('pdf', 'PDF') ORDER BY CreatedDate DESC LIMIT 1];
        
        if (pdfVersion == null || pdfVersion.VersionData == null) {
            System.debug(LoggingLevel.ERROR, 'sendEstimateToSC: PDF ContentVersion not found or empty for Estimate ID: ' + estimateId);
            return;
        }
        
        Blob pdfBlob = pdfVersion.VersionData;
        String pdfFileName = String.isNotBlank(pdfVersion.Title) ? pdfVersion.Title : estimate.Name;
        if (!pdfFileName.toLowerCase().endsWith('.pdf')) {
            pdfFileName += '.pdf';
        }
        
        // 3. Get current user info for the attachment upload
        User currentUser = [SELECT Id, FirstName, LastName FROM User WHERE Id = :UserInfo.getUserId()];
        String userName = currentUser.FirstName + ' ' + currentUser.LastName;
        
        // 4. Call ServiceChannelHelper to add the attachment
        Map<String, Object> response = ServiceChannelHelper.addAttachment(scWorkOrderId, pdfFileName, pdfBlob, userName);
        
        // 5. Log success/failure
        if (response != null) { // Assuming a non-null response indicates success for attachments
            System.debug('Successfully sent Estimate PDF attachment for Estimate ID: ' + estimateId + ' to SC WO ID: ' + scWorkOrderId + '. Response: ' + JSON.serialize(response));
            // Optionally update Estimate__c status (e.g., Sent_To_ServiceChannel__c = true)
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to send Estimate PDF attachment for Estimate ID: ' + estimateId + ' to SC WO ID: ' + scWorkOrderId);
        }
    }
    
    // --- Helper Methods for Get/Create ---
    
    /**
* @description Gets or creates a Corporate__c record based on SC Subscriber ID.
* @param scSubscriberId The Service Channel Subscriber ID.
* @param subscriberInfo Map containing subscriber details from SC payload (Name, ShortName).
* @return Corporate__c The found or newly created Corporate__c record, or null on failure.
*/
    public static Corporate__c getOrCreateCorporate(String scSubscriberId, Map<String, Object> subscriberInfo) {
        if (String.isBlank(scSubscriberId) || subscriberInfo == null) {
            System.debug(LoggingLevel.ERROR, 'Invalid parameters for getOrCreateCorporate. scSubscriberId: ' + scSubscriberId);
            return null;
        }
        
        // Check for existing Corporate__c
        List<Corporate__c> existingCorporates = [SELECT Id, Name FROM Corporate__c WHERE External_Corporate_ID__c = :scSubscriberId LIMIT 1];
        if (!existingCorporates.isEmpty()) {
            System.debug('Found existing Corporate__c ID: ' + existingCorporates[0].Id + ' for SC Subscriber ID: ' + scSubscriberId);
            return existingCorporates[0];
        }
        
        // Create new Corporate__c
        Corporate__c newCorporate = new Corporate__c(
            Name = (String) subscriberInfo.get('Name'), // "API SANDBOX"
            External_Corporate_ID__c = scSubscriberId, // "2014917243"
            External_Name__c = (String) subscriberInfo.get('Name'),
            Short_Code__c = (String) subscriberInfo.get('ShortName'),
            External_Corporate_Source__c = 'Service Channel'// "API SANDBOX"
        );
        
        Database.SaveResult sr = Database.insert(newCorporate, false);
        if (sr.isSuccess()) {
            System.debug('Created Corporate__c ID: ' + sr.getId() + ' for SC Subscriber ID: ' + scSubscriberId);
            newCorporate.Id = sr.getId(); // Set the Id on the object we just inserted
            return newCorporate; // Return the inserted object directly instead of re-querying
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Corporate__c for SC Subscriber ID: ' + scSubscriberId + '. Errors: ' + sr.getErrors());
            return null;
        }
    }
    // Fetch subscriber details from ServiceChannel API
    //private static final String SERVICE_CHANNEL_BASE_URL = 'https://sb2api.servicechannel.com/v3';
    private static String tokenCache;
    private static DateTime tokenExpiry;
    
    /**
* @description Fetches detailed location information from Service Channel API using the location ID.
* @param scLocationId The Service Channel Location ID (e.g., "2006085096").
* @return Map<String, Object> The location details from the API response, or null if the call fails.
*/
    public static Map<String, Object> fetchLocationDetails(String scLocationId) {
        System.debug('Entering fetchLocationDetails method with SC Location ID: ' + scLocationId);
        
        String authToken = getServiceChannelAuthToken();
        system.debug('bypassed the auth token');
        if (authToken == null) {
            System.debug(LoggingLevel.ERROR, 'Failed to retrieve authentication token');
            return null;
        }
        
        String url = SERVICE_CHANNEL_BASE_URL + '/locations?id=' + scLocationId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + authToken);
        req.setHeader('Content-Type', 'application/json');
        
        Http http = new Http();
        HttpResponse res;
        
        try {
            res = http.send(req);
            System.debug('Request sent for location details. Response: ' + res.getBody());
            
            if (res.getStatusCode() == 200) {
                Object responseObj = JSON.deserializeUntyped(res.getBody());
                
                if (responseObj instanceof List<Object>) {
                    List<Object> responseList = (List<Object>) responseObj;
                    if (!responseList.isEmpty() && responseList[0] instanceof Map<String, Object>) {
                        return (Map<String, Object>) responseList[0]; // Return the first location
                    }
                } else if (responseObj instanceof Map<String, Object>) {
                    return (Map<String, Object>) responseObj; // Direct map response
                }
                
                System.debug(LoggingLevel.ERROR, 'Unexpected response format: ' + res.getBody());
                return null;
            } else {
                System.debug(LoggingLevel.ERROR, 'Failed to fetch location details. Status Code: ' 
                             + res.getStatusCode() + '. Body: ' + res.getBody());
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in fetchLocationDetails: ' + e.getMessage() 
                         + ' Stack: ' + e.getStackTraceString());
            return null;
        }
    }
    
    // Get authentication token for ServiceChannel API
    private static String getServiceChannelAuthToken() {
        // 1. Check cache
        if (tokenCache != null && tokenExpiry != null && DateTime.now() < tokenExpiry) {
            System.debug('Returning cached Service Channel token.');
            return tokenCache;
        }
        
        System.debug('Cache miss or expired. Fetching new Service Channel token.');
        // 2. Fetch Credentials from Custom Setting
        // Using try-catch for safety in case the setting or fields don't exist
        
        
        // if (creds == null || !creds.Is_Active__c || String.isBlank(creds.Login_URL__c) || String.isBlank(creds.Username__c) || String.isBlank(creds.Password__c) || String.isBlank(creds.Encoded_Auth__c)) {
        //     System.debug(LoggingLevel.ERROR, 'Active Service Channel credentials not found or incomplete in Custom Settings: ' + CREDENTIAL_SETTING_NAME);
        //     return null;
        // }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://sb2login.servicechannel.com/oauth/token');
        req.setMethod('POST');
        req.setHeader('Authorization', 'Basic UFIuMjAwMDA2MzE0Ni5EMDFEM0E4OC0yQ0NGLTQ5ODItOURDRS1EQUVEQTUyMEYwNzI6NDQzQkVGMUQtQjQwMy00RDk2LUFDNTItQjQxMUYxRDY0NzJG');
        // Set content type for form data
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        // Set timeout (recommended)
        req.setTimeout(60000); // 60 seconds
        
        // Construct body
        String requestBody = 'grant_type=password' +
            '&username=' + EncodingUtil.urlEncode('KEYST62712', 'UTF-8') +
            '&password=' + EncodingUtil.urlEncode('Keystone1', 'UTF-8');
        req.setBody(requestBody);
        
        Http http = new Http();
        HttpResponse res = null;
        try {
            res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                system.debug('response map'+responseMap);
                system.debug('access_token');
                if (responseMap.containsKey('access_token') && responseMap.containsKey('expires_in')) {
                    tokenCache = (String) responseMap.get('access_token');
                    system.debug('access token'+tokenCache);
                    // Ensure expires_in is treated as Decimal or Double before converting to Integer if necessary
                    Object expiresInObj = responseMap.get('expires_in');
                    Integer expiresInSeconds = 0;
                    if (expiresInObj instanceof Decimal) {
                        expiresInSeconds = ((Decimal)expiresInObj).intValue();
                    } else if (expiresInObj instanceof Double) {
                        expiresInSeconds = ((Double)expiresInObj).intValue();
                    } else if (expiresInObj instanceof Integer) {
                        expiresInSeconds = (Integer)expiresInObj;
                    }
                    
                    if (expiresInSeconds > 60) { // Only cache if expiry is reasonably long
                        // Add a small buffer (e.g., 60 seconds) to expiry to avoid race conditions near expiry time
                        tokenExpiry = DateTime.now().addSeconds(expiresInSeconds - 60);
                        System.debug('Successfully obtained and cached new Service Channel token. Expires at: ' + tokenExpiry);
                    } else {
                        tokenExpiry = DateTime.now().addSeconds(expiresInSeconds); // Use exact expiry if very short
                        System.debug('Successfully obtained new Service Channel token (short expiry). Expires at: ' + tokenExpiry);
                    }
                    return tokenCache;
                } else {
                    System.debug(LoggingLevel.ERROR, 'Service Channel Auth response missing access_token or expires_in. Body: ' + res.getBody());
                    tokenCache = null; // Clear cache on error
                    tokenExpiry = null;
                    return null;
                }
            } else {
                System.debug(LoggingLevel.ERROR, 'Failed to authenticate with ServiceChannel API. Status Code: ' + res.getStatusCode() + '. Body: ' + res.getBody());
                tokenCache = null; // Clear cache on error
                tokenExpiry = null;
                return null;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception during Service Channel Auth callout: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            tokenCache = null; // Clear cache on error
            tokenExpiry = null;
            return null;
        }
    }
    /**
* @description Gets or creates a Sites__c record based on SC Store ID and Corporate ID.
* @param scStoreId The Service Channel Store ID (from Location.StoreId).
* @param scLocationId The Service Channel internal Location ID (from Location.Id).
* @param locationInfo Map containing location details from SC payload (Name, Address, etc.).
* @param corporateId The ID of the parent Corporate__c record.
* @return Sites__c The found or newly created Sites__c record, or null on failure.
*/
    /**
* @description Gets or creates a Sites__c record based on SC Store ID and Corporate ID, using detailed location data from the API.
* @param scStoreId The Service Channel Store ID (e.g., "00241").
* @param scLocationId The Service Channel Location ID (e.g., "2006085096").
* @param detailedLocationInfo Map containing detailed location data from the SC API response.
* @param corporateId The ID of the parent Corporate__c record.
* @param brandId The ID of the parent Brand__c record.
* @return Sites__c The found or newly created Sites__c record, or null on failure.
*/
    /**
* @description Gets or creates a Sites__c record based on SC Store ID and Corporate ID, using detailed location data from the API.
* @param scStoreId The Service Channel Store ID (e.g., "00241").
* @param scLocationId The Service Channel Location ID (e.g., "2006085096").
* @param detailedLocationInfo Map containing detailed location data from the SC API response.
* @param corporateId The ID of the parent Corporate__c record.
* @param brandId The ID of the parent Brand__c record.
* @return Sites__c The found or newly created Sites__c record, or null on failure.
*/
    private static Sites__c getOrCreateSite(String scStoreId, String scLocationId, Map<String, Object> detailedLocationInfo, Id corporateId, Id brandId) {
        if (String.isBlank(scStoreId) || corporateId == null || detailedLocationInfo == null) {
            System.debug(LoggingLevel.ERROR, 'Invalid parameters for getOrCreateSite. scStoreId: ' + scStoreId + ', corporateId: ' + corporateId + ', detailedLocationInfo: ' + detailedLocationInfo);
            return null;
        }
        
        // Check for existing Sites__c
        List<Sites__c> existingSites = [SELECT Id, Name FROM Sites__c WHERE External_Site_ID__c = :scStoreId AND Corporate__c = :corporateId LIMIT 1];
        if (!existingSites.isEmpty()) {
            System.debug('Found existing Sites__c ID: ' + existingSites[0].Id + ' for SC Store ID: ' + scStoreId);
            return existingSites[0];
        }
        
        // Create new Sites__c using detailed location info from API
        Sites__c newSite = new Sites__c();
        newSite.Name = (String) detailedLocationInfo.get('Name'); // e.g., "1350 Braselton Parkway"
        newSite.Corporate__c = corporateId;
        newSite.Brand__c = brandId;
        newSite.External_Site_Name__c = (String) detailedLocationInfo.get('Name');
        newSite.External_Site_ID__c = scStoreId; // e.g., "00241"
        
        // Map additional fields from the API response (adjust field names to match your Sites__c object)
        //   newSite.Address__c = String.valueOf(detailedLocationInfo.get('Address1')) + ' ' + String.valueOf(detailedLocationInfo.get('Address2')); // e.g., "Ste 100 1350 Braselton Parkway"
        newSite.Address__City__s = (String) detailedLocationInfo.get('City');     // e.g., "Braselton"
        // newSite.State__c = (String) detailedLocationInfo.get('State');   // e.g., "GA"
        //newSite.Zip__c = (String) detailedLocationInfo.get('Zip');       // e.g., "30517-5324"
        // newSite.Country__c = (String) detailedLocationInfo.get('Country'); // e.g., "US"
        newSite.Address__Latitude__s = (Decimal) detailedLocationInfo.get('Latitude');   // e.g., 34.11312464
        newSite.Address__Longitude__s = (Decimal) detailedLocationInfo.get('Longitude'); // e.g., -83.78256645
        
        Database.SaveResult sr = Database.insert(newSite, false);
        if (sr.isSuccess()) {
            System.debug('Created Sites__c ID: ' + sr.getId() + ' for SC Store ID: ' + scStoreId);
            newSite.Id = sr.getId();
            return newSite;
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to insert Sites__c for SC Store ID: ' + scStoreId + '. Errors: ' + sr.getErrors());
            return null;
        }
    }
    public static Brand__c getOrCreateBrand(String scSubscriberId, Map<String, Object> subscriberInfo, Id corporateId) {
        if (String.isBlank(scSubscriberId) || subscriberInfo == null || corporateId == null) {
            System.debug(LoggingLevel.ERROR, 'Invalid parameters for getOrCreateBrand. scProviderId: ' + scSubscriberId + ', corporateId: ' + corporateId);
            return null;
        }
        system.debug('corporate Id for Brand'+corporateId);
        // Check for existing Brand__c with the same External_Brand_ID__c and Corporate__c
        List<Brand__c> existingBrands = [SELECT Id, Name FROM Brand__c 
                                         WHERE External_Brand_ID__c = :scSubscriberId 
                                         AND Corporate__c = :corporateId 
                                         LIMIT 1];
        if (!existingBrands.isEmpty()) {
            //  System.debug('Found existing Brand__c ID: ' + existingBrands[0].Id + ' for SC Provider ID: ' + scSubscriberId + ' and Corporate ID: ' + corporateId);
            return existingBrands[0];
        }
        
        // Create new Brand__c
        Brand__c newBrand = new Brand__c(
            Name = (String)  subscriberInfo.get('Name'), // "API SANDBOX"
            External_Brand_ID__c = scSubscriberId, // "2014917243"
            External_Brand_Name__c =  (String) subscriberInfo.get('Name'),
            //   Phone__c = (String) providerInfo.get('Phone'),// "7188675309"
            Corporate__c = corporateId, // Link to the newly created Corporate__c
            External_Brand_Source__c = 'Service Channel'
        );
        
        Database.SaveResult sr = Database.insert(newBrand, false);
        system.debug('Created Brand Record'+newBrand.Id);
        if (sr.isSuccess()) {
            //     System.debug('Created Brand__c ID: ' + sr.getId() + ' for SC Provider ID: ' + scProviderId + ' and Corporate ID: ' + corporateId);
            newBrand.Id = sr.getId();
            return newBrand;
        } else {
            //      System.debug(LoggingLevel.ERROR, 'Failed to insert Brand__c for SC Provider ID: ' + scProviderId + '. Errors: ' + sr.getErrors());
            return null;
        }
    }
    // --- Add other methods as needed based on NestJS service ---
    // e.g., getServiceChannelWOStatus, postServiceChannelWOStatus, tripCheckInSC, tripCheckOutSc, etc.
    // These would likely involve callouts via ServiceChannelHelper and mapping via ServiceChannelMapper.
}