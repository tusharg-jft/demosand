public class SitesTriggerHandler {
    public static void handleAfterInsert(List<Sites__c> newSites) {
        // Query Sites with related Brand and Users
        List<Sites__c> sitesWithRelatedData = [
            SELECT Id, Brand__c, BrandUser__c, Site_User__c, Corporate__c,
                   Brand__r.CorporateUser__c,Brand__r.BrandOwner__c, Corporate__r.User__c,
                   CreatedBy.Profile.Name, CreatedById
            FROM Sites__c 
            WHERE Id IN :newSites
        ];
        
        List<Sites__Share> sharesToCreate = new List<Sites__Share>();
        List<Sites__c> sitesToUpdate = new List<Sites__c>();
        
        for(Sites__c site : sitesWithRelatedData) {
            Sites__c siteToUpdate = new Sites__c(Id = site.Id);
            
            // Corporate Profile user creating record
            if(site.CreatedBy.Profile.Name == 'Corporate Profile') {
                // Update corporate user with current logged in user
                siteToUpdate.CorpUser__c = site.CreatedById;
                sitesToUpdate.add(siteToUpdate);
                
                // Share with Brand User from Brand
                if(site.Brand__c != null && site.Brand__r.brandOwner__c != null) {
                    sharesToCreate.add(SharingHelper.createSiteShare(site.Id, site.Brand__r.brandOwner__c));
                }
                
                // Share with Site User
                if(site.Site_User__c != null) {
                    sharesToCreate.add(SharingHelper.createSiteShare(site.Id, site.Site_User__c));
                }
            }
            // Brand Profile user creating record
            else if(site.CreatedBy.Profile.Name == 'Brand Profile') {
                // Update brand user with current logged in user
                siteToUpdate.BrandUser__c = site.CreatedById;
                sitesToUpdate.add(siteToUpdate);
                
                // Share with Corporate User from Corporate
                if(site.Corporate__c != null && site.Corporate__r.User__c != null) {
                    sharesToCreate.add(SharingHelper.createSiteShare(site.Id, site.Corporate__r.User__c));
                }
                
                // Share with Site User
                if(site.Site_User__c != null) {
                    sharesToCreate.add(SharingHelper.createSiteShare(site.Id, site.Site_User__c));
                }
            }
        }
        
        if(!sitesToUpdate.isEmpty()) {
            update sitesToUpdate;
        }
        
        if(!sharesToCreate.isEmpty()) {
            Database.insert(sharesToCreate, false);
        }
    }
}