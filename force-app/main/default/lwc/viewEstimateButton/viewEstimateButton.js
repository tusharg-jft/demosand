import { LightningElement, api } from 'lwc';

export default class ParentComponent extends LightningElement {
    @api recordId;
    isModalOpen = false;

    get vfUrl() {
        return `/apex/ViewEstimate?id=${this.recordId}`;
    }
    handleOpenModal() {
        this.isModalOpen = true;
    }

    handleCloseModal() {
        this.isModalOpen = false;
    }
}