/**
 * @description Helper class for making HTTP callouts to the Service Channel API.
 *              Uses Named Credentials for endpoint and authentication management.
 */
public with sharing class ServiceChannelHelper {

    // Assumes a Named Credential named 'Service_Channel_API' is configured
    private static final String NAMED_CREDENTIAL = 'callout:Service_Channel_API'; 
    private static final Integer TIMEOUT_MS = 120000; // 120 seconds timeout

    // Placeholder endpoint paths - replace with actual paths from SC API documentation
    private static final String EP_WORK_ORDER_GET = '/workorders/{0}'; // Example: GET /api/workorders/{workOrderId}
    private static final String EP_WORK_ORDER_STATUS = '/workorders/{0}/status'; // Example: GET /api/workorders/{workOrderId}/status
    private static final String EP_STATUS_UPDATE = '/workorders/{0}/statusupdate'; // Example: POST /api/workorders/{workOrderId}/statusupdate
    private static final String EP_ADD_NOTE = '/workorders/{0}/notes'; // Example: POST /api/workorders/{workOrderId}/notes
    private static final String EP_NOTE_RECIPIENTS = '/workorders/{0}/noterecipients'; // Example: GET /api/workorders/{workOrderId}/noterecipients
    private static final String EP_TRIP_CHECKIN = '/workorders/{0}/checkin'; // Example: POST /api/workorders/{workOrderId}/checkin
    private static final String EP_TRIP_CHECKOUT = '/workorders/{0}/checkout'; // Example: POST /api/workorders/{workOrderId}/checkout
    private static final String EP_ATTACHMENT_POST = '/workorders/{0}/attachments?UserName={1}'; // Example: POST /api/workorders/{workOrderId}/attachments?UserName={encodedUserName}
    private static final String EP_ADD_INVOICE = '/invoices'; // Example: POST /api/invoices
    private static final String EP_STORE_GET = '/locations/{0}'; // Example: GET /api/locations/{locationId}
    private static final String EP_GET_PRIORITIES = '/subscribers/{0}/priorities'; // Example: GET /api/subscribers/{subscriberId}/priorities

    /**
     * @description Makes an HTTP request to the Service Channel API.
     * @param method The HTTP method (e.g., 'GET', 'POST').
     * @param endpointPath The specific API endpoint path (relative to Named Credential URL).
     * @param requestBody The JSON string for POST/PATCH requests (null for GET/DELETE).
     * @param contentType The content type header (e.g., 'application/json'). Defaults to JSON.
     * @return HttpResponse The response from the API.
     */
    private static HttpResponse makeRequest(String method, String endpointPath, String requestBody, String contentType) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        
        req.setEndpoint(NAMED_CREDENTIAL + endpointPath);
        req.setMethod(method.toUpperCase());
        req.setTimeout(TIMEOUT_MS);
        
        // Default headers
        req.setHeader('Accept', 'application/json');
        if (String.isNotBlank(contentType)) {
             req.setHeader('Content-Type', contentType);
        } else if (method.equalsIgnoreCase('POST') || method.equalsIgnoreCase('PATCH') || method.equalsIgnoreCase('PUT')) {
             req.setHeader('Content-Type', 'application/json; charset=UTF-8');
        }

        if (String.isNotBlank(requestBody)) {
            req.setBody(requestBody);
        }

        HttpResponse res = null;
        try {
            System.debug('ServiceChannelHelper Request: ' + method + ' ' + req.getEndpoint());
            if(String.isNotBlank(requestBody)) {
                 System.debug('ServiceChannelHelper Request Body: ' + requestBody);
            }
            
            res = http.send(req);
            
            System.debug('ServiceChannelHelper Response Status: ' + res.getStatusCode() + ' ' + res.getStatus());
             System.debug('ServiceChannelHelper Response Body: ' + res.getBody());

            // Basic error handling for non-2xx responses
            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                handleHttpError(req, res);
                // Optionally throw a custom exception here
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ServiceChannelHelper Callout Error: ' + e.getMessage() + ' for ' + method + ' ' + req.getEndpoint() + ' Stack: ' + e.getStackTraceString());
            // Optionally throw a custom exception here
            throw new CalloutException('Service Channel API callout failed: ' + e.getMessage());
        }
        return res;
    }
    
     /**
     * @description Makes a GET request and deserializes the JSON response.
     * @param endpointPath The specific API endpoint path.
     * @return Map<String, Object> The deserialized JSON response, or null on error.
     */
    private static Map<String, Object> makeGetRequest(String endpointPath) {
         HttpResponse res = makeRequest('GET', endpointPath, null, null);
         if (res != null && res.getStatusCode() >= 200 && res.getStatusCode() < 300 && String.isNotBlank(res.getBody())) {
             try {
                 return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
             } catch (Exception e) {
                  System.debug(LoggingLevel.ERROR, 'ServiceChannelHelper: Failed to deserialize GET response from ' + endpointPath + '. Error: ' + e.getMessage());
                  return null;
             }
         }
         return null;
    }

    /**
     * @description Makes a POST request and deserializes the JSON response.
     * @param endpointPath The specific API endpoint path.
     * @param payload The request payload object (will be serialized to JSON).
     * @return Map<String, Object> The deserialized JSON response, or null on error.
     */
    private static Map<String, Object> makePostRequest(String endpointPath, Object payload) {
         String requestBody = JSON.serialize(payload, true); // Suppress nulls
         HttpResponse res = makeRequest('POST', endpointPath, requestBody, 'application/json; charset=UTF-8');
         if (res != null && res.getStatusCode() >= 200 && res.getStatusCode() < 300 && String.isNotBlank(res.getBody())) {
              try {
                 // Handle cases where response might not be JSON or could be empty
                 if (res.getBody().trim().startsWith('{') || res.getBody().trim().startsWith('[')) {
                    return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                 } else {
                     // Handle non-JSON success responses if applicable (e.g., simple text confirmation)
                     Map<String, Object> successResult = new Map<String, Object>{'result' => res.getBody()};
                     return successResult;
                 }
             } catch (Exception e) {
                  System.debug(LoggingLevel.ERROR, 'ServiceChannelHelper: Failed to deserialize POST response from ' + endpointPath + '. Error: ' + e.getMessage());
                  return null;
             }
         }
         return null; // Return null if status code indicates failure or body is empty
    }

    /**
     * @description Handles HTTP errors by logging details.
     * @param req The HttpRequest that failed.
     * @param res The HttpResponse received.
     */
    private static void handleHttpError(HttpRequest req, HttpResponse res) {
        String errorMessage = 'Service Channel API Error. Status: ' + res.getStatusCode() + ' ' + res.getStatus() +
                              '. Endpoint: ' + req.getMethod() + ' ' + req.getEndpoint();
        if (String.isNotBlank(res.getBody())) {
            errorMessage += '. Response Body: ' + res.getBody();
        }
        System.debug(LoggingLevel.ERROR, errorMessage);
        // Consider creating a custom Log__c record or Platform Event here
    }

    // --- Public methods for specific API calls ---

    /**
     * @description Gets Work Order details from Service Channel.
     * @param workOrderId The Service Channel Work Order ID.
     * @return Map<String, Object> Deserialized Work Order data or null.
     */
    public static Map<String, Object> getWorkOrder(String workOrderId) {
        String path = String.format(EP_WORK_ORDER_GET, new List<String>{workOrderId});
        return makeGetRequest(path);
    }

    /**
     * @description Gets Work Order status details from Service Channel.
     * @param workOrderId The Service Channel Work Order ID.
     * @param subscriberId The Service Channel Subscriber ID (if needed by API).
     * @return Map<String, Object> Deserialized status data or null.
     */
    // Adjust signature if subscriberId isn't needed or comes from elsewhere
    public static Map<String, Object> getWorkOrderStatus(String workOrderId, String subscriberId) {
         // Assuming EP_WORK_ORDER_STATUS needs both IDs, adjust if not
        String path = String.format(EP_WORK_ORDER_STATUS, new List<String>{workOrderId}); 
        // Add subscriberId as query param if needed: path += '?subscriberId=' + EncodingUtil.urlEncode(subscriberId, 'UTF-8');
        return makeGetRequest(path);
    }
    
    /**
     * @description Updates the status of a Work Order in Service Channel.
     * @param workOrderId The Service Channel Work Order ID.
     * @param statusPayload Payload containing the new status details.
     * @return Map<String, Object> Deserialized response or null.
     */
    public static Map<String, Object> updateWorkOrderStatus(String workOrderId, Map<String, Object> statusPayload) {
        String path = String.format(EP_STATUS_UPDATE, new List<String>{workOrderId});
        return makePostRequest(path, statusPayload);
    }

    /**
     * @description Adds a note to a Work Order in Service Channel.
     * @param workOrderId The Service Channel Work Order ID.
     * @param notePayload Payload containing the note details.
     * @return Map<String, Object> Deserialized response (e.g., containing the new note ID) or null.
     */
    public static Map<String, Object> addNote(String workOrderId, Map<String, Object> notePayload) {
        String path = String.format(EP_ADD_NOTE, new List<String>{workOrderId});
        return makePostRequest(path, notePayload);
    }
    
     /**
     * @description Gets note recipients for a Work Order from Service Channel.
     * @param workOrderId The Service Channel Work Order ID.
     * @return Map<String, Object> Deserialized recipient data or null.
     */
    public static Map<String, Object> getNoteRecipients(String workOrderId) {
        String path = String.format(EP_NOTE_RECIPIENTS, new List<String>{workOrderId});
        return makeGetRequest(path);
    }

    /**
     * @description Performs a trip check-in in Service Channel.
     * @param workOrderId The Service Channel Work Order ID.
     * @param checkinPayload Payload containing check-in details.
     * @return Map<String, Object> Deserialized response or null.
     */
    public static Map<String, Object> tripCheckIn(String workOrderId, Map<String, Object> checkinPayload) {
        String path = String.format(EP_TRIP_CHECKIN, new List<String>{workOrderId});
        return makePostRequest(path, checkinPayload);
    }

    /**
     * @description Performs a trip check-out in Service Channel.
     * @param workOrderId The Service Channel Work Order ID.
     * @param checkoutPayload Payload containing check-out details.
     * @return Map<String, Object> Deserialized response or null.
     */
    public static Map<String, Object> tripCheckOut(String workOrderId, Map<String, Object> checkoutPayload) {
        String path = String.format(EP_TRIP_CHECKOUT, new List<String>{workOrderId});
        return makePostRequest(path, checkoutPayload);
    }

    /**
     * @description Adds an invoice to Service Channel.
     * @param invoicePayload Payload containing the invoice details.
     * @return Map<String, Object> Deserialized response (e.g., containing the new invoice ID) or null.
     */
    public static Map<String, Object> addInvoice(Map<String, Object> invoicePayload) {
        return makePostRequest(EP_ADD_INVOICE, invoicePayload);
    }
    
    /**
     * @description Gets Store (Location) details from Service Channel.
     * @param locationId The Service Channel Location ID.
     * @return Map<String, Object> Deserialized location data or null.
     */
    public static Map<String, Object> getStoreDetails(String locationId) {
        String path = String.format(EP_STORE_GET, new List<String>{locationId});
        return makeGetRequest(path);
    }
    
    /**
     * @description Gets Priorities for a Subscriber from Service Channel.
     * @param subscriberId The Service Channel Subscriber ID.
     * @return Map<String, Object> Deserialized priority data or null.
     */
    public static Map<String, Object> getPriorities(String subscriberId) {
        String path = String.format(EP_GET_PRIORITIES, new List<String>{subscriberId});
        return makeGetRequest(path);
    }

    /**
     * @description Posts an attachment to a Work Order in Service Channel.
     *              Handles multipart/form-data encoding.
     * @param workOrderId The Service Channel Work Order ID.
     * @param fileName The name of the file being attached.
     * @param fileBody The Blob content of the file.
     * @param userName The name of the user uploading the file (for SC API).
     * @return Map<String, Object> Deserialized response or null.
     */
    public static Map<String, Object> addAttachment(String workOrderId, String fileName, Blob fileBody, String userName) {
        String encodedUserName = EncodingUtil.urlEncode(userName, 'UTF-8');
        String endpointPath = String.format(EP_ATTACHMENT_POST, new List<String>{workOrderId, encodedUserName});
        
        // Construct multipart/form-data body
        String boundary = '----WebKitFormBoundary' + DateTime.now().getTime();
        String header = '--' + boundary + '\r\n' +
                        'Content-Disposition: form-data; name="file"; filename="' + fileName + '"\r\n' +
                        'Content-Type: application/octet-stream\r\n\r\n'; // Adjust Content-Type if needed
        String footer = '\r\n--' + boundary + '--\r\n'; // Added final CRLF to footer

        // Encode the file body
        String encodedFileBody = EncodingUtil.base64Encode(fileBody);

        // Construct the full request body as a string
        // NOTE: Base64 encoding might not be the correct way Service Channel expects the raw binary.
        // If this fails, the API might require raw bytes which is harder with standard HttpRequest.
        // Consider alternatives like Composite API if SC supports it, or check SC docs for raw binary uploads.
        // For now, proceeding with Base64 as a common pattern.
        // UPDATE: Standard Apex HttpRequest does not directly support raw binary in multipart.
        // Let's try setting the body directly as a string concatenation.
        String bodyString = header + EncodingUtil.base64Encode(fileBody) + footer;


        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + endpointPath);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
        req.setHeader('Accept', 'application/json');
        // Set the body as a string - Apex handles the conversion.
        // Ensure the Blob is not excessively large, as it might hit heap limits when encoded/converted.
        req.setBody(bodyString);
        req.setTimeout(TIMEOUT_MS);

        Http http = new Http();
        HttpResponse res = null;
        try {
             System.debug('ServiceChannelHelper Attachment Request: POST ' + req.getEndpoint());
             res = http.send(req);
             System.debug('ServiceChannelHelper Attachment Response Status: ' + res.getStatusCode() + ' ' + res.getStatus());
             System.debug('ServiceChannelHelper Attachment Response Body: ' + res.getBody());

             if (res.getStatusCode() >= 200 && res.getStatusCode() < 300 && String.isNotBlank(res.getBody())) {
                 try {
                     // Assuming response is JSON, adjust if not
                     return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                 } catch (Exception e) {
                     System.debug(LoggingLevel.ERROR, 'ServiceChannelHelper: Failed to deserialize Attachment POST response from ' + endpointPath + '. Error: ' + e.getMessage());
                     return null;
                 }
             } else {
                 handleHttpError(req, res);
                 return null;
             }
        } catch (Exception e) {
             System.debug(LoggingLevel.ERROR, 'ServiceChannelHelper Attachment Callout Error: ' + e.getMessage() + ' for POST ' + req.getEndpoint() + ' Stack: ' + e.getStackTraceString());
             throw new CalloutException('Service Channel API attachment callout failed: ' + e.getMessage());
        }
    }
}