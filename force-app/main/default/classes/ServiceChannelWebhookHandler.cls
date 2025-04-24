@RestResource(urlMapping='/servicechannel/webhook')
global with sharing class ServiceChannelWebhookHandler {
    
    @HttpPost
    global static void receiveWorkOrder() {
        System.debug('Creating WO**********');
        
        System.debug('Found payload to process');
        Webhook_Switch_Service_Channel__mdt serviceSwitch = [SELECT Id, ProcessPayload__c FROM Webhook_Switch_Service_Channel__mdt];
        System.debug('Payload switch value: ' + serviceSwitch.ProcessPayload__c);
        
        if (serviceSwitch.ProcessPayload__c == false) {
            System.debug('Processing of Service Channel is disabled');
            return;
        }
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        try {
            // Parse the incoming JSON payload
            String requestBody = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            
            System.debug('Received Service Channel Webhook Payload: ' + requestBody);
            
            // Extract EventType if it exists
            String eventType = '';
            if (payload.containsKey('EventType')) {
                eventType = (String) payload.get('EventType');
            }
            
            // Store the payload in Webhook_Payload__c
            Webhook_Payload__c webhookRecord = new Webhook_Payload__c(
                Payload__c = requestBody,
                Status__c = 'Pending',
                Event_Type__c = eventType
            );
            
            insert webhookRecord;
            System.debug('Stored webhook payload in Webhook_Payload__c ID: ' + webhookRecord.Id);
            
            // Send a success response immediately (acknowledgement)
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"message": "Webhook received successfully"}');
            
        } catch (Exception e) {
            System.debug('Error processing Service Channel webhook: ' + e.getMessage() + ' Stack: ' + e.getStackTraceString());
            
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error": "' + e.getMessage() + '"}');
        }
    }
}