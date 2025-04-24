import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getTrips from '@salesforce/apex/CalendarController.getTrips';
import getBrands from '@salesforce/apex/CalendarController.getBrands';
import getSites from '@salesforce/apex/CalendarController.getSites';
import getVendors from '@salesforce/apex/CalendarController.getVendors';
import getTrades from '@salesforce/apex/CalendarController.getTrades';
import FULLCALENDARJS from '@salesforce/resourceUrl/fullcalendar_min_js';
import FULLCALENDARCSS from '@salesforce/resourceUrl/fullcalendar_min_css';

export default class Calendar extends LightningElement {
    textValue = "";
    @track calendar;
    @track isCalendarView = true; // Toggle between Calendar and List view
    @track trips = [];
    @track filteredTrips = [];
    @track selectedStatuses = [];
    @track statuses = [
        { name: 'Scheduled', color: 'green' },
        { name: 'In Progress', color: 'blue' },
        { name: 'Completed', color: 'gray' },
        { name: 'Canceled', color: 'red' },
        { name: 'Return Trip Required', color: 'orange' },
    ];

    @track isFilterModalOpen = false; // Main filter modal state
    @track isDateRangeModalOpen = false; // Date range modal state
    @track selectedDateFrom = '';
    @track selectedDateTo = '';
    @track selectedDateRangeLabel = 'Select Date Range'; // Default label
    @track brands = [];
    @track sites = [];
    @track vendors = [];
    @track trades = [];
    @track selectedBrand = '';
    @track selectedSite = '';
    @track selectedVendor = '';
    @track selectedTrade = '';

    connectedCallback() {
        if (!this.calendar && this.isCalendarView) {
            Promise.all([loadScript(this, FULLCALENDARJS + '/fullcalendar.js'), loadStyle(this, FULLCALENDARCSS + '/fullcalendar.css')])
                .then(() => {this.initializeCalendar();
                    console.log('Resource LOded')
                })
                .catch((error) => {
                    console.error('Error loading FullCalendar: ', error);
                });
        }
        this.fetchBrands(); 
        this.fetchSites();
        this.fetchVendors();
        this.fetchTrades();
    }

    fetchBrands() {
        getBrands()
            .then((data) => {
                // Map the brand records to the dropdown options format
                this.brands = data.map(brand => ({
                    label: brand.Name, 
                    value: brand.Id   // Use the brand's Id
                }));
            })
            .catch((error) => {
                console.error('Error fetching brands: ', error);
            });
    }

    fetchSites() {
        getSites()
            .then((data) => {
                // Map the brand records to the dropdown options format
                this.sites = data.map(site => ({
                    label: site.Name, 
                    value: site.Id   // Use the brand's Id
                }));
            })
            .catch((error) => {
                console.error('Error fetching sites: ', error);
            });
    }

    fetchVendors() {
        getVendors()
            .then((data) => {
                // Map the brand records to the dropdown options format
                this.vendors = data.map(vendor => ({
                    label: vendor.Name, 
                    value: vendor.Id   // Use the brand's Id
                }));
            })
            .catch((error) => {
                console.error('Error fetching vendors: ', error);
            });
    }

    fetchTrades() {
        getTrades()
            .then((data) => {
                // Map the brand records to the dropdown options format
                this.trades = data.map(trade => ({
                    label: trade.Name, 
                    value: trade.Id   // Use the brand's Id
                }));
            })
            .catch((error) => {
                console.error('Error fetching trades: ', error);
            });
    }


    handleBrandChange(event) {
        this.selectedBrand = event.target.value;
      //  this.applyFilters();
    }

    handleSiteChange(event) {
        this.selectedSite = event.target.value;
    //    this.applyFilters();
    }

    handleVendorChange(event) {
        this.selectedVendor = event.target.value;
     //   this.applyFilters();
    }

    handleTradeChange(event) {
        this.selectedTrade = event.target.value;
     //   this.applyFilters();
    }

    get toggleIcon() {
        return this.isCalendarView ? 'utility:list' : 'utility:date_input';
    }
    
    
    initializeCalendar() {
        getTrips({ 
            searchText: this.textValue || '', 
            brandId: this.selectedBrand || '',
            siteId: this.selectedSite ||'',
            vendorId: this.selectedVendor ||'',
            tradeId: this.selectedTrade ||''

        })
        .then((data) => {
            this.trips = data.map((trip) => ({
                id: trip.Id,
                name: trip.Name,
                title: `${trip.Status__c}: ${trip.Name}`,
                start: trip.Date_Time_ETA__c, // Ensure format is YYYY-MM-DD
                status: trip.Status__c,
                WO: trip.Work_Order__c ? trip.Work_Order__r.WorkOrderNumber : 'N/A', 
                workOrderId: trip.Work_Order__c,
                brandId: trip.Brand__c,
                BR: trip.Brand__c ? trip.Brand__r.Name : 'N/A',
                siteId: trip.Sites__c, 
                vendorId: trip.Vendor__c, 
                tradeId: trip.Trade__c
            }));
            
            this.filteredTrips = [...this.trips];
            if (this.isCalendarView) {
                this.renderCalendar();
            }
        })
        .catch((error) => {
            console.error('Error fetching trips: ', error);
        });
    }

    renderCalendar() {
        const calendarEl = this.template.querySelector('.calendar');
        console.log('rendering');
$(calendarEl).fullCalendar();
        this.calendar = new FullCalendar.Calendar(calendarEl, {
            initialView: 'dayGridMonth',
            events: this.filteredTrips,
            eventClick: this.handleEventClick.bind(this), // Make events clickable
        });

        this.calendar.render();
    }

      handleEventClick (info)


 {
        alert(`Trip: ${info.event.title}\nDate: ${info.event.start}`);
    }

    handleStatusChange(event) {
        const status = event.target.dataset.status;

        if (event.target.checked) {
            this.selectedStatuses.push(status);
        } else {
            this.selectedStatuses = this.selectedStatuses.filter((s) => s !== status);
        }

        this.filteredTrips = this.trips.filter((trip) =>
            this.selectedStatuses.includes(trip.status)
        );

        if (this.isCalendarView) {
            this.calendar.removeAllEvents();
            this.calendar.addEventSource(this.filteredTrips);
        }
    }

    toggleView() {
        this.isCalendarView = !this.isCalendarView;

        if (this.isCalendarView) {
            Promise.all([loadScript(this, FULLCALENDARJS), loadStyle(this, FULLCALENDARCSS)])
                .then(() => this.renderCalendar())
                .catch((error) => {
                    console.error('Error loading FullCalendar: ', error);
                });
        }
    }

    handleRowClick(event) {
        const tripId = event.currentTarget.dataset.id;
        const clickedTrip = this.trips.find((trip) => trip.id === tripId);
    
        if (clickedTrip) {
            alert(`Clicked on Trip: ${clickedTrip.title}`);
        }
    }

    openTrip(event) {
        const tripId = event.target.dataset.id;
        window.open(`/lightning/r/Trip__c/${tripId}/view`, '_blank');
    }
    openwo(event) {
        const workOrderId = event.target.dataset.id;
        if(workOrderId){
        window.open(`/lightning/r/Work_Order__c/${workOrderId}/view`, '_blank'); 
    } else{
        alert('No Work Order associated with this Trip.');
    }
    }

    openbrand(event) {
        const brandId = event.target.dataset.id;
        if(brandId){
        window.open(`/lightning/r/Brand__c/${brandId}/view`, '_blank'); 
    } else{
        alert('No Brand associated with this Trip.');
    }
    }

    handleInputChange(event){
        this.textValue = event.detail.value.toLowerCase();
        this.initializeCalendar(); 
    }

    /*For Filter*/

    // Open and Close Main Filter Modal
    openFilterModal() {
        this.isFilterModalOpen = true;
    }
    closeFilterModal() {
        this.isFilterModalOpen = false;
    }

    // Open and Close Date Range Modal
    openDateRangeModal() {
        this.isDateRangeModalOpen = true;
    }
    closeDateRangeModal() {
        this.isDateRangeModalOpen = false;
    }

    // Handle Date Changes
    handleDateFromChange(event) {
        this.selectedDateFrom = event.target.value;
    }
    handleDateToChange(event) {
        this.selectedDateTo = event.target.value;
    }

    // Predefined Date Ranges
    selectToday() {
        const today = new Date().toISOString().split('T')[0];
        this.selectedDateFrom = today;
        this.selectedDateTo = today;
        this.selectedDateRangeLabel = 'Today';
    }
    selectLast7Days() {
        const today = new Date();
        const last7Days = new Date(today.setDate(today.getDate() - 7)).toISOString().split('T')[0];
        this.selectedDateFrom = last7Days;
        this.selectedDateTo = new Date().toISOString().split('T')[0];
        this.selectedDateRangeLabel = 'Last 7 Days';
    }
    selectLastWeek() {
        const today = new Date();
        const lastWeekEnd = new Date(today.setDate(today.getDate() - today.getDay() - 1)).toISOString().split('T')[0];
        const lastWeekStart = new Date(today.setDate(today.getDate() - 6)).toISOString().split('T')[0];
        this.selectedDateFrom = lastWeekStart;
        this.selectedDateTo = lastWeekEnd;
        this.selectedDateRangeLabel = 'Last Week';
    }
    selectLastMonth() {
        const now = new Date();
        const firstDayLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString().split('T')[0];
        const lastDayLastMonth = new Date(now.getFullYear(), now.getMonth(), 0).toISOString().split('T')[0];
        this.selectedDateFrom = firstDayLastMonth;
        this.selectedDateTo = lastDayLastMonth;
        this.selectedDateRangeLabel = 'Last Month';
    }
    selectLastYear() {
        const now = new Date();
        const firstDayLastYear = new Date(now.getFullYear() - 1, 0, 1).toISOString().split('T')[0];
        const lastDayLastYear = new Date(now.getFullYear() - 1, 11, 31).toISOString().split('T')[0];
        this.selectedDateFrom = firstDayLastYear;
        this.selectedDateTo = lastDayLastYear;
        this.selectedDateRangeLabel = 'Last Year';
    }

    // Apply Selected Date Range
    applyDateRange() {
        if (this.selectedDateFrom && this.selectedDateTo) {
            this.selectedDateRangeLabel = `${this.selectedDateFrom} to ${this.selectedDateTo}`;
    
            // Filter trips by date range
            this.filteredTrips = this.trips.filter((trip) => {
                const tripDate = new Date(trip.start);
                const fromDate = new Date(this.selectedDateFrom);
                const toDate = new Date(this.selectedDateTo);
                return tripDate >= fromDate && tripDate <= toDate;
            });
    
            // Update calendar if in Calendar view
            if (this.isCalendarView) {
                this.calendar.removeAllEvents();
                this.calendar.addEventSource(this.filteredTrips);
            }
        }
        this.closeDateRangeModal();
    }
    

    // Apply Filters
    applyFilters() {
        const fromDate = this.selectedDateFrom ? new Date(this.selectedDateFrom) : null;
        const toDate = this.selectedDateTo ? new Date(this.selectedDateTo) : null;
    
        // If no filters are selected, show all trips
        if (
            !this.selectedBrand && 
            !this.selectedSite && 
            !this.selectedVendor && 
            !this.selectedTrade && 
            this.selectedStatuses.length === 0 &&
            !this.selectedDateFrom && 
            !this.selectedDateTo
        ) {
            this.filteredTrips = [...this.trips];  // Show all trips
        } else {
            this.filteredTrips = this.trips.filter((trip) => {
                const tripDate = new Date(trip.start);
                
                const matchesStatus = 
                    this.selectedStatuses.length === 0 ||  
                    this.selectedStatuses.includes(trip.status); 
                
                const matchesDateRange = 
                    (!fromDate || tripDate >= fromDate) && 
                    (!toDate || tripDate <= toDate); 
    
                const matchesBrand = !this.selectedBrand || trip.brandId === this.selectedBrand;
                const matchesSite = !this.selectedSite || trip.siteId === this.selectedSite;
                const matchesVendor = !this.selectedVendor || trip.vendorId === this.selectedVendor;
                const matchesTrade = !this.selectedTrade || trip.tradeId === this.selectedTrade;
    
                return matchesStatus && matchesDateRange && matchesBrand && matchesSite && matchesVendor && matchesTrade;
            });
        }
    
        // If in Calendar View, update calendar
        if (this.isCalendarView) {
            this.calendar.removeAllEvents();  
            this.calendar.addEventSource(this.filteredTrips);  
        }
    
        // Close the filter modal after applying filters
        this.closeFilterModal();
    }
    
    
    resetFilters() {
        // Reset filter fields
        this.selectedDateRangeLabel = '';
        this.selectedBrand = '';
        this.selectedSite = '';
        this.selectedVendor = '';
        this.selectedTrade = '';
        this.selectedStatuses = [];
    
        // Show all trips
        this.filteredTrips = [...this.trips];  // Reset to all trips
    
        if (this.isCalendarView) {
            this.calendar.removeAllEvents();  
            this.calendar.addEventSource(this.filteredTrips);  
        }
    }
    
}