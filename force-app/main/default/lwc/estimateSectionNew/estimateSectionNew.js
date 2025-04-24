import { api, LightningElement, track } from 'lwc';
import { currentFormData } from './estimateData'; 
import getTradeAndVendorId from '@salesforce/apex/EstimateController.getTradeAndVendorId';
import getVTRMRecords from '@salesforce/apex/EstimateController.getVTRMRecords'; 

export default class EstimateSection extends LightningElement {

  @api rec;
  @track formData = {}; 
  @track options = [];  // For picklist options
  @track rates = {};    // Holds rates for different picklist values
  
  @api
  getEstimateFormData() {
    return this.formData;
  }

  get formDataString() {
    return JSON.stringify(this.formData, null, 2);
  }

  connectedCallback() {
    // console.log("=== connectedCallback STARTED ===");

    // Initialize formData
    this.formData = JSON.parse(JSON.stringify(currentFormData));
    this.addPicklistFlags();

    // Fetch the dynamic picklist options and rates
    this.loadRates();

    // console.log("=== connectedCallback COMPLETED ===");
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


  updateUnitPrice(sectionIndex, row, picklistValue) {
    const section = this.formData.Estimate[sectionIndex];
    const unitPriceField = row.find(field => field.fieldLabel === 'UnitPrice');

    if (unitPriceField && this.rates[picklistValue] !== undefined) {
      const selectedRate = this.rates[picklistValue];
      unitPriceField.value = selectedRate;
      this.calculateNetPrice(sectionIndex, row);
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
      // console.log("net price ",netPrice.toFixed(2))
    }


    //const newnetPriceElements = this.template.querySelectorAll('lightning-input[data-class-name="netPrice"]');


    const netPriceElements = this.template.querySelectorAll('lightning-input[data-class-name="netPrice"]');

    console.log("net price elemenets==", netPriceElements);
   // const values = Array.from(netPriceElements).map(element => element.value);

    const sum = Array.from(netPriceElements)
    .reduce((total, element) => {
        const value = parseFloat(element.value) || 0; // Convert to number, default to 0 if invalid
        return total + value;
    }, 0);

    console.log("Sum element===", sum)

// Find the totalAmount element and update its text content
const totalElement = this.template.querySelector('.totalAmount');
console.log("Total Element data==", totalElement)
if (totalElement) {
    totalElement.textContent = sum.toFixed(2); // e.g., "300.00"
    console.log('Updated total:', sum);
} else {
    console.log('Total element not found.');
}
    
  }
}



//   handleInputChangePicklist(event) {

//     const sectionLabel = event.target.dataset.label;
//     const sectionIndex = this.formData.Estimate.findIndex(sec => sec.Label === sectionLabel);
//     const fieldLabel = event.target.dataset.field;
//     const newValue = event.target.value;
//     const index = parseInt(event.target.dataset.index, 10);

//     console.log(index)

//     if (sectionIndex >= 0) {
//         const section = this.formData.Estimate[sectionIndex];
//         section.Fields.forEach(row => {
//             row.forEach(field => {
//                 // console.log("filed ", field);
//                 if (field.fieldLabel === 'LabourPicklist') {

//                     // Check if we have the picklist value in rates
//                     if (this.rates[newValue]) {
//                         console.log(this.rates[newValue]);

//                         // Update the Unit Price field with the corresponding rate from rates
//                         const unitPriceField = row.find(f => f.fieldLabel === 'Unit Price');
//                         if (unitPriceField) {
//                             unitPriceField.value = this.rates[newValue];
//                             console.log('Unit Price updated:', unitPriceField.value);
                            
//                             // Recalculate the Net Price when Unit Price is updated
//                             console.log("section index" , sectionIndex)
//                             console.log("index" , row)
//                             this.calculateNetPrice(sectionIndex, 0);
//                         }
//                     }
//                 }
//             });
//         });
//     }
// }


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

   console.log('Input changed - Section:', sectionLabel, 'Field:', fieldName, 'Index:', index, 'Value:', event.target.value);

  if (sectionIndex >= 0 && this.formData.Estimate[sectionIndex].Fields[index]) {
 
    const fieldValue = event.target.value;
    const fieldIndex = this.formData.Estimate[sectionIndex].Fields[index].findIndex(
      field => field.fieldLabel === fieldName
    );

    
    if (fieldIndex >= 0) {
      this.formData.Estimate[sectionIndex].Fields[index][fieldIndex].value = fieldValue;


      
      this.calculateNetPrice(sectionIndex, index);
    }
  }
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


  addPicklistFlags() {
    this.formData.Estimate.forEach(section => {
      section.Fields.forEach(row => {
        row.forEach(field => {
          if (field.fieldLabel === 'LabourPicklist') {
            field.isPicklist = true;  // Mark as picklist field
          }
        });
      });
    });
  }
}