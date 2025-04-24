import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class EstimateModalButton extends LightningElement {
  showModal = false;
  @api recordId;

  


  handleOpenModal() {
    this.showModal = true;
    console.log("estimate modal button" ,this.recordId)
    console.log("clicked")

  }

  // Close Modal
  handleCloseModal() {
    this.showModal = false;
  }


}