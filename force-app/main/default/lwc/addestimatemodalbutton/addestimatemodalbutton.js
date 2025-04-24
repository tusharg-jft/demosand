import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EstimateModalButton extends LightningElement {
  showModal = false;

  @api recordId;
  showModal = false;

  connectedCallback() {
    console.log('Record Id:', this.recordId);
  }

  // Open Modal
  handleOpenModal() {
    this.showModal = true;
    console.log("record id testing",this.recordId)
  }

  // Close Modal
  handleCloseModal() {
    this.showModal = false;
  }

  // Save Estimate
  handleSave() {
    this.showModal = false;
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: 'Estimate saved successfully!',
        variant: 'success',
      })
    );
  }
}