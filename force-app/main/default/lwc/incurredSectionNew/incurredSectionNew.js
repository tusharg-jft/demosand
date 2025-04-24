import { api, LightningElement, track } from 'lwc';
import {  currentFormData } from './incurredData'; // Ensure both are exported correctly
// import createEstimateRecord from '@salesforce/apex/EstimateController.createEstimateRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getCurrencyFields from '@salesforce/apex/EstimateController.getCurrencyFields';
import getExpenses from '@salesforce/apex/EstimateController.getExpenses';


export default class IncurredSection extends LightningElement {
  @api rec;
  // @api existingEstimateData; // Property to receive existing estimate data
  @track formData = {}; // Holds user input and merged data
  @track fieldValues = []; // Array to hold field values for the template
  @track netPriceValues = []; // Array to hold net price values for the template
  @track options=[];
  @track selectedPickListValue = ''; // Stores selected value
  @track expenseIdList =[]; // store the id of the expense that has to be deleted
    
  @api getIncurredFormData() {
    return this.formData;
  } 



  connectedCallback() {

    this.formData = JSON.parse(JSON.stringify(currentFormData));
    

    getCurrencyFields().then(data=>{
                  // console.log(data);
                      this.options = data.map((item)=>({
                        label: item.label,
                value: item.apiName
            }));
                }).catch(error=>{console.log(error)})
           
            



        getExpenses({ workOrderId: this.rec })
        .then(data => {
            console.log("Raw Expenses Data: ", data);
            if (data && data.length > 0) {
                this.mergeExpensesIntoMaterial(data);
            }
        })
        .catch(error => {
            console.error("Error fetching expenses:", error);
        });
    

}

  handleAddField(event) {
    const sectionLabel = event.target.dataset.label;
    const sectionIndex = this.formData.Incurred.findIndex(sec => sec.Label === sectionLabel);
    
    if (sectionIndex >= 0) {
      const section = this.formData.Incurred[sectionIndex];
      const newFieldRow = [];
      
      // Clone the field structure from the first row if available
      if (section.Fields.length > 0 && section.Fields[0].length > 0) {
        section.Fields[0].forEach(field => {
          newFieldRow.push({
            ...field,
            value: field.inputType === 'number' ? '0' : ''
          });
        });
        
        // Add the new row to the Fields array
        section.Fields.push(newFieldRow);
      }
    }
  }

  handleDeleteField(event) {
    const sectionLabel = event.target.dataset.label;
    const index = parseInt(event.target.dataset.index, 10);
    const sectionIndex = this.formData.Incurred.findIndex(sec => sec.Label === sectionLabel);
    
    if (sectionIndex >= 0) {
      const section = this.formData.Incurred[sectionIndex];
      
      // Only delete if there's more than one row
      if (section.Fields.length > 1) {
        section.Fields.splice(index, 1);
      } else if (section.Fields.length === 1) {
        // If it's the last row, just clear the values
        section.Fields[0].forEach(field => {
          field.value = field.inputType === 'number' ? '0' : '';
        });
      }
    }
  }

  handleInputChange(event) {
    const sectionLabel = event.target.dataset.label;
    const fieldName = event.target.dataset.field;
    const index = parseInt(event.target.dataset.index, 10);
    const sectionIndex = this.formData.Incurred.findIndex(sec => sec.Label === sectionLabel);

    // console.log('Input changed - Section:', sectionLabel, 'Field:', fieldName, 'Index:', index, 'Value:', event.target.value);

    if (sectionIndex >= 0 && this.formData.Incurred[sectionIndex].Fields[index]) {
      const fieldValue = event.target.value;
      const fieldIndex = this.formData.Incurred[sectionIndex].Fields[index].findIndex(
        field => field.fieldLabel === fieldName
      );
      
      if (fieldIndex >= 0) {
        this.formData.Incurred[sectionIndex].Fields[index][fieldIndex].value = fieldValue;
        this.calculateNetPrice(sectionIndex, index);
      }
    }
  }

  calculateNetPrice(sectionIndex, rowIndex) {
    // console.log('Calculating net price for section:', sectionIndex, 'row:', rowIndex);
    const section = this.formData.Incurred[sectionIndex];
    const fieldRow = section.Fields[rowIndex];
    
    if (fieldRow) {
      // Find trackable fields (qty and unit price)
      const trackableFields = fieldRow.filter(field => field.track);
      // Find the net price field
      const netPriceField = fieldRow.find(field => field.autoUpdate);
      
      if (netPriceField && trackableFields.length === 2) {
        const [field1, field2] = trackableFields;
        const value1 = parseFloat(field1.value) || 0;
        const value2 = parseFloat(field2.value) || 0;
        const netPrice = value1 * value2;
        
        // Update the net price field
        netPriceField.value = netPrice.toFixed(2);
      }
    }


    const netPriceElements = this.template.querySelectorAll('lightning-input[data-class-name="netPrice"]');

    console.log("net price elemenets==", netPriceElements);
   // const values = Array.from(netPriceElements).map(element => element.value);

    const sum = Array.from(netPriceElements)
    .reduce((total, element) => {
        const value = parseFloat(element.value) || 0; // Convert to number, default to 0 if invalid
        return total + value;
    }, 0);

    console.log("Sum element===", sum)


  }

  validateFormData() {
    for (const section of this.formData.Incurred) {
      const sectionLabel = section.Label;
      
      for (const fieldRow of section.Fields) {
        for (const field of fieldRow) {
          if (field.required && (!field.value || !field.value.toString().trim())) {
            this.dispatchEvent(new ShowToastEvent({
              title: 'Validation Error',
              message: `Please fill in all required fields in the ${sectionLabel} section.`,
              variant: 'error',
            }));
            return false;
          }
        }
      }
    }
    return true;
  }






  getFieldValue(sectionLabel, rowIndex, fieldLabel) {
    try {
      const sectionIndex = this.formData.Incurred.findIndex(sec => sec.Label === sectionLabel);
      if (sectionIndex < 0 || !this.formData.Incurred[sectionIndex].Fields[rowIndex]) {
        return '';
      }
      
      const field = this.formData.Incurred[sectionIndex].Fields[rowIndex].find(
        f => f.fieldLabel === fieldLabel
      );
      
      return field && field.value !== undefined ? field.value : '';
    } catch (error) {
      console.error('Error getting field value:', error);
      return '';
    }
  }


mergeExpensesIntoMaterial(expenses) {

  let materialSection = this.formData.Incurred.find(sec => sec.Label === "Material");

  if (materialSection) {

      materialSection.Fields = [];

      expenses.forEach(expense => {
          let newRow = [
              {
                  fieldLabel: "Id",
                  value: expense.Id.toString(),
                  required: true,
                  inputType: "text",
                  isDisabled: true,
                  track: true,
                  autoUpdate: false
              },
              {
                  fieldLabel: "Qty",
                  value: expense.Quantity__c.toString(),
                  required: true,
                  inputType: "number",
                  isDisabled: false,
                  track: true,
                  autoUpdate: false
              },
              {
                  fieldLabel: "Detail",
                  value: expense.Title__c,
                  required: true,
                  inputType: "text",
                  isDisabled: false,
                  track: false,
                  autoUpdate: false
              },
              {
                  fieldLabel: "Unit Price",
                  value: expense.Unit_Price__c.toString(),
                  required: true,
                  inputType: "number",
                  isDisabled: false,
                  track: true,
                  autoUpdate: false
              },
              {
                  fieldLabel: "Net Price ($)",
                  value: expense.Net_Price__c.toString(),
                  required: false,
                  inputType: "number",
                  isDisabled: true,
                  track: false,
                  autoUpdate: true
              }
          ];
          materialSection.Fields.push(newRow);
      });
      // console.log("Updated Material section:", JSON.stringify(materialSection, null, 2));
  } else {
      console.warn("Material section not found in formData!");
  }
}


 handlePickListChange(event) {
    this.selectedPickListValue = event.detail.value; 
   }


}