import { api, LightningElement, track } from 'lwc';
import {  currentFormData } from './estimateData'; // Ensure both are exported correctly
import createEstimateRecord from '@salesforce/apex/EstimateController.createEstimateRecord';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import updateEstimateDataInWo from '@salesforce/apex/EstimateController.updateEstimateDataInWo';
import getTradeAndVendorId from '@salesforce/apex/EstimateController.getTradeAndVendorId';
import getVTRMRecords from '@salesforce/apex/EstimateController.getVTRMRecords';
import getLatestEstimateData from '@salesforce/apex/EditEstimateController.getLatestEstimateData';

export default class EstimateSection extends LightningElement {
  @api rec;
  @api existingEstimateData; // Property to receive existing estimate data
  @track formData = {}; // Holds user input and merged data
  @track fieldValues = []; // Array to hold field values for the template
  @track netPriceValues = []; // Array to hold net price values for the template
  @track showDebug = false; // Controls debug section visibility
  @track estimateData = []; // To store formatted estimate data
  @track options=[];
  @track selectedPickListValue = ''; // Stores selected value

  @api
  getEstimateFormData() {
    return this.formData;
  }


  get formDataString() {
    return JSON.stringify(this.formData, null, 2);
  }



  connectedCallback() {
    console.log("=== connectedCallback STARTED ===");
    // console.log("Initializing form structure from estimateData...");
    
    this.formData = JSON.parse(JSON.stringify(currentFormData));
    this.addPicklistFlags();


    this.loadRates();
              

    getLatestEstimateData({ workOrderId: this.rec })
        .then(data => {
            try {
                // console.log("Raw Estimate Data:", data);

                if (data) {
                    let parsedData = JSON.parse(data); // Convert JSON string to object
                    this.estimateData = parsedData.Estimate;
                    console.log("jai shree ram",this.estimateData)

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

    console.log("=== connectedCallback COMPLETED ===");
}

  handleAddField(event) {
    const sectionLabel = event.target.dataset.label;
    const sectionIndex = this.formData.Estimate.findIndex(sec => sec.Label === sectionLabel);
    
    if (sectionIndex >= 0) {
      const section = this.formData.Estimate[sectionIndex];
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
    const sectionIndex = this.formData.Estimate.findIndex(sec => sec.Label === sectionLabel);
    
    if (sectionIndex >= 0) {
      const section = this.formData.Estimate[sectionIndex];
      
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

  handleInputChangePicklist(event) {
    const sectionLabel = event.target.dataset.label;
    const sectionIndex = this.formData.Estimate.findIndex(sec => sec.Label === sectionLabel);
    const fieldLabel = event.target.dataset.field;
    const newValue = event.target.value;
    const rowIndex = parseInt(event.target.dataset.index, 10);  // This is where you capture the correct row index

    console.log(rowIndex);  // Debugging line to check the index

    if (sectionIndex >= 0) {
        const section = this.formData.Estimate[sectionIndex];
        section.Fields.forEach((row, rowIdx) => {
            row.forEach(field => {
                if (field.fieldLabel === 'LabourPicklist') {
                    if (this.rates[newValue]) {
                        const unitPriceField = row.find(f => f.fieldLabel === 'Unit Price');
                        if (unitPriceField) {
                            unitPriceField.value = this.rates[newValue];
                            console.log('Unit Price updated:', unitPriceField.value);

                            // Pass the correct index for recalculating the Net Price
                            this.calculateNetPrice(sectionIndex, rowIdx);
                        }
                    }
                }
            });
        });
    }
}

handleInputChangeInputbox(event) {
  
  const sectionLabel = event.target.dataset.label;
  const fieldName = event.target.dataset.field;
  const index = parseInt(event.target.dataset.index, 10);
  const sectionIndex = this.formData.Estimate.findIndex(sec => sec.Label === sectionLabel);

  // console.log('Input changed - Section:', sectionLabel, 'Field:', fieldName, 'Index:', index, 'Value:', event.target.value);

  if (sectionIndex >= 0 && this.formData.Estimate[sectionIndex].Fields[index]) {
 
    const fieldValue = event.target.value;
    const fieldIndex = this.formData.Estimate[sectionIndex].Fields[index].findIndex(
      field => field.fieldLabel === fieldName
    );

    
    if (fieldIndex >= 0) {
      this.formData.Estimate[sectionIndex].Fields[index][fieldIndex].value = fieldValue;

      // console.log("qqqqqqqqqsectionIndex " , sectionIndex)
      // console.log("qqqqqqqindex " , index)
      
      this.calculateNetPrice(sectionIndex, index);
    }
  }
}


  calculateNetPrice(sectionIndex, rowIndex) {
    // console.log('Calculating net price for section:', sectionIndex, 'row:', rowIndex);
    const section = this.formData.Estimate[sectionIndex];
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

  validateFormData() {
    for (const section of this.formData.Estimate) {
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

//   handleSave() {
//     // console.log('Save initiated - validating form data...');
//     if (!this.validateFormData()) {
//         console.warn('Form validation failed - save aborted');
//         return;
//     }

//     const formattedData = {
//         Estimate: this.formData.Estimate.map(section => ({
//             Label: section.Label,
//             Fields: section.Fields.map(fieldRow => 
//                 fieldRow.map(field => ({
//                     fieldLabel: field.fieldLabel,
//                     value: field.value
//                 }))
//             )
//         }))
//     };

//     // console.log('Data being saved:', JSON.stringify(formattedData, null, 2));
//     // console.log('WorkOrder ID:', this.rec);

//     createEstimateRecord({ formData: JSON.stringify(formattedData), workOrderId: this.rec })
//         .then((rec) => {
//             // console.log('Estimate created successfully, record ID:', rec);
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Success',
//                 message: `Estimate created successfully! Record Id: ${rec}`,
//                 variant: 'success',
//             }));
//             this.resetFormData();
//         })
//         .catch((error) => {
//             console.error('Error creating estimate:', error);
//             this.dispatchEvent(new ShowToastEvent({
//                 title: 'Error',
//                 message: error.body ? error.body.message : error.message,
//                 variant: 'error',
//             }));
//         });

//     // console.log('Updating estimate data in work order...');
//     updateEstimateDataInWo({ formData: JSON.stringify(formattedData), workOrderId: this.rec });
// }




  // resetFormData() {
    // Reset to initial state by reloading currentFormData
    // this.formData = JSON.parse(JSON.stringify(currentFormData));
    
  // }

  getFieldValue(sectionLabel, rowIndex, fieldLabel) {
    try {
      const sectionIndex = this.formData.Estimate.findIndex(sec => sec.Label === sectionLabel);
      if (sectionIndex < 0 || !this.formData.Estimate[sectionIndex].Fields[rowIndex]) {
        return '';
      }
      
      const field = this.formData.Estimate[sectionIndex].Fields[rowIndex].find(
        f => f.fieldLabel === fieldLabel
      );
      
      return field && field.value !== undefined ? field.value : '';
    } catch (error) {
      console.error('Error getting field value:', error);
      return '';
    }
  }
  mergeEstimateData() {
    console.log("Merging estimateData into formData...");

    this.estimateData.forEach(existingSection => {
      console.log("I am Form Data" , this.formData)
        let formSection = this.formData.Estimate.find(sec => sec.Label === existingSection.Label);

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
handlePickListChange(event) {
    this.selectedPickListValue = event.detail.value; 
   }

   addPicklistFlags() {
    this.formData.Estimate.forEach(section => {
      section.Fields.forEach(row => {
        row.forEach(field => {
          if (field.fieldLabel === 'LabourPicklist') {
            field.isPicklist = true;
          }
        });
      });
    });
  }

    loadRates() {
      getTradeAndVendorId({ workorderId: this.rec })
        .then(data => {
          const tradeId = data.tradeId;
          const vendorId = data.vendorId;
          
          if (tradeId && vendorId) {
            getVTRMRecords({ tradeId: tradeId, vendorId: vendorId })
              .then(vtrmData => {
                if (vtrmData && vtrmData.length > 0) {
                  this.rates = {
                    'Regular Rate': vtrmData[0].Regular_Rate__c,
                    'After Hours Rate': vtrmData[0].After_Hours_Rate__c,
                    'Weekend Rate': vtrmData[0].Weekend_Rate__c,
                    'Holiday Rate': vtrmData[0].Holiday_Rate__c,
                    'Emergency Rate': vtrmData[0].Emergency_Rate__c,
                    'Weekend Emergency Rate': vtrmData[0].Weekend_Emergency_Rate__c,
                  };
  
    
  
                  // Update picklist options dynamically
                  this.options = Object.keys(this.rates).map(rateKey => ({
                    label: rateKey,
                    value: rateKey
                  }));
                  // console.log(this.options)
                }
              })
              .catch(error => {
                console.error('Error fetching VTRM records:', error);
              });
          }
        })
        .catch(error => {
          console.error('Error during trade/vendor fetch:', error);
        });
    }
  



  


}