/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class InvoiceController {
    public Invoice__c invoice {get; private set;}
    public List<Labor__c> incurredLabor {get; private set;}
    public List<Labor__c> invoiceLabor {get; private set;}
    
    public InvoiceController(ApexPages.StandardController stdController) {
        this.invoice = [SELECT Id, Name,  Status__c,
                                Total_Discount__c, Tax_Amount__c,
                                 Net_Total1__c, 
                                Proposal_For_Repairs__c, Work_Orders__r.Trade__r.Name, 
                                Work_Orders__r.Classification__r.Name, 
                                Work_Orders__r.Issue__r.Name,
                                Work_Orders__r.WorkOrderNumber__c
                         FROM Invoice__c
                         WHERE Id = :stdController.getId()];

        // Fetch related Labor records based on Type and Record Type
        incurredLabor = [SELECT Quantity__c, Technician_Quantity__c, Details__c, Unit_Price__c, Net_Price__c 
                         FROM Labor__c 
                         WHERE Invoices__c = :invoice.Id AND Type__c = 'Incurred for Invoice'];

        invoiceLabor = [SELECT Quantity__c, Technician_Quantity__c, Details__c, Unit_Price__c, Net_Price__c 
                         FROM Labor__c 
                         WHERE Invoices__c = :invoice.Id AND Type__c = 'Invoice'];
    }
    
    // Method to save the rendered PDF as an attachment.
    public PageReference saveAsPDF() {
        try {
            // Generate the PDF content
            PageReference pdfPage = Page.Invoice;
            pdfPage.getParameters().put('id', invoice.Id);
            Blob pdfContent = pdfPage.getContentAsPDF();
            
            // Unique file name
            String uniqueFileName = invoice.Name + '_Invoice_' + Datetime.now().format('yyyyMMddHHmmss') + '.pdf';
            
            // Create a new ContentVersion
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = uniqueFileName;
            contentVersion.PathOnClient = uniqueFileName;
            contentVersion.VersionData = pdfContent; 
            insert contentVersion;
            
            // Fetch the ContentDocumentId for the new ContentVersion
            ContentDocument contentDocument = [
                SELECT Id
                FROM ContentDocument
                WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id)
            ];
            
            // Check for existing ContentDocumentLink
            List<ContentDocumentLink> existingLinks = [
                SELECT Id 
                FROM ContentDocumentLink 
                WHERE ContentDocumentId = :contentDocument.Id 
                AND LinkedEntityId = :invoice.Id
            ];

            if (existingLinks.isEmpty()) {
                // Create a new ContentDocumentLink
                ContentDocumentLink newLink = new ContentDocumentLink();
                newLink.ContentDocumentId = contentDocument.Id;
                newLink.LinkedEntityId = invoice.Id; // Link to the Invoice__c record
                newLink.ShareType = 'V'; // Viewer access
                newLink.Visibility = 'AllUsers';
                insert newLink;
            }

            // Add a success message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'PDF saved successfully as ' + uniqueFileName + '!'));

        } catch (Exception e) {
            // Add an error message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error saving PDF: ' + e.getMessage()));
        }
        return null; 
    }


    ///// tushar code here 

    @AuraEnabled
    public static Id createInvoiceRecord(String formData, Id workOrderId,  Decimal netPrice, Decimal grandTotal, Decimal totalDiscount,  Integer internalnumber , String assesment  , String proposal) {
        if (String.isBlank(formData) || workOrderId == null) {
            throw new AuraHandledException('Form data and Work Order Id are required.');
        }
        if(grandTotal==0){
            grandTotal = netPrice;
        }
        
        try {
            Invoice__c newInvoice = new Invoice__c();
            newInvoice.Estimate_Data__c = formData;
            newInvoice.Work_Orders__c= workOrderId;
            newInvoice.netTotal__c = netPrice;
            newInvoice.grandTotal__c = grandTotal;
            newInvoice.totalDiscount__c = totalDiscount;
            newInvoice.Internal_Invoice_No__c = internalnumber;
            newInvoice.Assessment_Troubleshoot__c = assesment;
            newInvoice.Proposal_For_Repairs__c = proposal;
            insert newInvoice;

            return newInvoice.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating Estimate: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Object getLatestInvoicedData(Id invoiceId) {
        
        // Return an empty list if workOrderId is null
        if (invoiceId == null) {
            return new List<Invoice__c>();
        }
        
        // Query the latest Estimate record related to the Work Order
        Invoice__c invoice = [
            SELECT Id, 	Estimate_Data__c
            FROM Invoice__c
            WHERE Id = :invoiceId
            ORDER BY CreatedDate DESC
        ];
        
        // Return the list (it could be empty or contain 1 record)
        return invoice.Estimate_Data__c;
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, Decimal> getLatestInvoicePrices(Id invoiceId) {
         // Return an empty list if workOrderId is null
          if (invoiceId == null) {
            return new Map<String, Decimal>();
        }

        Invoice__c latestInvoice= [
            SELECT netTotal__c, grandTotal__c,totalDiscount__c, Internal_Estimate_No__c 
            FROM Invoice__c
            WHERE Id = :invoiceId
        ];

        return new Map<String, Decimal>{
            'NetPrice' => latestInvoice.netTotal__c,
            'GrandTotal' => latestInvoice.grandTotal__c,
            'TotalDiscount' => latestInvoice.totalDiscount__c,
            'InternalEstimateNo' => latestInvoice.Internal_Estimate_No__c
        };
    }
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getconstanttextinvoice(Id invoiceId) {
        // Return an empty list if workOrderId is null
         if (invoiceId == null) {
           return new Map<String, String>();
       }

       Invoice__c invoice = [
           SELECT Proposal_For_Repairs__c , Assessment_Troubleshoot__c 
           FROM Invoice__c
           WHERE Id = :invoiceId
       ];

       return new Map<String, String>{
           'AssessmentTroubleshoot' => invoice.Assessment_Troubleshoot__c,

           'ProposalForRepairs' => invoice.Proposal_For_Repairs__c
       };
   }
   
    @AuraEnabled(cacheable=true)
    public static List<InvoiceWrapper> getInvoicesBasedOnWorkOrder(Id workOrderId) {
        System.debug('🔍 Input Work Order ID: ' + workOrderId);

        if (String.isBlank(workOrderId)) {
            throw new AuraHandledException('Work Order Id is required.');
        }

        Work_Order__c currentWO = [
            SELECT Id, Work_Order_Type__c, ParentWO__c
            FROM Work_Order__c
            WHERE Id = :workOrderId
            LIMIT 1
        ];
        System.debug('📌 Current Work Order: ' + currentWO);

        List<Work_Order__c> targetWOs;

        if (currentWO.Work_Order_Type__c == 'Child') {
            System.debug('🔁 Work Order is a Child. Fetching invoices under this Work Order only.');
            targetWOs = [SELECT Id FROM Work_Order__c WHERE Id = :currentWO.Id];
        } else if (currentWO.Work_Order_Type__c == 'Order' && currentWO.Id != null) {
            System.debug('🔁 Work Order is an Order. Fetching all Child Work Orders with this as parent.');
            targetWOs = [
                SELECT Id
                FROM Work_Order__c
                WHERE ParentWO__c = :currentWO.Id
            ];
        } else {
            System.debug('⚠️ Unknown Work Order type. Returning empty.');
            return new List<InvoiceWrapper>();
        }

        List<Id> targetWOIds = new List<Id>();
        for (Work_Order__c wo : targetWOs) {
            targetWOIds.add(wo.Id);
        }

        System.debug('📋 Work Order IDs for Invoice search: ' + targetWOIds);

        List<Invoice__c> invoiceList = [
            SELECT Id, Name, Work_Orders__c, Work_Orders__r.Name,
                   Work_Orders__r.Vendor__r.Name,
                   Status__c, netTotal__c, totalDiscount__c, grandTotal__c
            FROM Invoice__c
            WHERE Work_Orders__c IN :targetWOIds
        ];

        System.debug('🧾 Retrieved Invoices: ' + invoiceList);

        List<InvoiceWrapper> wrappedList = new List<InvoiceWrapper>();
        for (Invoice__c inv : invoiceList) {
            String vendorName = inv.Work_Orders__r.Vendor__r != null ? inv.Work_Orders__r.Vendor__r.Name : '';
            wrappedList.add(new InvoiceWrapper(
                inv.Id,
                inv.Name,
                inv.Work_Orders__r.Name,
                vendorName,
                inv.Status__c,
                inv.netTotal__c,
                inv.totalDiscount__c,
                inv.grandTotal__c,
                inv.Work_Orders__c
            ));
        }

        System.debug('✅ Final wrapped invoice data: ' + wrappedList);
        return wrappedList;
    }

    public class InvoiceWrapper {
        @AuraEnabled public Id invoiceId;
        @AuraEnabled public String name;
        @AuraEnabled public String workOrderName;
        @AuraEnabled public String vendorName;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal netTotal;
        @AuraEnabled public Decimal totalDiscount;
        @AuraEnabled public Decimal grandTotal;
        @AuraEnabled public Id workOrderId;

        public InvoiceWrapper(
            Id invoiceId,
            String name,
            String workOrderName,
            String vendorName,
            String status,
            Decimal netTotal,
            Decimal totalDiscount,
            Decimal grandTotal,
            Id workOrderId
        ) {
            this.invoiceId = invoiceId;
            this.name = name;
            this.workOrderName = workOrderName;
            this.vendorName = vendorName;
            this.status = status;
            this.netTotal = netTotal;
            this.totalDiscount = totalDiscount;
            this.grandTotal = grandTotal;
            this.workOrderId = workOrderId;
        }
    }


  



   



}