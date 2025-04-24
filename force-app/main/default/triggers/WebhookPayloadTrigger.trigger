trigger WebhookPayloadTrigger on Webhook_Payload__c (after insert) {
 String currentUserId = UserInfo.getUserId();
String currentUserName = UserInfo.getName();
String currentUserEmail = UserInfo.getUserEmail();

System.debug('UserInfo.getName()='+UserInfo.getName());
    for(Webhook_Payload__c wp : Trigger.new) {
        if(wp.Payload__c != null) {
            System.debug('UserInfo.getName11()='+UserInfo.getName());
            System.debug('UserInfo.getUserEmail()='+UserInfo.getUserEmail());

            ServiceChannelService.processWebhook(wp.Payload__c); 
            
        }
    }
    
    
}