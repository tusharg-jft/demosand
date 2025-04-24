import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getWorkOrderLocations from '@salesforce/apex/WorkOrderMapController.getWorkOrderLocations';
import getNearbyVendors from '@salesforce/apex/WorkOrderMapController.getNearbyVendors';
import assignWorkOrder from '@salesforce/apex/WorkOrderMapController.assignWorkOrder';

export default class WorkOrderMap extends LightningElement {
    @track isLoading = true;
    @track error;
    @track workOrders = [];
    @track vendors = [];
    @track searchRadius = 50; // Default radius in km
    @track showAssignModal = false;
    @track selectedWorkOrderId;
    @track selectedVendors = [];
    @track selectedVendorId;
    @track vendorOptions = [];
    @track mapUrl = '';
    @track currentCenter = { lat: 20.5937, lng: 78.9629 }; // Default to India center
    @track currentZoom = 10;
    @track selectedWorkOrder = null;

    // Google Maps API Key
    apiKey = 'AIzaSyBc7rWNLbLfWfUjodUJZJ7CqkM1E7juh0Q';

    // When component is rendered
    renderedCallback() {
        if (this.isLoading && !this.error) {
            this.loadWorkOrders();
        }
    }

    // Load Work Orders
    async loadWorkOrders() {
        try {
            this.isLoading = true;
            this.workOrders = await getWorkOrderLocations();
            
            if (this.workOrders.length > 0) {
                // Set center to first work order
                this.currentCenter = {
                    lat: this.workOrders[0].latitude,
                    lng: this.workOrders[0].longitude
                };
                this.updateMapUrl();
            } else {
                this.error = 'No work orders found with location data.';
            }
        } catch (error) {
            this.error = error.message || 'Error loading work orders';
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Update the map URL based on current state
    updateMapUrl() {
        // Base URL for Google Maps Embed API
        let url = `https://www.google.com/maps/embed/v1/view?key=${this.apiKey}`;
        
        // Add center coordinates
        url += `&center=${this.currentCenter.lat},${this.currentCenter.lng}`;
        
        // Add zoom level
        url += `&zoom=${this.currentZoom}`;
        
        this.mapUrl = url;
    }

    // Handle work order selection
    handleWorkOrderSelect(event) {
        const workOrderId = event.target.value;
        this.selectedWorkOrder = this.workOrders.find(wo => wo.id === workOrderId);
        
        if (this.selectedWorkOrder) {
            this.currentCenter = {
                lat: this.selectedWorkOrder.latitude,
                lng: this.selectedWorkOrder.longitude
            };
            this.updateMapUrl();
        }
    }

    // Handle radius change
    handleRadiusChange(event) {
        this.searchRadius = event.target.value;
    }

    // Find nearby vendors
    async findNearbyVendors() {
        if (!this.selectedWorkOrder) {
            this.showToast('Error', 'Please select a work order first', 'error');
            return;
        }

        try {
            this.isLoading = true;
            this.selectedWorkOrderId = this.selectedWorkOrder.id;
            
            const vendors = await getNearbyVendors({ 
                workOrderId: this.selectedWorkOrderId, 
                radius: this.searchRadius 
            });

            this.vendors = vendors;

            // Prepare vendor options for assignment modal
            this.selectedVendors = vendors;
            this.vendorOptions = vendors.map(v => ({
                label: `${v.title} (${v.distance.toFixed(2)} km)`,
                value: v.id
            }));

            this.showAssignModal = true;

        } catch (error) {
            this.error = error.message || 'Error finding nearby vendors';
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Handle vendor selection
    handleVendorSelection(event) {
        this.selectedVendorId = event.detail.value;
    }

    // Handle work order assignment
    async handleAssignWorkOrder() {
        if (!this.selectedVendorId) {
            this.showToast('Error', 'Please select a vendor', 'error');
            return;
        }

        try {
            this.isLoading = true;
            await assignWorkOrder({
                workOrderId: this.selectedWorkOrderId,
                vendorId: this.selectedVendorId
            });

            this.showToast('Success', 'Work Order assigned successfully', 'success');
            this.closeAssignModal();
            this.refreshMap();

        } catch (error) {
            this.error = error.message || 'Error assigning work order';
            this.showToast('Error', this.error, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    // Close assignment modal
    closeAssignModal() {
        this.showAssignModal = false;
        this.selectedWorkOrderId = null;
        this.selectedVendorId = null;
        this.selectedVendors = [];
        this.vendorOptions = [];
    }

    // Refresh map
    refreshMap() {
        this.loadWorkOrders();
    }
    
    // View vendor on map
    viewVendorOnMap(event) {
        const vendorId = event.currentTarget.dataset.id;
        const vendor = this.vendors.find(v => v.id === vendorId);
        
        if (vendor) {
            this.currentCenter = {
                lat: vendor.latitude,
                lng: vendor.longitude
            };
            this.currentZoom = 14; // Zoom in closer to see the vendor
            this.updateMapUrl();
        }
    }

    // Show toast message
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    // Get work order options for combobox
    get workOrderOptions() {
        return this.workOrders.map(wo => ({
            label: wo.title,
            value: wo.id
        }));
    }

    // Get vendor list for display
    get hasVendors() {
        return this.vendors && this.vendors.length > 0;
    }
    
    // Check if work order is selected
    get hasSelectedWorkOrder() {
        return this.selectedWorkOrder !== null;
    }
    
    // Check if no work order is selected (for disabled attribute)
    get noWorkOrderSelected() {
        return this.selectedWorkOrder === null;
    }
}