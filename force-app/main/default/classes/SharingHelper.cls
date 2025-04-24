public class SharingHelper {
    private static final String BRAND_PROFILE = 'Brand Profile';
    private static final String SITE_PROFILE = 'Site Profile';
    private static final String CORPORATE_PROFILE = 'Corporate Profile';
    
    public static Sites__Share createSiteShare(Id siteId, Id userId) {
        return new Sites__Share(
            ParentId = siteId,
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Sites__Share.RowCause.Manual
        );
    }
    
    public static List<User> getBrandUsers() {
        return [SELECT Id, Name 
                FROM User 
                WHERE Profile.Name = :BRAND_PROFILE 
                AND IsActive = true];
    }
    
    public static List<User> getSiteUsers() {
        return [SELECT Id, Name 
                FROM User 
                WHERE Profile.Name = :SITE_PROFILE 
                AND IsActive = true];
    }
    
    public static List<User> getCorporateUsers() {
        return [SELECT Id, Name 
                FROM User 
                WHERE Profile.Name = :CORPORATE_PROFILE 
                AND IsActive = true];
    }
    
    public static Boolean hasBrandProfile(Id userId) {
        List<User> users = [SELECT Id FROM User 
                            WHERE Id = :userId 
                            AND Profile.Name = :BRAND_PROFILE 
                            AND IsActive = true 
                            LIMIT 1];
        return !users.isEmpty();
    }
    
    public static Boolean hasSiteProfile(Id userId) {
        List<User> users = [SELECT Id FROM User 
                            WHERE Id = :userId 
                            AND Profile.Name = :SITE_PROFILE 
                            AND IsActive = true 
                            LIMIT 1];
        return !users.isEmpty();
    }
    
    public static Boolean hasCorporateProfile(Id userId) {
        List<User> users = [SELECT Id FROM User 
                            WHERE Id = :userId 
                            AND Profile.Name = :CORPORATE_PROFILE 
                            AND IsActive = true 
                            LIMIT 1];
        return !users.isEmpty();
    }
    
    public static Brand__Share createBrandShare(Id brandId, Id userId) {
        return new Brand__Share(
            ParentId = brandId,
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Brand__Share.RowCause.Manual
        );
    }
    
    // This is to make sure tha brand user should get the read only access to the corporate.
    public static Corporate__Share createCorporateShare(Id corporateId, Id userId) {
        return new Corporate__Share(
            ParentId = corporateId,
            UserOrGroupId = userId,
            AccessLevel = 'Read',
            RowCause = Schema.Corporate__Share.RowCause.Manual
        );
    }
    
    public static Work_Order__Share createWorkOrderShare(Id workOrderId, Id userId) {
        return new Work_Order__Share(
            ParentId = workOrderId,
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Work_Order__Share.RowCause.Manual
        );
    }
    public static Trip__Share createTripShare(Id tripId,Id userId){
        return new Trip__Share(
            parentId = tripId,
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Trip__Share.RowCause.Manual );
    }
     public static Work_Order__Share createVendorShare(Id workOrderId,Id userId){
        return new Work_Order__Share(
            parentId = workOrderId,
            UserOrGroupId = userId,
            AccessLevel = 'Edit',
            RowCause = Schema.Trip__Share.RowCause.Manual );
    }
     public static Work_Order__Share createWorkOrderReadOnlyShare(Id workOrderId, Id userId) {
        return new Work_Order__Share(
            ParentId = workOrderId,
            UserOrGroupId = userId,
            AccessLevel = 'Read',
            RowCause = Schema.Work_Order__Share.RowCause.Manual
        );
    }
    
    
    
}