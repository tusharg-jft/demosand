public with sharing class BrandUserController {
    @AuraEnabled(cacheable=true)
    public static List<User> getBrandUsers(String searchKey) {
        String key = '%' + searchKey + '%';
        String brandProfileId = [SELECT Id FROM Profile WHERE Name = 'Brand Profile' LIMIT 1].Id;
        
        return [
            SELECT Id, Name, Email
            FROM User
            WHERE ProfileId = :brandProfileId
            AND Name LIKE :key
            AND IsActive = true
            ORDER BY Name
            LIMIT 10
        ];
    }
}