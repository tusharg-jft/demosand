public with sharing class TradeController {
    
    @AuraEnabled(cacheable=true)
    public static List<Trade__c> getTradesByGLCode(Id glCodeId) {
        try {
            return [SELECT Id, Name, GL_Code__c, IsActive__c FROM Trade__c WHERE GL_Code__c = :glCodeId];
        } catch (Exception e) {
            System.debug('Error fetching trades: ' + e.getMessage());
            throw new AuraHandledException('Error fetching trades: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static void saveFile(String fileName, String base64, Id recordId) {
        try {
            Blob fileBlob = EncodingUtil.base64Decode(base64);
            
            ContentVersion cv = new ContentVersion();
            cv.VersionData = fileBlob;
            cv.Title = fileName;
            cv.PathOnClient = fileName;
            insert cv; 
            
            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];
            
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cd.Id; 
            cdl.LinkedEntityId = recordId; 
            cdl.Visibility = 'AllUsers'; 
            insert cdl; 
            
        } catch (Exception e) {
            System.debug('Error saving file: ' + e.getMessage());
            throw new AuraHandledException('Error saving file: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Trade__c> getTrades() {
        try {
            return [SELECT Id, Name FROM Trade__c ORDER BY Name ASC];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching trades: ' + e.getMessage());
        }
    }
}