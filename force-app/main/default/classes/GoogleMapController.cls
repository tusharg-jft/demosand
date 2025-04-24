public with sharing class GoogleMapController 
{
  
    @AuraEnabled(cacheable=true)
    public static List<Account> getCompanyLocations(String accountNameInitial){
       String str = accountNameInitial + '%';
       return [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
               FROM Account 
               WHERE Name LIKE :str];       
   }
   
}