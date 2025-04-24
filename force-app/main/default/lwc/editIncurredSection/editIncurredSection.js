import { api, LightningElement, track } from 'lwc';
import {  currentFormData } from './incurredData'; // Ensure both are exported correctly
// import createEstimateRecord from '@salesforce/apex/EstimateController.createEstimateRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateIncurredDataInWo from '@salesforce/apex/EstimateController.updateIncurredDataInWo';
import getLatestEstimateData from '@salesforce/apex/EditEstimateController.getLatestEstimateData';
// import updateExpenses from '@salesforce/apex/EstimateController.updateExpenses';


export default class IncurredSection extends LightningElement {
  @api recordId;
  @api rec;
  // @api existingEstimateData; // Property to receive existing estimate data
  @track formData = {}; // Holds user input and merged data
  @track fieldValues = []; // Array to hold field values for the template
  @track netPriceValues = []; // Array to hold net price values for the template
  @track  IncurredData = []; // To store formatted estimate data
  @track options=[];
  @track selectedPickListValue = ''; // Stores selected value
  @track expenseIdList =[]; // store the id of the expense that has to be deleted

  @api getIncurredFormData() {
    return this.formData;
  } 

  get formDataString() {
    return JSON.stringify(this.formData, null, 2);
  }


  connectedCallback() {

    this.formData = JSON.parse(JSON.stringify(currentFormData));
    

   
            

    getLatestEstimateData({ workOrderId: this.rec })
        .then(data => {
            try {
                // console.log("Raw Incurred Data:", data);

                if (data) {
                    let parsedData = JSON.parse(data); // Convert JSON string to object
                    this.IncurredData = parsedData.Incurred;

                    // Merge estimateData into formData
                    this.mergeEstimateData();
                }
            } catch (error) {
                console.error("Error parsing Estimate Data:", error);
            }
        })
        .catch(error => {
            console.error("Error fetching Estimate Data:", error);
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
  }

  // validateFormData() {
  //   for (const section of this.formData.Incurred) {
  //     const sectionLabel = section.Label;
      
  //     for (const fieldRow of section.Fields) {
  //       for (const field of fieldRow) {
  //         if (field.required && (!field.value || !field.value.toString().trim())) {
  //           this.dispatchEvent(new ShowToastEvent({
  //             title: 'Validation Error',
  //             message: `Please fill in all required fields in the ${sectionLabel} section.`,
  //             variant: 'error',
  //           }));
  //           return false;
  //         }
  //       }
  //     }
  //   }
  //   return true;
  // }

//   handleSave() {
//     console.log("clicked save button");

//     if (!this.validateFormData()) {
//         return;
//     }

//     let expenseIdList = []; // List to store all extracted Id values

//     const formattedData = {
//         Incurred: this.formData.Incurred.map(section => ({
//             Label: section.Label,
//             Fields: section.Fields.map(fieldRow => 
//                 fieldRow.map(field => ({
//                     fieldLabel: field.fieldLabel,
//                     value: field.value
//                 }))
//             )
//         }))
//     };
//     console.log("Data being saved:", JSON.stringify(formattedData, null, 2));

//     // Extract IDs and log them
  
//     formattedData.Incurred.forEach(section => {
//         section.Fields.forEach(fieldGroup => {
//             fieldGroup.forEach(field => {
//                 if (field.fieldLabel === "Id" && field.value) {
//                     this.expenseIdList.push(field.value);
//                 }
//             });
//         });
//     });

//     // // Log the final ID list
//     // console.log("Final Expense ID List:", this.expenseIdList[0]);



//     updateExpenses({expensesList: this.expenseIdList}).then((data)=>{console.log(data)
      
//     }).catch((error)=>{
//       console.log(error)
//     })

//     updateIncurredDataInWo({ formData: JSON.stringify(formattedData), workOrderId: this.rec })
//         .then(() => {
//             console.log("Successfully updated incurred data in Work Order.");
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Success',
//                 message: `Incurred Saved successfully! Record Id: ${this.rec}`,
//                 variant: 'success',
//             }));
//         })
//         .catch(error => {
//             console.error("Error saving incurred data:", error);
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Error',
//                 message: 'Failed to save incurred data',
//                 variant: 'error',
//             }));
//         });
// }


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
 mergeEstimateData() {
    // console.log("Merging estimateData into formData...");

    this.IncurredData.forEach(existingSection => {
        let formSection = this.formData.Incurred.find(sec => sec.Label === existingSection.Label);

        if (formSection) {
            // Ensure formData has enough rows to match estimateData
            while (formSection.Fields.length < existingSection.Fields.length) {
                formSection.Fields.push([...formSection.Fields[0].map(f => ({ ...f, value: f.inputType === 'number' ? 0 : '' }))]);
            }

            // Now update each row
            existingSection.Fields.forEach((existingRow, rowIndex) => {
                existingRow.forEach(existingField => {
                    let formField = formSection.Fields[rowIndex].find(f => f.fieldLabel === existingField.fieldLabel);
                    
                    if (formField) {
                        formField.value = existingField.value; // Update value
                    }
                });
            });
        }
    });

    // console.log("Merged formData:", JSON.stringify(this.formData, null, 2));
}
mergeExpensesIntoMaterial(expenses) {
  // console.log("Merging Expenses into Material section...");

  // Find the Material section
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




}