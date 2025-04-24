import { LightningElement, api, wire } from 'lwc';
import getInvoices from '@salesforce/apex/EstimateController.getInvoices';
import submitInvoiceForApproval from'@salesforce/apex/InvoiceApprovalController.submitInvoiceForApproval'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class InvoiceTable extends LightningElement {
  @api recordId;
statu;
invoiceId;
  columns = [
    {
      label: 'Invoice Name',
      fieldName: 'recordLink',
      type: 'url',
      typeAttributes: { label: { fieldName: 'Name' }, target: '_blank' }
    },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Net Total', fieldName: 'netTotal__c', type: 'currency' },
    { label: 'Total Discount', fieldName: 'totalDiscount__c', type: 'currency' },
    { label: 'Grand Total', fieldName: 'grandTotal__c', type: 'currency' }
  ];

  invoices = { data: [], error: null };

  @wire(getInvoices, { workOrderId: '$recordId' })
wiredInvoices({ data, error }) {
    if (error) {
        this.invoices = { data: [], error };
        console.error('Error fetching invoices:', error);
        this.statu = null;
        this.invoiceId = null;
        return;
    }

    if (data && Array.isArray(data) && data.length > 0) {
        // Add row numbers and format data for the custom table
        const invoiceList = data.map((row, index) => ({
            ...row,
            recordLink: '/' + row.Id,
            rowNumber: index + 1, // Add row number starting from 1
            isPending: row.Status__c === 'Pending',
            isRejected: row.Status__c === 'Rejected',
            showviewinvoice: row.Status__c === 'Approved'|| row.Status__c === 'On Hold',
            isPaid: row.Status__c === 'Paid',
        }));

        this.invoices = {
            data: invoiceList,
            error: null
        };

        const firstInvoice = invoiceList[0];

        this.statu = firstInvoice?.Status__c || null;
        this.invoiceId = firstInvoice?.Id || null;
    } else {
        // No data
        this.invoices = {
            data: [],
            error: null
        };
        this.statu = null;
        this.invoiceId = null;
    }
}


isInvoiceModalOpen = false;
 invoicePdfUrl;

handleOpenInvoiceModal(event) {
    const invoiceId = event.currentTarget.dataset.id;
    this.invoicePdfUrl = `/apex/NewInvoicePDFPage?id=`+ this.invoiceId;
    this.isInvoiceModalOpen = true;
}

handleCloseModal() {
    this.isInvoiceModalOpen = false;
    this.invoicePdfUrl = null;
}


  // handleSubmitInvoiceApproval(event){
  //           console.log(this.invoiceId);
  
  
  
  
  //           submitInvoiceForApproval({ invoiceId: this.invoiceId })
  //           .then(result => {
  //               console.log('Apex Response:', result);
  //               this.dispatchEvent(new ShowToastEvent({
  //                   title: 'Submitted',
  //                   message: result,
  //                   variant: 'success'
  //               }));
  //           })
  //           .catch(error => {
  //               console.error('Error submitting for approval', error);
  //               this.dispatchEvent(new ShowToastEvent({
  //                   title: 'Error',
  //                   message: error.body?.message || 'Unexpected error',
  //                   variant: 'error'
  //               }));
  //           })
  //           .finally(() => {
  //               this.isSubmitting = false;
  //               console.log('After Apex Call');
  //               console.log('hi' +this.invoiceId) // Debug
  //           });
  //         }
  handleSubmitInvoiceApproval(event) {
    const invoiceId = event.currentTarget.dataset.id;
    console.log('Submitting Invoice:', invoiceId);
  
    
    ({ invoiceId })
      .then(result => {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Submitted',
          message: result,
          variant: 'success'
        }));
      })
      .catch(error => {
        console.error('Error submitting for approval', error);
        this.dispatchEvent(new ShowToastEvent({
          title: 'Error',
          message: error.body?.message || 'Unexpected error',
          variant: 'error'
        }));
      });
  }
  

          get show(){
            if(this.statu=='Pending' || 
              this.statu== 'Rejected'  ){
              return true;
          }
        else{
          return false;
        }}

get vis2(){

  if( this.statu=='Paid' ){
    return false;
  }
  else{
    return true;
}


}

get showEdit(){
  if(this.statu=='Pending' || this.statu=='Rejected'  ){
    return true;
  }else{
    return false;
  }
}



get shoVF(){

  if( this.statu=='Approved'|| this.statu=='Paid'|| this.statu=='On Hold'|| this.statu=='Rejected'|| this.statu=='Pending' ){
    return true;
  }
  else{
    return false;
}
}

showIframe=false;

        showPdf() {
          this.vfPageUrl = '/apex/NewInvoicePDFPage?id=' + this.invoiceId;
          this.showIframe = true;
        }


isModalOpen=false; 
openModal() {

  this.isModalOpen = true;
  this.showPdf();
}

closeModal() {
  this.isModalOpen = false;
}



  get visible() {
    
    if( this.statu=='Rejected'|| this.statu=='Pending' || this.statu=='On Hold' ){
      return true;
    }
    else{
      return false;
    }
  }

  // Handle row selection in the custom table
  handleRowSelection(event) {
    // Prevent the event from bubbling up to parent elements
    event.stopPropagation();
    
    // Get the selected row's ID
    const selectedId = event.currentTarget.dataset.id;
    
    // Update the selected invoice ID
    this.invoiceId = selectedId;
    
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
    
    // Find the selected invoice in the data
    const selectedInvoice = this.invoices.data.find(invoice => invoice.Id === selectedId);
    
    if (selectedInvoice) {
      // Update the component state with the selected invoice's data
      this.statu = selectedInvoice.Status__c;
      
      console.log("Selected Invoice ID:", this.invoiceId);
      console.log("Selected Invoice Status:", this.statu);
    }
  }
}