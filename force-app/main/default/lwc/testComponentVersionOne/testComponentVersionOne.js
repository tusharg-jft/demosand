import { LightningElement } from 'lwc';
import { currentFormData } from './estimateData'; // adjust this path as needed

export default class DynamicForm extends LightningElement {
    formData = currentFormData;

    // Computed structure for looping dynamically
    get formDataSections() {
        const sections = Object.keys(this.formData).map(typeKey => {
            console.log('Type:', typeKey); // Logs "Estimate", "Incurred"
            console.log('Sections:', this.formData[typeKey]); // Logs array of section objects

            return {
                type: typeKey,
                sections: this.formData[typeKey]
            };
        });

        console.log('Full Form Data Sections:', JSON.stringify(sections, null, 2));
        return sections;
    }

    connectedCallback() {
        // Log raw data on component init
        console.log('Raw currentFormData:', JSON.stringify(this.formData, null, 2));
    }
}