public with sharing class EstimateController {

   
    public Id RecordId {get;set;}
    public Estimate__c objEstimate{get;set;}
    public list<Estimate_Line_Items__c> estItemList{get;set;}
    public String PDFNo{get;set;}
    public String EFNo{get;set;}
    public boolean show{get;set;}
    public boolean showpdf{get;set;}
    public ApexPages.PageReference page2{get;set;}
    
    public EstimateController(ApexPages.StandardController controller){
        RecordId  = ApexPages.currentPage().getParameters().get('id');
        objEstimate=[SELECT Id,Name,Estimate_Date__c,total_amount__c,Tax__c,Status__c,Email__c, Contact__c, Contact__r.Name, Contact__r.MailingStreet, Contact__r.MailingCity, Contact__r.MailingState, Contact__r.MailingPostalCode, Contact__r.MailingCountry, Contact__r.Email from Estimate__c where Id = :RecordId ];
        getEstimateLine(RecordId);
    }
    
    public void save(){
        PageReference savepage ;
        savepage = Page.Estimate;
        savepage.getParameters().put('id',RecordId);
        system.debug('id:- '+RecordId);
        blob pdfBlob;
        if (!Test.isRunningTest()) {
            pdfBlob = savepage.getContent(); //generate the pdf blob
        } else { 
            pdfBlob = Blob.valueOf('Test');
        }
        List<ContentDocumentLink> notesattch = [select id, ContentDocument.Title,LinkedEntityId from ContentDocumentLink where LinkedEntityId =: RecordId order by ContentDocument.Title asc];    
        list<string> docId = new list<string>();
        system.debug('notesattch## ' + notesattch);
        PageReference savepage2 = Page.Estimate;
        ContentDocumentLink conDocLink = New ContentDocumentLink();
        ContentVersion conVer = new ContentVersion();
        if(notesattch.size() > 0)
        {
            string title =  notesattch[0].ContentDocument.Title;
            system.debug('title111 ' + title);
            List<String> titleSplit = title.split('R');
            //String FinalTitle = titleSplit[0]+'R0'+notesattch.size();
            String FinalTitle = 'R0'+notesattch.size();
            system.debug('FinalTitle22 ' + FinalTitle);
            PDFNo=FinalTitle;
            
            
            conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
            conVer.PathOnClient = FinalTitle+'.pdf'; 
            conVer.Title = FinalTitle; 
            conVer.VersionData = pdfBlob;
            system.debug('conVer@@ ' + conVer);
            insert conVer;  
            
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            
            
            conDocLink.LinkedEntityId = RecordId;
            conDocLink.ContentDocumentId = conDoc; 
            conDocLink.shareType = 'V';
            insert conDocLink;
            //update accObj;
            
            show=false;
           showpdf=true;
            savepage2.getParameters().put('id',RecordId);
            //if(!show)
               // savepage2.getParameters().put('show','0');
           // savepage2.setRedirect(true);
            
        }
        else{
            
            //ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; // to use S specify this document is in Salesforce, to use E for external files
            conVer.PathOnClient = PDFNo+'.pdf'; 
            conVer.Title = 'R00'; 
            conVer.VersionData = pdfBlob;
            insert conVer;  
            
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            
            //ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = RecordId;
            conDocLink.ContentDocumentId = conDoc; 
            conDocLink.shareType = 'V';
            insert conDocLink;
            //Addtext = 'File Attached';
            
            //update accObj;
            
            show=false;
            showpdf=true;
            //Cafactionpage;CAFFormPDF
           savepage2.getParameters().put('id',RecordId);
          //  if(!show)
                //savepage2.getParameters().put('show','0');
            //savepage2.setRedirect(true);
            
            
        }
        docId.add(conVer.Id);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();   
        list<string> emailList = new list<string>();
        emailList.add(objEstimate.Email__c);
        email.setSubject('Estimate of your order');
        email.setToAddresses(emailList);//Use SOQL to retrieve addresses in the address
        email.setEntityAttachments(docId);
        email.setPlainTextBody('Dear '+objEstimate.Contact__r.Name+',\n I hope you are well. Please see attached Estimate number() for Service(), Which is due for payment on().\n Please dont hassitate to reach outif you have any question.\n Kind Regards,\n Mona');
        email.setBccSender(true);
        
        Messaging.SendEmailResult [] r = Messaging.SendEmail(new Messaging.SingleEmailMessage[] {email});     
        for ( Messaging.sendEmailResult result : r ) {
            
            if ( !r[0].isSuccess () ) {
                
                System.debug ( result  );
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Something went wrong...!!!'));
                
            }
            
            else{
               ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Email Sent Successfully')); 
                
            }
        }
        //return savepage2;
    }
    
    public void getEstimateLine(Id RecId){
        estItemList=[select Id,Name,Product__c,Quantity__c,Unit_Price__c,Total_Price__c,Estimate__c,Product__r.Name from Estimate_Line_Items__c where Estimate__c=: RecId];
    }
    
    
    
    
    /* 
Public class SendEmail
{
public String subject {get; set;}
public String body {get; set;}

private opportunity opp;

// Constructor to populate instance of your object
public SendEmail(ApexPages.StandardController controller) {
this.objEstimate= (Estimate_c )controller.getRecord();
objEstimate= [SELECT Estimate fields required
FROM objEstimate
WHERE id = :ApexPages.CurrentPage().getParameters().get('id')];
}

public objEstimate getEstimate(){
return objEstimate;
}
*/
    
    public pageReference send(){
        
        return null;  
    }
    
    
    
    //BELOW SECTION BY TUSHAR
    
    
    @AuraEnabled
    public static Id createEstimateRecord(String formData, Id workOrderId,  Decimal netPrice, Decimal grandTotal, Decimal totalDiscount , Integer internalnumber , String assesment  , String proposal , String estimateStatus ) {
        if (String.isBlank(formData) || workOrderId == null) {
            throw new AuraHandledException('Form data and Work Order Id are required.');
        }
        if(grandTotal==0){
            grandTotal = netPrice;
        }

        
        try {
            Estimate__c newEstimate = new Estimate__c();
            newEstimate.Estimate_Data__c = formData;
            newEstimate.Work_Orders__c= workOrderId;
            newEstimate.netPrice__c = netPrice;
            newEstimate.grandTotal__c = grandTotal;
            newEstimate.totalDiscount__c = totalDiscount;
            newEstimate.Internal_Estimate_No__c = internalnumber;
            newEstimate.Assessment_Troubleshoot__c = assesment;
            newEstimate.Proposal_For_Repairs__c = proposal;
            newEstimate.Status__c=estimateStatus;

            insert newEstimate;    

            return newEstimate.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Estimate: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static Id makenewestimateafterrejection(
        String formData,
        Id workOrderId,
        Decimal netPrice,
        Decimal grandTotal,
        Decimal totalDiscount,
        Integer internalnumber,
        String assesment,
        String proposal,
        Id parentEstimateId
    ) {
        Id finalParentEstimateId = parentEstimateId;

        if (parentEstimateId != null) {
            Estimate__c parentEstimate = [
                SELECT Id, parentestimate__c
                FROM Estimate__c
                WHERE Id = :parentEstimateId
                LIMIT 1
            ];
            parentEstimate.display__c='no';
            update parentEstimate;

            if (parentEstimate.parentestimate__c != null) {
                finalParentEstimateId = parentEstimate.parentestimate__c;
            }
        }

        Estimate__c newEstimate = new Estimate__c();
        newEstimate.Estimate_Data__c = formData;
        newEstimate.Work_Orders__c = workOrderId;
        newEstimate.netPrice__c = netPrice;
        newEstimate.grandTotal__c = grandTotal;
        newEstimate.totalDiscount__c = totalDiscount;
        newEstimate.Internal_Estimate_No__c = internalnumber;
        newEstimate.Assessment_Troubleshoot__c = assesment;
        newEstimate.Proposal_For_Repairs__c = proposal;
        newEstimate.parentestimate__c = finalParentEstimateId;
        newEstimate.Status__c = 'Submit for approval';

        insert newEstimate;
        return newEstimate.Id;
    }


    @AuraEnabled(cacheable=true)
public static Object getEstimateData(Id workOrderId) {
    if (workOrderId == null) {
        return null;
    }

    Work_Order__c wo = [SELECT Estimate_Data__c FROM Work_Order__c WHERE Id = :workOrderId LIMIT 1];
    return wo.Estimate_Data__c;
}


    @AuraEnabled(cacheable=true)
public static Object getIncurredData(Id workOrderId) {
    if (workOrderId == null) {
        return null;
    }

    Work_Order__c wo = [SELECT IncurredData__c FROM Work_Order__c WHERE Id = :workOrderId LIMIT 1];
    return wo.IncurredData__c;
}

 // Updated method to return currency fields in a List of Map format
 @AuraEnabled(cacheable=true)
 public static List<Map<String, String>> getCurrencyFields() {
     Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Vendor_Trade_Rate_Management__c').getDescribe().fields.getMap();
     List<Map<String, String>> currencyFields = new List<Map<String, String>>();

     for (String fieldName : fieldMap.keySet()) {
         Schema.DescribeFieldResult fieldDesc = fieldMap.get(fieldName).getDescribe();
         
         if (fieldDesc.getType() == Schema.DisplayType.Currency) {
             Map<String, String> fieldInfo = new Map<String, String>();
             fieldInfo.put('apiName', fieldName);
             fieldInfo.put('label', fieldDesc.getLabel());
             currencyFields.add(fieldInfo);
         }
     }
     return currencyFields;
 }

 @AuraEnabled(cacheable=true)
 public static List<Expense__c> getExpenses(Id workOrderId) {
     try {
         // Ensure workOrderId is not null
         if (workOrderId == null) {
             throw new AuraHandledException('Work Order ID cannot be null');
         }

         // Use the correct lookup field name
         return [SELECT Id,Name, Title__c, Quantity__c, Unit_Price__c, Net_price__c ,active__c
                 FROM Expense__c 
                 WHERE Work_Order__c = :workOrderId AND active__c =:'true']; // Use WorkOrderId if it's a standard lookup

     } catch (Exception e) {
         System.debug('Error fetching expenses: ' + e.getMessage());
         throw new AuraHandledException('Failed to fetch expenses. Please contact support.');
     }
 }




 @AuraEnabled(cacheable=true)
 public static String updateExpenses(List<Id> expensesList) {
     try {
         if (expensesList == null || expensesList.isEmpty()) {
             return 'No Expenses to update.';
         }
 
         // Query all Expense records to update
         List<Expense__c> expensesToUpdate = [SELECT Id, active__c FROM Expense__c WHERE Id IN :expensesList];
         system.debug('expensesToUpdate'+expensesToUpdate.size());
         List<Expense__c> updateExpense = New List<Expense__c>();

 
         for (Expense__c exp : expensesToUpdate) {
             exp.active__c = 'false'; 
             updateExpense.add(exp);
         }
         system.debug('updateExpense'+updateExpense.size());

         // Perform a single DML update for all the expenses
         update updateExpense;
 
         return 'Expenses updated successfully.';
     } catch (Exception e) {
         System.debug('Error: ' + e.getMessage());
         throw new AuraHandledException('Error updating expenses: ' + e.getMessage());
     }
 }
 public static String testingbug1(Set<Id> expensesList) {
     try {
         if (expensesList == null || expensesList.isEmpty()) {
             return 'No Expenses to update.';
         }
 
         // Query all Expense records to update
         List<Expense__c> expensesToUpdate = [SELECT Id, active__c FROM Expense__c WHERE Id IN :expensesList];
         system.debug('expensesToUpdate'+expensesToUpdate.size());
         List<Expense__c> updateExpense = New List<Expense__c>();

 
         for (Expense__c exp : expensesToUpdate) {
             exp.active__c = 'false'; 
             updateExpense.add(exp);
         }
         system.debug('updateExpense'+updateExpense.size());

         // Perform a single DML update for all the expenses
         update updateExpense;
 
         return 'Expenses updated successfully.';
     } catch (Exception e) {
         System.debug('Error: ' + e.getMessage());
         throw new AuraHandledException('Error updating expenses: ' + e.getMessage());
     }
 }
 

 
 @AuraEnabled(cacheable=true)
 public static Map<String, String> getTradeAndVendorId(Id workorderId) {
     try {
         // Ensure workorderId is not null
         if (workorderId == null) {
             throw new AuraHandledException('Work Order ID cannot be null');
         }
 
         // Query using correct Id field
         Work_Order__c workorder = [
             SELECT Id, Trade__c, Vendor__c 
             FROM Work_Order__c 
             WHERE Id = :workorderId
             LIMIT 1
         ];
 
         // Initialize the map
         Map<String, String> mapTradeAndVendorId = new Map<String, String>();
         mapTradeAndVendorId.put('vendorId', workorder.Vendor__c);
         mapTradeAndVendorId.put('tradeId', workorder.Trade__c);
 
         return mapTradeAndVendorId;
 
     } catch (Exception e) {
         System.debug('Error fetching trade/vendor: ' + e.getMessage());
         throw new AuraHandledException('Failed to fetch trade and vendor. Please contact support.');
     }
 }

 @AuraEnabled(cacheable=true)
 public static List<Invoice__c> getInvoices(Id workOrderId) {
     return [
         SELECT Id, Name, Estimate__c, grandTotal__c, netTotal__c, Status__c, totalDiscount__c 
         FROM Invoice__c
         WHERE Work_Orders__c = :workOrderId
         ORDER BY CreatedDate DESC
     ];
 }

 @AuraEnabled(cacheable=true)
public static List<Vendor_Trade_Rate_Management__c> getVTRMRecords(Id tradeId, Id vendorId) {
    try {
        if (tradeId == null || vendorId == null) {
            throw new AuraHandledException('Trade ID and Vendor ID are required');
        }

        List<Vendor_Trade_Rate_Management__c> vtrmRecords = [
            SELECT Id, Name, Status__c,	After_Hours_Rate__c,Emergency_Rate__c,Holiday_Rate__c,Regular_Rate__c,Weekend_Emergency_Rate__c,Weekend_Rate__c // Add your required fields here
            FROM Vendor_Trade_Rate_Management__c
            WHERE Trade__c = :tradeId AND Vendor__c = :vendorId AND Status__c='Approved'
        ];

        return vtrmRecords;

    } catch (Exception e) {
        System.debug('Error fetching VTRM records: ' + e.getMessage());
        throw new AuraHandledException('Failed to fetch VTRM records. Please contact support.');
    }
}

@AuraEnabled(cacheable=true)
public static List<Estimate__c> getEstimates(Id workOrderId) {
    return [
        SELECT Id, Name ,Estimate_Data__c, Incurred_Data__c,netPrice__c, totalDiscount__c, grandTotal__c, Status__c,Formdata__c
        FROM Estimate__c
        WHERE Work_Orders__c = :workOrderId
        ORDER BY CreatedDate DESC
    ];
}

@AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getLatestPrices(Id passedestimateid) {
         // Return an empty list if workOrderId is null
          if (passedestimateid == null) {
            return new Map<String, Decimal>();
        }

        Estimate__c latestEstimate = [
            SELECT netPrice__c, grandTotal__c, totalDiscount__c , 	Proposal_For_Repairs__c , Assessment_Troubleshoot__c , 	Internal_Estimate_No__c
            FROM Estimate__c
            WHERE Id = :passedestimateid
        ];

        return new Map<String, Decimal>{
            'NetPrice' => latestEstimate.netPrice__c,
            'GrandTotal' => latestEstimate.grandTotal__c,
            'TotalDiscount' => latestEstimate.totalDiscount__c 
            , 
            // 'ProposalForRepairs' => latestEstimate.Proposal_For_Repairs__c,
            // 'AssessmentTroubleshoot' => latestEstimate.Assessment_Troubleshoot__c,
            'InternalEstimateNo' => latestEstimate.Internal_Estimate_No__c
        };
    }
@AuraEnabled(cacheable=true)
    public static Map<String, String> getconstanttext(Id passedestimateid) {
         // Return an empty list if workOrderId is null
          if (passedestimateid == null) {
            return new Map<String, String>();
        }

        Estimate__c latestEstimate = [
            SELECT netPrice__c, grandTotal__c, totalDiscount__c , 	Proposal_For_Repairs__c , Assessment_Troubleshoot__c , 	Internal_Estimate_No__c
            FROM Estimate__c
            WHERE Id = :passedestimateid
            
        ];

        return new Map<String, String>{
            'AssessmentTroubleshoot' => latestEstimate.Assessment_Troubleshoot__c,

            'ProposalForRepairs' => latestEstimate.Proposal_For_Repairs__c
        };
    }






    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getTripRatesfromvendor(Id vendorId) {
        // Query the Trip__c record related to the given WorkOrderId
        Vendor__c vendor = [
            SELECT 	Regular_Trip_Charge__c, Emergency_Trip_Charge__c
            FROM Vendor__c 
            WHERE Id = :vendorId
            LIMIT 1
        ];

        // Return the values in a map
        Map<String, Decimal> rates = new Map<String, Decimal>();
        rates.put('RegularTripPrice', vendor.Regular_Trip_Charge__c);
        rates.put('EmergencyTripRate', vendor.Emergency_Trip_Charge__c);

        return rates;
    }
    @AuraEnabled(cacheable=true)
    public static Object getLatestEstimateData(Id passedestimateid) {
        
        // Return an empty list if workOrderId is null
        if (passedestimateid == null) {
            return new List<Estimate__c>();
        }
        
        // Query the latest Estimate record related to the Work Order
        Estimate__c estimate = [
            SELECT Id, Estimate_Data__c
            FROM Estimate__c
            WHERE Id = :passedestimateid
        ];
        
        // Return the list (it could be empty or contain 1 record)
        return estimate.Estimate_Data__c;
    }
    @AuraEnabled
    public static void deactivateExpenses(List<Id> expenseIds) {
        if (expenseIds == null || expenseIds.isEmpty()) return;

        List<Expense__c> expensesToUpdate = [
            SELECT Id, active__c
            FROM Expense__c
            WHERE Id IN :expenseIds
        ];

        for (Expense__c exp : expensesToUpdate) {
            exp.active__c = 'false'; // Set to picklist value 'False'
        }

        update expensesToUpdate;
    }
    @AuraEnabled
    public static void updateWorkOrder(Id workOrderId, String assessmentTroubleshoot, String proposalForRepairs, Integer internalEstimateNo) {
        if (String.isBlank(workOrderId)) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        Work_Order__c workOrder = [SELECT Id, AssessmentTroubleshoot__c, Proposal_For_Repairs__c, Internal_Estimate_No__c 
                                   FROM Work_Order__c 
                                   WHERE Id = :workOrderId 
                                   LIMIT 1];

        workOrder.AssessmentTroubleshoot__c = assessmentTroubleshoot;
        workOrder.Proposal_For_Repairs__c = proposalForRepairs;
        workOrder.Internal_Estimate_No__c = internalEstimateNo;

        update workOrder;
    }

  @AuraEnabled(cacheable=true)
public static List<Estimate__c> getEstimatesBasedOnWorkOrder(Id workOrderId) {
    if (String.isBlank(workOrderId)) {
        throw new AuraHandledException('Work Order Id is required.');
    }

    // Get the current Work Order
    Work_Order__c workOrder = [
        SELECT Id, Work_Order_Type__c
        FROM Work_Order__c
        WHERE Id = :workOrderId
        LIMIT 1
    ];

    List<Estimate__c> estimates;

    // If it's an Order type, fetch estimates for all its child work orders
    if (workOrder.Work_Order_Type__c == 'Order') {
        estimates = [
            SELECT Id, Name, Work_Orders__c, Work_Orders__r.Name,
                   Vendor__c,
                   Status__c, netPrice__c, grandTotal__c, totalDiscount__c
            FROM Estimate__c
            WHERE Work_Orders__c IN (
                SELECT Id
                FROM Work_Order__c
                WHERE ParentWO__c = :workOrderId
            )
        ];
    } else {
        // Otherwise, just fetch estimates directly tied to this work order
        estimates = [
            SELECT Id, Name, Work_Orders__c, Work_Orders__r.Name,
                   Vendor__c,
                   Status__c, netPrice__c, grandTotal__c, totalDiscount__c
            FROM Estimate__c
            WHERE Work_Orders__c = :workOrderId
        ];
    }

    return estimates;
}


@AuraEnabled(cacheable=true)
public static String getEStimateStatus(Id estimateId){

    Estimate__c estimate = [
            SELECT 
                   Status__c
            FROM Estimate__c
            WHERE Id = :estimateId
        ];
    
        return estimate.Status__c;
}

@AuraEnabled
public static Id updateCurrentEstimate(String formData,  Decimal netPrice, Decimal grandTotal, Decimal totalDiscount , Integer internalnumber , String assesment  , String proposal , Id estimateId) {
    try {
        Estimate__c existingEstimate = [
            SELECT Id 
            FROM Estimate__c 
            WHERE Id = :estimateId
        ];

        existingEstimate.Estimate_Data__c = formData;
        existingEstimate.netPrice__c = netPrice;
        existingEstimate.grandTotal__c = grandTotal;
        existingEstimate.totalDiscount__c = totalDiscount;
        existingEstimate.Internal_Estimate_No__c = internalnumber;
        existingEstimate.Assessment_Troubleshoot__c = assesment;
        existingEstimate.Proposal_For_Repairs__c = proposal;


        update existingEstimate;

        return existingEstimate.Id;
    } catch (Exception e) {
        throw new AuraHandledException('Error updating Estimate: ' + e.getMessage());
    }
}





}