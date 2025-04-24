import getInvoicesBasedOnWorkOrder from '@salesforce/apex/InvoiceController.getInvoicesBasedOnWorkOrder';
import { LightningElement, api, wire, track } from 'lwc';

export default class CorporateBrandInvoicelist extends LightningElement {
    @api recordId;
    @track invoices = [];
    @track filteredInvoices = [];

    @track selectedVendor = 'All';
    @track selectedStatus = 'All';

    vendorOptions = [{ label: 'All', value: 'All' }];
    statusOptions = [{ label: 'All', value: 'All' }];
    columns = [
        {
            type: 'button',
            label: 'Invoice Name',
            fieldName: 'name',
            typeAttributes: {
                label: { fieldName: 'name' },
                name: 'view_invoice',
                variant: 'base'
            }
        },
        {
            label: 'Work Order',
            fieldName: 'workOrderUrl',
            type: 'url',
            typeAttributes: { label: { fieldName: 'workOrderName' }, target: '_blank' }
        },
        {
            label: 'Vendor',
            fieldName: 'vendorName',
            type: 'text'
        },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Net Total', fieldName: 'netTotal', type: 'currency' },
        { label: 'Total Discount', fieldName: 'totalDiscount', type: 'currency' },
        { label: 'Grand Total', fieldName: 'grandTotal', type: 'currency' }
    ];
    

    @wire(getInvoicesBasedOnWorkOrder, { workOrderId: '$recordId' })
    wiredInvoices({ error, data }) {
        console.log('📦 Wired call triggered with recordId:', this.recordId);
        if (data) {
            console.log('✅ Data received from Apex:', data);

            this.invoices = data.map(inv => ({
                ...inv,
               invoiceUrl: `/apex/NewInvoicePDFPage?id=${inv.invoiceId}`,
    workOrderUrl: `/lightning/r/Work_Order__c/${inv.workOrderId}/view`
            }));

            this.filteredInvoices = this.invoices;
            this.buildFilterOptions(this.invoices);
        } else if (error) {
            console.error('❌ Error fetching invoices:', error);
        }
    }


    @track showModal = false;
@track selectedInvoiceUrl = '';

handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;

    if (actionName === 'view_invoice') {
        this.selectedInvoiceUrl = `/apex/NewInvoicePDFPage?id=${row.invoiceId}`;
        this.showModal = true;
    }
}

closeModal() {
    this.showModal = false;
}


    buildFilterOptions(data) {
        const vendorSet = new Set();
        const statusSet = new Set();

        console.log('🔍 Building filter options from data...');
        data.forEach(inv => {
            console.log('🧾 Processing invoice:', inv);
            if (inv.vendorName && inv.vendorName !== '') {
                vendorSet.add(inv.vendorName);
            }
            if (inv.status) {
                statusSet.add(inv.status);
            }
        });

        this.vendorOptions = [{ label: 'All', value: 'All' }, ...[...vendorSet].map(v => ({ label: v, value: v }))];
        this.statusOptions = [{ label: 'All', value: 'All' }, ...[...statusSet].map(s => ({ label: s, value: s }))];

        console.log('✅ Vendor options:', this.vendorOptions);
        console.log('✅ Status options:', this.statusOptions);
    }

    handleVendorChange(event) {
        this.selectedVendor = event.detail.value;
        console.log('🔁 Vendor filter changed to:', this.selectedVendor);
        this.applyFilters();
    }

    handleStatusChange(event) {
        this.selectedStatus = event.detail.value;
        console.log('🔁 Status filter changed to:', this.selectedStatus);
        this.applyFilters();
    }

    applyFilters() {
        console.log('🔍 Applying filters...');
        console.log('Current selectedVendor:', this.selectedVendor);
        console.log('Current selectedStatus:', this.selectedStatus);

        this.filteredInvoices = this.invoices.filter(inv => {
            const matchesVendor = this.selectedVendor === 'All' || inv.vendorName === this.selectedVendor;
            const matchesStatus = this.selectedStatus === 'All' || inv.status === this.selectedStatus;
            const keep = matchesVendor && matchesStatus;
            console.log(`🧪 Invoice: ${inv.name}, Vendor Match: ${matchesVendor}, Status Match: ${matchesStatus}, Keep: ${keep}`);
            return keep;
        });

        console.log('✅ Filtered invoices:', this.filteredInvoices);
    }
}