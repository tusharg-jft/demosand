import createInvoiceRecord from '@salesforce/apex/InvoiceController.createInvoiceRecord';
import getEstimateModalInfo from '@salesforce/apex/EstimateModalInfo.getEstimateModalInfo';
import { api, LightningElement, track } from 'lwc';
import { currentFormData } from './Data'; // Ensure both are exported correctly
import getTradeAndVendorId from '@salesforce/apex/EstimateController.getTradeAndVendorId';
import getVTRMRecords from '@salesforce/apex/EstimateController.getVTRMRecords';
// import updateEstimateprices from '@salesforce/apex/EstimateController.updateEstimateprices'

import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getExpenses from '@salesforce/apex/EstimateController.getExpenses';
import getLatestPrices from '@salesforce/apex/EstimateController.getLatestPrices';
import getTripRatesfromvendor from '@salesforce/apex/EstimateController.getTripRatesfromvendor';
import getLatestInvoicedData from '@salesforce/apex/InvoiceController.getLatestInvoicedData';
import getLatestInvoicePrices from '@salesforce/apex/InvoiceController.getLatestInvoicePrices';
import getconstanttextinvoice from '@salesforce/apex/InvoiceController.getconstanttextinvoice';
import deactivateExpenses from '@salesforce/apex/EstimateController.deactivateExpenses';
import updateWorkOrder from '@salesforce/apex/EstimateController.updateWorkOrder';

export default class EstimateModalButton extends LightningElement {
  showModal = false;
  @api type; // 'add' or 'edit'
  @api recordId;
  @api existingEstimateData; // Property to receive existing estimate data
  @api rec
  @api passedestimateid;


  @track formData = {}; // Holds user input and merged data
  @track fieldValues = []; // Array to hold field values for the template
  @track netPriceValues = []; // Array to hold net price values for the template
  @track showDebug = false; // Controls debug section visibility
  @track estimateData = []; // To store formatted estimate data
  @track IncurredData = []
  @track options = [];
  @track selectedPickListValue = ''; // Stores selected value
  @track showModal = false;
  @track workOrderData = {};
  @track vendorData = {};
  @track siteData = {};
  @track isEstimate = false;
  @track isIncurred = false;
  @track discountOptions = [
    { label: 'Flat Rate', value: 'Flat Rate' },
    { label: 'Percentage', value: 'Percentage' },

  ];
  @track AssementValue = '';
  @track ProposalValue = '';


  @track netTotal = 0;
  @track totalDiscount = 0;
  @track taxAmount = 0;
  @track grandTotal = 0;

  @track formattedsiteAddress;
  @track formattedvendorAddress;


  @track selectedDiscountType = '';
  @track discountValue = null;
  @track showDiscountValue = false;
  @track discountPlaceholder = '';

  @track tripRates = {};
  @track tripOptions = [];

  @track picklistOptionsMap = {}; // Holds dynamic picklist options by fieldLabel

  @track internalEstimateNumber;
  @track assessmentText = '';handleInternalnumber(event) {
    this.internalEstimateNumber = event.target.value;
    // console.log('Internal Estimate No:', this.internalEstimateNumber);
  }
  @track proposalText = '';

  
  


  discountOptions = [
    { label: 'Flat Rate', value: 'Flat' },
    { label: 'Percentage', value: 'Percentage' }
  ];


  get label() {
    return this.type === 'edit' ? 'Edit Invoice' : 'Add Invoice';
  }

  get isAdd() {
    return this.type === 'add';
  }
  get isEdit() {
    return this.type === 'edit';
  }
  get formDataSections() {
    const sections = Object.keys(this.formData).map(typeKey => ({
      type: typeKey,
      sections: this.formData[typeKey]
    }));
    return sections;
  }

  getPicklistOptions(fieldLabel) {
    return this.picklistOptionsMap[fieldLabel] || [];
  }

  connectedCallback() {
    document.documentElement.classList.add('modal-open'); // Apply to HTML
    document.body.classList.add('modal-open'); // Apply to Body
    if (this.recordId == null) {
      this.recordId = this.rec
    }
    this.formData = JSON.parse(JSON.stringify(currentFormData));
    this.addPicklistFlags();


    this.loadRates();


    getEstimateModalInfo({ workorderid: this.recordId })
      .then(result => {
        if (result) {
          // console.log('Result from Apex:', result);

          this.workOrderData = result.wo;
          this.vendorData = result.vendoruser || {};
          this.siteData = result.siteuser || {};

          this.formattedvendorAddress = this.formatAddress(this.vendorData.Address__c)
          this.formattedsiteAddress = this.formatAddress(this.siteData.Address__c)

          // console.log("this.formattedvendorAddress ", this.formattedsiteAddress)
          // console.log("this.formattedsiteAddress " , this.formatsiteAddress)
        } else {
          // console.error('No data returned from Apex');
        }
      })
      .catch(error => {
        console.error('Error fetching data:', error);
      });

    getExpenses({ invoiceId: this.passedestimateid }).then(data => {
      // console.log("Raw Expenses Data: ", data);
      if (data && data.length > 0) {
        this.mergeExpensesIntoMaterial(data);
      }
    }).catch(error => {
      console.error("Error fetching expenses:", error);
    });
    // IF CONDITION   <=============================================>
    if (this.type == "edit") {
      console.log("Inside the IF" , this.type)

      console.log("i am the passed id " ,this.passedestimateid );

      getLatestInvoicedData({ invoiceId: this.passedestimateid })
        .then(data => {
          try {
            console.log("Raw Estimate Data:", data);

            if (data) {
              let parsedData = JSON.parse(data); // Convert JSON string to object

              console.log("i am the passed data" , parsedData)
              this.estimateData = parsedData.Estimate;
              this.IncurredData = parsedData.Incurred;
              this.mergeEstimateData();

              // console.log("this.netTotal" , this.netTotal)
            }
          } catch (error) {
            console.error("Error parsing Estimate Data:", error);
          }
        })
        .catch(error => {
          console.error("Error fetching Estimate Data:", error);
        });

        getLatestInvoicePrices({ invoiceId: this.passedestimateid }).then((data) => {
        console.log("get price list ", data)
        this.grandTotal = data.GrandTotal;
        this.netTotal = data.NetPrice;
        this.totalDiscount = data.TotalDiscount;
        this.internalEstimateNumber = data.InternalEstimateNo;
        console.log("grand total" , this.grandTotal);
        console.log("net total" , this.netTotal);
        console.log("total discount" , this.totalDiscount);
        console.log("internal number" , this.internalEstimateNumber);
      }).catch((error) => {
        console.log(error)
      })

      getconstanttextinvoice({ invoiceId: this.passedestimateid })
              .then((data) => {
                  this.assessmentText = data.AssessmentTroubleshoot;
                  this.proposalText = data.ProposalForRepairs;
      
                  // Log values after setting
                  console.log("Assessment Text:", this.assessmentText);
                  console.log("Proposal Text:", this.proposalText);
              })
              .catch((error) => {
                  console.error("Error fetching constant text:", error);
              });
    }






    console.log("=== connectedCallback COMPLETED ===");

  }

  handleClick() {
    this.showModal = true;
    //  console.log(this.recordId)
    // console.log("type of button is testing 1",this.type);
  }

  handleCloseModal() {
    this.showModal = false;
  }

  handleSave(event) {
    // Your save logic here
    this.showModal = false;
  }
  // Open Modal
  handleOpenModal() {
    this.showModal = true;
  }

  // Close Modal
  handleCloseModal() {

    this.showModal = false;
    document.documentElement.classList.remove('modal-open');
    document.body.classList.remove('modal-open');
  }


  // Estimate JS
  //Done
  handleAddFieldDynamic(event) {
    console.log("clicked on handleAddFieldDynamic ")
    const sectionType = event.target.dataset.type; // 'Estimate' or 'Incurred'
    console.log(sectionType)
    const sectionLabel = event.target.dataset.label;

    const sectionList = this.formData[sectionType];
    const sectionIndex = sectionList.findIndex(sec => sec.Label === sectionLabel);

    if (sectionIndex >= 0) {
      const section = sectionList[sectionIndex];
      const newFieldRow = [];

      // Deep clone the first row to avoid reference issues
      if (section.Fields.length > 0 && section.Fields[0].length > 0) {
        section.Fields[0].forEach(field => {
          newFieldRow.push(JSON.parse(JSON.stringify({
            ...field,
            value: field.inputType === 'number' ? '' : ''
          })));
        });

        section.Fields.push(newFieldRow);
      }
    }
  }
  //Done
  handleDeleteFieldDynamic(event) {
    const sectionType = event.target.dataset.type;
    const sectionLabel = event.target.dataset.label;
    const index = parseInt(event.target.dataset.index, 10);

    const sectionList = this.formData[sectionType];
    const sectionIndex = sectionList.findIndex(sec => sec.Label === sectionLabel);

    if (sectionIndex >= 0) {
      const section = sectionList[sectionIndex];

      if (section.Fields.length > 1) {
        section.Fields.splice(index, 1);
      } else if (section.Fields.length === 1) {
        section.Fields[0].forEach(field => {
          field.value = field.inputType === 'number' ? '0' : '';
        });
      }

      // Recalculate after deletion
      this.calculateGrandTotal();
    }
  }

  //Done
  handleInputChangeDynamic(event) {
    // console.log("testing heloo 123")
    // console.log("🟦 handleInputChangeDynamic fired");
  
    const sectionType = event.target.dataset.type; // 'Estimate' or 'Incurred'
    const sectionLabel = event.target.dataset.label;
    const fieldName = event.target.dataset.field;
    const index = parseInt(event.target.dataset.index, 10);
  
    const sectionList = this.formData[sectionType];
    const sectionIndex = sectionList.findIndex(sec => sec.Label === sectionLabel);
  
  
    if (sectionIndex >= 0 && sectionList[sectionIndex].Fields[index]) {
      const fieldValue = event.target.value;
      const fieldIndex = sectionList[sectionIndex].Fields[index].findIndex(
        field => field.fieldLabel === fieldName
      );
  
      if (fieldIndex >= 0) {
        sectionList[sectionIndex].Fields[index][fieldIndex].value = fieldValue;
  
        this.calculateNetPriceDynamic(sectionType, sectionIndex, index);
        this.calculateGrandTotal();
        // this.handleDiscountValueChange()
      } else {
        console.warn("⚠️ Field not found within row.");
      }
    } else {
      console.warn("⚠️ Section or Row not found.");
    }
  } // handleInputChangeDynamic(event) {
  //   console.log("🟦 handleInputChangeDynamic fired");

  //   const sectionType = event.target.dataset.type; // 'Estimate' or 'Incurred'
  //   const sectionLabel = event.target.dataset.label;
  //   const fieldName = event.target.dataset.field;
  //   const index = parseInt(event.target.dataset.index, 10);

  //   const sectionList = this.formData[sectionType];
  //   const sectionIndex = sectionList.findIndex(sec => sec.Label === sectionLabel);


  //   if (sectionIndex >= 0 && sectionList[sectionIndex].Fields[index]) {
  //     const fieldValue = event.target.value;
  //     const fieldIndex = sectionList[sectionIndex].Fields[index].findIndex(
  //       field => field.fieldLabel === fieldName
  //     );

  //     if (fieldIndex >= 0) {
  //       sectionList[sectionIndex].Fields[index][fieldIndex].value = fieldValue;

  //       this.calculateNetPriceDynamic(sectionType, sectionIndex, index);
  //       this.calculateGrandTotal();
  //       // this.handleDiscountValueChange()
  //     } else {
  //       console.warn("⚠️ Field not found within row.");
  //     }
  //   } else {
  //     console.warn("⚠️ Section or Row not found.");
  //   }
  // }

  //Done
  // calculateNetPriceDynamic(sectionType, sectionIndex, rowIndex) {
  //   const section = this.formData[sectionType][sectionIndex];
  //   const fieldRow = section.Fields[rowIndex];

  //   if (fieldRow) {
  //     const trackableFields = fieldRow.filter(field => field.track);
  //     const netPriceField = fieldRow.find(field => field.autoUpdate);

  //     if (netPriceField && trackableFields.length === 2) {
  //       const [field1, field2] = trackableFields;
  //       const value1 = parseFloat(field1.value) || 0;
  //       const value2 = parseFloat(field2.value) || 0;
  //       const netPrice = value1 * value2;

  //       netPriceField.value = netPrice.toFixed(2);
  //       console.log(netPrice)
  //     }
  //   }
  // }
  calculateNetPriceDynamic(sectionType, sectionIndex, rowIndex) {

    console.log("calculateNetPriceDynamic")
  
  
    const section = this.formData[sectionType][sectionIndex];
    const fieldRow = section.Fields[rowIndex];
  
    if (fieldRow) {
      const qtyField = fieldRow.find(field => field.fieldLabel === 'Qty');
      const unitPriceField = fieldRow.find(field => field.fieldLabel === 'Unit Price');
      const techField = fieldRow.find(field => field.fieldLabel === 'Tech'); // <- optional field
      const netPriceField = fieldRow.find(field => field.fieldLabel === 'Net Price' && field.autoUpdate);
  
      const qty = parseFloat(qtyField?.value) || 0;
      const unitPrice = parseFloat(unitPriceField?.value) || 0;
      const tech = techField ? (parseFloat(techField.value) || 1) : 1;
  
      const calculatedNetPrice = qty * unitPrice * tech;
  
      if (netPriceField) {
        netPriceField.value = calculatedNetPrice.toFixed(2);
      }
    }
  }
  


  handleInputChangePicklist(event) {
    console.log('🟦 [Step 1] handleInputChangePicklist triggered');

    const sectionType = event.target.dataset.type;
    const sectionLabel = event.target.dataset.label;
    const fieldLabel = event.target.dataset.field;
    const rawValue = event.target.value;
    const newValue = rawValue ? rawValue.trim() : '';
    const rowIndex = parseInt(event.target.dataset.index, 10);

    if (!sectionType || isNaN(rowIndex)) {
    }

    const sectionList = this.formData[sectionType];
    const sectionIndex = sectionList.findIndex(sec => sec.Label === sectionLabel);

    if (sectionIndex >= 0) {
      const row = sectionList[sectionIndex].Fields[rowIndex];
      row.forEach(field => {
        if (field.fieldLabel === fieldLabel) {
          field.value = newValue;

          // Choose rate map
          const rateMap = fieldLabel === 'Trip Type' ? this.tripRates : this.rates;

          // Find the Unit Price field in the same row
          const unitPriceField = row.find(f => f.fieldLabel === 'Unit Price');

          if (
            unitPriceField &&
            rateMap &&
            Object.prototype.hasOwnProperty.call(rateMap, newValue)
          ) {
            unitPriceField.value = rateMap[newValue];

            this.calculateNetPriceDynamic(sectionType, sectionIndex, rowIndex);

            this.calculateGrandTotal();

            this.formData = { ...this.formData };
          } else {
            console.warn(`❌ [Step 9 - Error] No matching rate found in rateMap for: "${newValue}"`);
            console.warn("🧾 [Available keys]:", Object.keys(rateMap));
          }
        }
      });
    } else {
      console.warn("⚠️ [Step 4 - Error] Section not found for picklist update.");
    }
  }



  mergeEstimateData() {
    // console.log("Merging estimateData into formData...");

    this.estimateData.forEach(existingSection => {
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
  //Done
  addPicklistFlags() {
    this.formData.Estimate.forEach(section => {
      section.Fields.forEach(row => {
        row.forEach(field => {
          if (field.fieldLabel === 'Rate Type') {
            field.isPicklist = true;
            field.options = this.picklistOptionsMap['Rate Type'] || [];
          }
          if (field.fieldLabel === 'Trip Type') {
            field.isPicklist = true;
            field.options = this.picklistOptionsMap['Trip Type'] || [];
          }
        });
      });
    });
  }

  //Done
  loadRates() {
    // console.log("Now Loading the Rates")
    getTradeAndVendorId({ workorderId: this.recordId })
      .then(data => {
        const tradeId = data.tradeId;
        const vendorId = data.vendorId;

        // console.log("trader" , tradeId)
        // console.log("vendor ",vendorId)

        if (tradeId && vendorId) {
          getVTRMRecords({ tradeId: tradeId, vendorId: vendorId })
            .then(vtrmData => {
              // console.log("vtrmData " , vtrmData)
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
                const labourOptions = Object.keys(this.rates).map(rateKey => ({
                  label: rateKey,
                  value: rateKey
                }));

                this.picklistOptionsMap['Rate Type'] = labourOptions;
                this.addPicklistFlags(); // 🔄 Update fields

                // console.log("this is an option",this.options)
              }
            })
            .catch(error => {
              console.error('Error fetching VTRM records:', error);
            });

          getTripRatesfromvendor({ vendorId: vendorId })
            .then(tripData => {

              if (tripData) {
                this.tripRates = {
                  'Regular Rate': tripData.RegularTripPrice,
                  'Emergency Rate': tripData.EmergencyTripRate,
                };

                this.picklistOptionsMap['Trip Type'] = Object.keys(this.tripRates).map(rateKey => ({
                  label: rateKey,
                  value: rateKey
                }));
                this.addPicklistFlags(); // 🔄 Update fields
              }
            })
            .catch(error => {
              console.error('Error fetching Trip rates:', error);
            });
        }
      })
      .catch(error => {
        console.error('Error during trade/vendor fetch:', error);
      });
  }


  //Done
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
            autoUpdate: false,
            hide: true
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
            fieldLabel: "Net Price",
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
  //Done
  handleDiscountChange(event) {
    const selectedValue = event.detail.value;
    // console.log('Selected Discount Type:', selectedValue);


  }
  //Done
  calculateGrandTotal() {
    let total = 0;
  
    Object.keys(this.formData).forEach(typeKey => {
      const formSections = this.formData[typeKey];
  
      formSections.forEach(section => {
        section.Fields.forEach(row => {
          row.forEach(field => {
            if (
              field.fieldLabel === "Net Price" &&
              !isNaN(parseFloat(field.value))
            ) {
              total += parseFloat(field.value);
            }
          });
        });
      });
    });
  
    this.netTotal = total.toFixed(2);
  
    // Automatically update grandTotal
    if (this.selectedDiscountType === 'Flat') {
      this.totalDiscount = this.discountValue || 0;
    } else if (this.selectedDiscountType === 'Percentage') {
      this.totalDiscount = (this.netTotal * (this.discountValue || 0)) / 100;
    } else {
      this.totalDiscount = 0;
    }
  
    this.grandTotal = (this.netTotal - this.totalDiscount).toFixed(2);
  }
  



  //Done
  formatAddress(addressObj) {
    // console.log("addressObj" , addressObj)
    if (!addressObj) return '';

    const {
      street,
      city,
      state,
      postalCode,
      country
    } = addressObj;

    return [street, city, state, postalCode, country]
      .filter(part => part)
      .join(', ');
  }

  validateFormData() {
    let hasAtLeastOneValidValue = false;
    let allValuesZeroOrEmpty = true;
  
    for (const sectionType in this.formData) {
      const sections = this.formData[sectionType];
  
      for (const section of sections) {
        const sectionLabel = section.Label;
  
        for (let rowIndex = 0; rowIndex < section.Fields.length; rowIndex++) {
          const row = section.Fields[rowIndex];
  
          let rowHasValue = false;
          let rowIsComplete = true;
          let missingFields = [];
  
          for (const field of row) {
            const rawValue = field.value;
            const value = rawValue && rawValue.toString().trim();
  
            // Determine if it's a numeric field with zero value
            const isZero = field.inputType === 'number' && parseFloat(value) === 0;
  
            if (value && !isZero) {
              hasAtLeastOneValidValue = true;
              allValuesZeroOrEmpty = false;
              rowHasValue = true;
            }
  
            if (!value && field.required) {
              rowIsComplete = false;
              missingFields.push(field.fieldLabel);
            }
          }
  
          if (rowHasValue && !rowIsComplete) {
            this.dispatchEvent(new ShowToastEvent({
              title: 'Incomplete Row',
              message: `In section "${sectionLabel}", row ${rowIndex + 1}, missing fields: ${missingFields.join(', ')}`,
              variant: 'error',
            }));
            return false;
          }
        }
      }
    }
  
    // 🔴 Block if literally everything is empty or 0
    if (!hasAtLeastOneValidValue || allValuesZeroOrEmpty) {
      this.dispatchEvent(new ShowToastEvent({
        title: 'Validation Error',
        message: 'Please add some values before creating an Estimate.',
        variant: 'error',
      }));
      return false;
    }
  
    return true;
  }
  

  handleSaveClick() {
    if (!this.validateFormData()) {
      return;
    }
    console.log("jai shree ram ")

    const formattedData = {};
    const expenseIdList = [];

    console.log(expenseIdList);


    Object.keys(this.formData).forEach(sectionType => {
      formattedData[sectionType] = this.formData[sectionType].map(section => {
        if (sectionType === 'Incurred' && section.Label === 'Material') {
          section.Fields.forEach(row => {
            row.forEach(field => {
              if (field.fieldLabel === 'Id' && field.value) {
                expenseIdList.push(field.value);
              }
            });
          });
        }
        return {
          Label: section.Label,
          Fields: section.Fields.map(fieldRow =>
            fieldRow.map(field => ({
              fieldLabel: field.fieldLabel,
              value: field.value
            }))
          )
        };
      });
    });

    if (this.type === 'add') {
      updateWorkOrder({
        workOrderId: this.rec,
        assessmentTroubleshoot: this.assessmentText,
        proposalForRepairs: this.proposalText,
        internalEstimateNo: this.internalEstimateNumber
      });
    }

    deactivateExpenses({ expenseIds: expenseIdList })
      .then(() => {
        return createInvoiceRecord({
          formData: JSON.stringify(formattedData),
          workOrderId: this.rec,
          netPrice: parseFloat(this.netTotal),
          totalDiscount: parseFloat(this.totalDiscount),
          grandTotal: parseFloat(this.grandTotal),
          internalnumber: this.internalEstimateNumber,
          assesment: this.assessmentText,
          proposal: this.proposalText
        });
      })
      .then((rec) => {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Success',
          message: "Invoice created successfully!",
          variant: 'success'
        }));
        this.handleCloseModal();
        this.dispatchEvent(new CustomEvent('refreshdata'));
      })
      .catch((error) => {
        this.dispatchEvent(new ShowToastEvent({
          title: 'Error',
          message: error.body ? error.body.message : error.message,
          variant: 'error'
        }));
      });
  }
  







  handleDiscountChange(event) {
    console.log("handleDiscountChange=================================================")
    this.selectedDiscountType = event.detail.value;
    this.showDiscountValue = true;

    // Update the placeholder based on selection
    if (this.selectedDiscountType === 'Flat') {
      this.discountPlaceholder = 'Enter flat amount';
    } else if (this.selectedDiscountType === 'Percentage') {
      this.discountPlaceholder = 'Enter percentage';
    } else {
      this.discountPlaceholder = '';
      this.showDiscountValue = false;
    }

    // ✅ Recalculate grandTotal if discountValue already exists
    if (this.discountValue) {
      this.recalculateDiscount();
    }
  }

  handleDiscountValueChange(event) {
    // console.log("handleDiscountValueChange====================================")
    this.discountValue = parseFloat(event.detail.value); // Ensure it's a float

    // ✅ Recalculate whenever discount value changes
    this.recalculateDiscount();
  }

  // ✅ Extracted logic for reusability
  recalculateDiscount() {
    if (this.selectedDiscountType === 'Flat') {
      this.totalDiscount = this.discountValue;
    } else if (this.selectedDiscountType === 'Percentage') {
      this.totalDiscount = (this.netTotal * this.discountValue) / 100;
    } else {
      this.totalDiscount = 0;
    }

    this.grandTotal = this.netTotal - this.totalDiscount;

    console.log('total discount test1 :', this.totalDiscount);
    console.log('grand total test2 :', this.grandTotal);
  }
  handleRichTextChange(event) {
    const field = event.target.dataset.id;
    const rawHtml = event.target.value;
  
    // Strip HTML tags
    const plainText = rawHtml.replace(/<[^>]*>/g, '');
  
    if (field === 'assessment') {
      this.assessmentText = plainText;
      // console.log('Assessment/Troubleshoot:', this.assessmentText);
    } else if (field === 'proposal') {
      this.proposalText = plainText;
      // console.log('Proposal for Repairs:', this.proposalText);
    }
  }

  handleInternalnumber(event) {
    this.internalEstimateNumber = event.target.value;
    // console.log('Internal Estimate No:', this.internalEstimateNumber);
  }



}