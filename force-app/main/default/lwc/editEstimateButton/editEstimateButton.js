import { api, LightningElement } from 'lwc';

export default class EstimateModalButton extends LightningElement {
  showModal = false;

  
  @api recordId;

  


  handleOpenModal() {
    this.showModal = true;
    console.log("clicked")
    console.log("edit estimste", this.recordId)

  }

  // Close Modal
  handleCloseModal() {
    this.showModal = false;
  }


}