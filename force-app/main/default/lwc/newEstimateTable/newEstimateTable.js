import { LightningElement, track, wire, api } from 'lwc';
/** Display toast message */
import { ShowToastEvent } from 'lightning/platformShowToastEvent'
import { refreshApex } from '@salesforce/apex';
import createInvoiceFromEstimate from '@salesforce/apex/InvoiceApprovalController.createInvoiceFromEstimate';
import submitForApproval from '@salesforce/apex/EstimateApprovalController.submitForApproval';
import { NavigationMixin } from 'lightning/navigation';
import getEstimates  from '@salesforce/apex/EstimateController.getEstimates';
/** Custom Label: An error occurred while retrieving contacts. */
// import ERROR_GETCONTACTS from '@salesforce/label/c.ErrMsg_GetContacts'
/** Get items for creating new contact */
import FIELD_NAME from '@salesforce/schema/Estimate__c.Name';
import FIELD_STATUS from '@salesforce/schema/Estimate__c.Status__c';


  
export default class TestContactList extends LightningElement {

    // Record ID displayed on screen
    @api recordId;
    // Contact list header
    // @track columns =  [
    //     {label:'EStimate name', fieldName:'Name' }
    //     ,{label:'Status', fieldName:'Status__c'},
  
 
       
    // ];
    estimateid;
    
    // Handler for estimate changed event
    handleEstimateChanged() {
        console.log("handle estimate change call")
        // Refresh the estimate data
        refreshApex(this.resultEstimate);
    }
    
    connectedCallback() {
        // Add event listener for the estimatechanged event
        this.template.addEventListener('estimatechanged', this.handleEstimateChanged.bind(this));
    }
    
    disconnectedCallback() {
        // Remove event listener when component is destroyed
        this.template.removeEventListener('estimatechanged', this.handleEstimateChanged.bind(this));
    }
    
    // Contact acquisition results
    resultEstimate = [];
    // Contact list data
    @track estimateList = [];
    // New creation modal dialog display flag
    @track isShowModal = false;
    // New dialog display items
    createFields = [FIELD_NAME, FIELD_STATUS];
    // @track columns = [
    //     { label: 'Estimate id', fieldName: 'Id', type: 'text' },
    //     { label: 'Estimate Name', fieldName: 'Name', type: 'text' },
    //     { label: 'Status', fieldName: 'Status__c', type: 'text' },
    //     { label: 'Net Total', fieldName: 'netPrice__c', type: 'currency' },
    //     { label: 'Total Discount', fieldName: 'totalDiscount__c', type: 'currency' },
    //     { label: 'Grand Total', fieldName: 'grandTotal__c', type: 'currency' },
    //     {
    //         label: 'Submit for Approval',
    //         type: 'submitApprovalButton',
    //         typeAttributes: {
    //             row: { fieldName: 'Id' }
    //         }
    //     },
    //     {
    //         label: 'Edit Estimate',
    //         type: 'editEstimateButton',
    //         typeAttributes: {
    //             row: { fieldName: 'Id' }
    //         }
    //     }
    // ];
    
    
    @track showEditButton = false;
    @track selectedRecordId;
    /**
     * Get Contact
     * 
     */

show=false;
Newshow=false;

showedit=false;
status;
netTotal;
grandTotal
totalDicount;


@wire(getEstimates, { workOrderId: '$recordId' })
// setEstimateList(result) {
//     try {
//         this.resultEstimate = result;
//         console.log("result", result);

//         if (result?.data && Array.isArray(result.data) && result.data.length > 0) {
//             // Add row numbers to each estimate
//             this.estimateList = result.data.map((estimate, index) => {
//                 return {
//                     ...estimate,
//                     rowNumber: index + 1 ,// Add row number starting from 1
//                     isApproved: estimate.Status__c === 'Approved', // ✅ Add this
//                     isPending:estimate.Status__c === 'Pending',
//                     isSubmittedforapproval:estimate.Status__c === 'Submitted_For_Approval'
//                 };
//             });

//             const firstEstimate = result.data[0];
//             if (firstEstimate) {
//                 this.estimateid = firstEstimate.Id;
//                 this.status = firstEstimate.Status__c;
//                 this.netTotal = firstEstimate.netPrice__c;
//                 this.grandTotal = firstEstimate.grandTotal__c;
//                 this.totalDicount = firstEstimate.totalDicount__c;

//                 this.showButton(); // Only show if data exists
//                 console.log("Estimate ID:", this.estimateid);
//             }
//         } else {
//             // No data scenario
//             console.log("No estimate data returned.");
//             this.estimateList = [];
//             this.estimateid = null;
//             this.status = null;
//             this.netTotal = null;
//             this.grandTotal = null;
//             this.totalDicount = null;
//         }

//     } catch (error) {
//         console.error("Error in setEstimateList:", error);
//         this.showToast(
//             'Error Getting Estimates',
//             error?.message || 'Unknown error occurred while loading estimates',
//             'error',
//             'sticky'
//         );
//     }
// }

setEstimateList(result) {
    try {
        this.resultEstimate = result;
        console.log("result", result);

        if (result?.data && Array.isArray(result.data) && result.data.length > 0) {
            // Add row numbers and flags to each estimate
            this.estimateList = result.data.map((estimate, index) => {
                return {
                    ...estimate,
                    rowNumber: index + 1, // Start row numbers from 1
                    isApproved: estimate.Status__c === 'Approved',
                    isPending: estimate.Status__c === 'Pending',
                    isInovoiced: estimate.Status__c === 'Invoiced',
                    isRejected: estimate.Status__c === 'Rejected',
                    isDraft: estimate.Status__c === 'Draft',
                    
                    isSubmitedForApproval: estimate.Status__c === 'Submited_For_Approval' || 'Submited for Approval',
                    estimateStatus: estimate.Status__c === 'Submited_For_Approval' ? 'Submited For Approval' : estimate.Status__c,


                     };
            });

            const firstEstimate = result.data[0];
            if (firstEstimate && firstEstimate.Id) {
                this.estimateid = firstEstimate.Id;
                this.status = firstEstimate.Status__c;
                this.netTotal = firstEstimate.netPrice__c;
                this.grandTotal = firstEstimate.grandTotal__c;
                this.totalDiscount = firstEstimate.totalDiscount__c;

                this.showButton();
                console.log("Estimate ID:", this.estimateid);
            }
        } else {
            console.log("No estimate data returned.");
            this.estimateList = [];
            this.estimateid = null;
            this.status = null;
            this.netTotal = null;
            this.grandTotal = null;
            this.totalDiscount = null;
        }

    } catch (error) {
        console.error("Error in setEstimateList:", error);
        this.showToast(
            'Error Getting Estimates',
            error?.message || 'Unknown error occurred while loading estimates',
            'error',
            'sticky'
        );
    }
}


@track isModalOpen = false;
@track vfPageUrl;

// Make sure to set your base VF URL here
VF_BASE_URL = '/apex/EstimatePDFPage?id=';

openModal(event) {
    const estimateId = event.target.dataset.id;
    this.vfPageUrl = this.VF_BASE_URL + this.estimateId;
    this.isModalOpen = true;
}

closeModal() {
    this.isModalOpen = false;
}


        get Estimateid(){
          console.log(this.estimateid);
          return this.estimateid;
        }

showIframe=false;

        showPdf() {
          this.vfPageUrl = '/apex/EStimatePDFPage?id=' + this.estimateid;
          this.showIframe = true;
          
      }
      //vfPageUrl = '/apex/EStimatePDFPage?id=' + this.estimateid;
     // vfPageUrl = 'https://sandbox12-dev-ed--c.visualforce.com/https://sandbox12-dev-ed--c.develop.vf.force.com/apex/EstimatePDFPage?id='+this.estimateid;


      isModalOpen=false; 
      openModal() {

        this.isModalOpen = true;
        this.showPdf();
      }

    closeModal() {
        this.isModalOpen = false;
    }



    get shoVF(){

        if( this.status=='Approved'|| this.status=='Canceled'|| this.status=='Submited_For_Approval'|| this.status=='Rejected'|| this.status=='Pending' ){
          return true;
        }
        else{
          return false;
      }
      }
showButton(){




  if( this.status == 'Pending' || 
    this.status== 'Rejected'  ){
    this.show = true;
    this.showedit=true
  }

  if(this.status=='Approved' ){
    this.Newshow = true;
    
    
  }
  
}


  handleSubmitInvoiceApproval(event) {
  
    console.log('Submitthis.estimateid = this.estimates.data[0].Id;ting Estimate Id:', this.estimateid); 
    const rowId = event.target.dataset.id;
    console.log("testing hello " , rowId)
    createInvoiceFromEstimate({ estimateId: rowId })
        .then(invoiceId => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'Invoice created successfully',
                    variant: 'success'
                })
            );

            // Navigate to the newly created invoice record
          

        })
        .catch(error => {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body ? error.body.message : error.message,
                    variant: 'error'
                })
            );
        });
}

        handleSubmitApproval(event){
          console.log(this.estimateid);




          submitForApproval({ estimateId: this.estimateid })
          .then(result => {
              console.log('Apex Response:', result);
              this.dispatchEvent(new ShowToastEvent({
                  title: 'Submitted',
                  message: result,
                  variant: 'success'
              }));

              this.handleEstimateChanged()

          })
          .catch(error => {
              console.error('Error submitting for approval', error);
              this.dispatchEvent(new ShowToastEvent({
                  title: 'Error',
                  message: error.body?.message || 'Unexpected error',
                  variant: 'error'
              }));
          })
          .finally(() => {
              this.isSubmitting = false;
          });
        }

        // Handle row selection in the custom table
        handleRowSelection(event) {
            // Prevent the event from bubbling up to parent elements
            event.stopPropagation();
            
            // Get the selected row's ID
            const selectedId = event.currentTarget.dataset.id;
            
            // Update the selected record ID
            this.selectedRecordId = selectedId;
            
            // Apply selected class to the clicked row and remove from others
            const allRows = this.template.querySelectorAll('tr.slds-hint-parent');
            if (allRows) {
                allRows.forEach(row => {
                    if (row.dataset.id === selectedId) {
                        row.classList.add('selected');
                    } else {
                        row.classList.remove('selected');
                    }
                });
            }
            
            // Find the selected estimate in the data
            const selectedEstimate = this.estimateList.find(estimate => estimate.Id === selectedId);
            
            if (selectedEstimate) {
                // Update the component state with the selected estimate's data
                this.estimateid = selectedEstimate.Id;
                this.status = selectedEstimate.Status__c;
                this.netTotal = selectedEstimate.netPrice__c;
                this.grandTotal = selectedEstimate.grandTotal__c;
                this.totalDicount = selectedEstimate.totalDiscount__c;
                
                // Update button visibility based on the selected estimate's status
                this.showButton();
                // console.log("Selected Estimate ID:", this.estimateid);
            }
        }
        
        // Handle row actions (buttons in the custom table)
        handleRowAction(event) {
            // Get the action and row ID from the clicked button
            const actionName = event.target.dataset.action;
            const rowId = event.target.dataset.id;
            
            // Find the row data for the clicked row
            const row = this.estimateList.find(estimate => estimate.Id === rowId);
            
            if (actionName === 'edit') {
                console.log('Edit clicked for row:', JSON.stringify(row));
                // Set the selected estimate for editing
                this.estimateid = rowId;
                // Additional edit functionality can be added here
            } else if (actionName === 'submitApproval') {
                console.log('Submit For Approval clicked for row:', JSON.stringify(row));
                // Set the selected estimate for approval submission
                this.estimateid = rowId;
                // Call the submit approval method
                this.handleSubmitApproval();
            }
        }
        
        // Helper method to show toast notifications
        showToast(title, message, variant, mode) {
            const event = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant || 'info', // info, success, warning, error
                mode: mode || 'dismissable' // dismissable, pester, sticky
            });
            this.dispatchEvent(event);
        }

//         handleMenuAction(event) {
//     const action = event.target.value;
//     const estimateId = event.target.dataset.id;

//     switch (action) {
//         case 'edit':
//             // Example: Navigate to edit or trigger custom logic
//             this.template.querySelector(`c-add-edit-button-version-one[data-id="${estimateId}"]`)?.click();
//             break;

//         case 'submitApproval':
//             this.handleRowAction({ target: { dataset: { id: estimateId, action: 'submitApproval' } } });
//             break;

//         case 'createInvoice':
//             this.handleSubmitInvoiceApproval({ target: { dataset: { id: estimateId } } });
//             break;

//         default:
//             console.warn("Unknown menu action:", action);
//     }
// }

          
}