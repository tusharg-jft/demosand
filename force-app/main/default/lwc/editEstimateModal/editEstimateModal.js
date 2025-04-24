import createEstimateRecord from '@salesforce/apex/EstimateController.createEstimateRecord';
import getEstimateModalInfo from '@salesforce/apex/EstimateModalInfo.getEstimateModalInfo';
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateExpenses from '@salesforce/apex/EstimateController.updateExpenses';

export default class EstimateModal extends LightningElement {
  @api rec;
  @track workOrderData = {};
  @track vendorData = {};
  @track siteData = {};
  @track isEstimate =false;
  @track isIncurred =false;
  @track discountOptions = [
    { label: 'Flat Rate', value: 'Flat Rate' },
    { label: 'Percentage', value: 'Percentage' },

];




netTotal = '$0.00';
totalDiscount = '$0.00';
taxAmount = '$0.00';
grandTotal = '$0.00';

@track AssementValue='';
@track ProposalValue='';



  connectedCallback() {
    document.documentElement.classList.add('modal-open'); // Apply to HTML
    document.body.classList.add('modal-open'); // Apply to Body
    // console.log("Record ID:", this.rec);

    getEstimateModalInfo({ workorderid: this.rec })
      .then(result => {
        if (result) {
          // console.log('Result from Apex:', result);

          this.workOrderData = result.wo;
          this.vendorData = result.vendoruser || {}; 
          this.siteData = result.siteuser || {};

          // Log Vendor Name if available
          if (this.vendorData) {
            // console.log('Vendor:', this.vendorData);
          const  vendorAddress = this.vendorData.Address__c;
            // console.log(vendorAddress) 
          } 
          if (this.workOrderData) {
            // console.log('Wo:', this.workOrderData);
          } 
          if (this.siteData) {
            // console.log('site:', this.siteData);
          } 
        } else {
          // console.error('No data returned from Apex');
        }
      })
      .catch(error => {
        // console.error('Error fetching data:', error);
      });
  }


  handleClose() {
    const closeEvent = new CustomEvent('close');
    this.dispatchEvent(closeEvent);
  }

  
  handleSaveClick() {
console.log("clicked saved")

    let expenseIdList = []; // List to store all extracted Id values


    const EStimateCmp = this.template.querySelector('c-edit-estimate-section ');
    const IncurredCmp = this.template.querySelector('c-edit-incurred-section ');
    if (EStimateCmp && IncurredCmp ) {
        const EStimatedata = EStimateCmp.getEstimateFormData();
        const Incurreddata = IncurredCmp.getIncurredFormData();
        // console.log('Estimate Form Data:', JSON.stringify(data, null, 2));
    const formattedData = {
            Estimate: EStimatedata.Estimate.map(section => ({
                Label: section.Label,
                Fields: section.Fields.map(fieldRow => 
                    fieldRow.map(field => ({
                        fieldLabel: field.fieldLabel,
                        value: field.value
                    }))
                )
            }))
            ,
            Incurred: Incurreddata.Incurred.map(section => ({
                Label: section.Label,
                Fields: section.Fields.map(fieldRow => 
                    fieldRow.map(field => ({
                        fieldLabel: field.fieldLabel,
                        value: field.value
                    }))
                )
            }))
            ,
            Assessment:this.AssementValue
            ,
            Proposal:this.ProposalValue
            
        };
        const setofid = new Set([]);
    formattedData.Incurred.forEach(section => {
        section.Fields.forEach(fieldGroup => {
            fieldGroup.forEach(field => {
                if (field.fieldLabel === "Id" && field.value) {
                  setofid.add(field.value)
                    expenseIdList.push(field.value);
                }
            });
        });
    });
    // console.log("List ",expenseIdList)
    // console.log("Set of Id",setofid)
    
    // console.log('jsi shree ram:', JSON.stringify(formattedData, null, 2));



      createEstimateRecord({ formData: JSON.stringify(formattedData), workOrderId: this.rec })
               .then((rec) => {
                   // console.log('Estimate created successfully, record ID:', rec);
                   this.dispatchEvent(new ShowToastEvent({
                       title: 'Success',
                       message: `Estimate created successfully!`,
                       variant: 'success',
                   }));
                  
               })
               .catch((error) => {
                   console.error('Error creating estimate:', error);
                   this.dispatchEvent(new ShowToastEvent({
                       title: 'Error',
                       message: error.body ? error.body.message : error.message,
                       variant: 'error',
                   }));
               });
    } else {
        console.warn('Child component not found');
    }
}


  handleDiscountChange(event) {
    // console.log('Selected Discount:', event.detail.value);
}

handleAssessment(event) {
  const inputValue = event.target.value;
   const aa = this.removeHTMLTags(inputValue);
   
  console.log('Assessment Value (Cleaned):', aa);
}

// Function to handle the 'Proposal For Repairs' input change
handleProposal(event) {
  const inputValue = event.target.value;
   const bb = this.removeHTMLTags(inputValue);
  console.log('Proposal Value (Cleaned):', bb);
}




}