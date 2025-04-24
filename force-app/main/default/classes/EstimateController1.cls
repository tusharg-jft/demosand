/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 03-03-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class EstimateController1 {
    public Estimate__c estimate { get; private set; }
    public List<Labor__c> incurredLabor { get; private set; }
    public List<Labor__c> estimateLabor { get; private set; }

    public EstimateController1(ApexPages.StandardController stdController) {
        this.estimate = [SELECT Id, Name, Status__c,  
                             Tax_Amount__c, Grand_Total_amount__c,
                                 Proposal_For_Repairs__c,
                                Work_Orders__r.Trade__r.Name, 
                                Work_Orders__r.Classification__r.Name, 
                                Work_Orders__r.Issue__r.Name,
                                Work_Orders__r.WorkOrderNumber__c
                         FROM Estimate__c
                         WHERE Id = :stdController.getId()];

        // Fetch related Labor records based on Type and Record Type
        incurredLabor = [SELECT Quantity__c, Technician_Quantity__c, Details__c, Unit_Price__c, Net_Price__c 
                         FROM Labor__c 
                         WHERE Estimates__c = :estimate.Id AND Type__c = 'Incurred for Estimate'];

        estimateLabor = [SELECT Quantity__c, Technician_Quantity__c, Details__c, Unit_Price__c, Net_Price__c 
                         FROM Labor__c 
                         WHERE Estimates__c = :estimate.Id AND Type__c = 'Estimate'];
    }
    
    // Method to save the rendered PDF as an attachment.
    public PageReference saveAsPDF() {
    try {
        // Generate the PDF content
        PageReference pdfPage = Page.Estimate1;
        pdfPage.getParameters().put('id', estimate.Id);
        Blob pdfContent = pdfPage.getContentAsPDF();

        //unique file name
        String uniqueFileName = estimate.Name + '_Estimate_' + Datetime.now().format('yyyyMMddHHmmss') + '.pdf';

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

      
        List<ContentDocumentLink> existingLinks = [
            SELECT Id 
            FROM ContentDocumentLink 
            WHERE ContentDocumentId = :contentDocument.Id 
            AND LinkedEntityId = :estimate.Id
        ];

        if (existingLinks.isEmpty()) {
            ContentDocumentLink newLink = new ContentDocumentLink();
            newLink.ContentDocumentId = contentDocument.Id;
            newLink.LinkedEntityId = estimate.Id; // Link to the Estimate__c record
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



     /*   try{
            // Generate the PDF content
            PageReference pdfPage = Page.Estimate1;
            pdfPage.getParameters().put('id', estimate.Id);
            Blob pdfContent = pdfPage.getContentAsPDF();
            
            //Create an Attachement
            Attachment attachment = new Attachment();
            Attachment.ParentId = estimate.Id;
            Attachment.Name = estimate.Name + '_Estimate.pdf';
            Attachment.body = pdfContent;
            Attachment.ContentType = 'application/pdf';
            
            //save the attachemnt 
            insert attachment;
            
            //return a success message
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'PDF saved successfully!'));
        }
        catch(Exception e){
            ApexPages.addMessage(new Apexpages.message(ApexPages.Severity.ERROR, 'Error saving PDF:' + e.getmessage()));
        }
        return ApexPages.currentPage(); // Stay on the same page
        }*/
    }