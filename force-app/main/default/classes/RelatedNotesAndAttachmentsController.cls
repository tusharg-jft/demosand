public with sharing class RelatedNotesAndAttachmentsController {
    @AuraEnabled(cacheable=true)
    public static List<ContentDocumentLink> getRelatedDocuments(Id targetObjectId) {
        return [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.ContentSize
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :targetObjectId
        ];
    }
}