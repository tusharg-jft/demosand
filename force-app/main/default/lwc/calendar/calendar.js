import { LightningElement, track } from 'lwc';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import getTrips from '@salesforce/apex/CalendarController.getTrips';
import getBrands from '@salesforce/apex/CalendarController.getBrands';
import FULLCALENDARJS from '@salesforce/resourceUrl/fullcalendar_min_js';
import FULLCALENDARCSS from '@salesforce/resourceUrl/fullcalendar_min_css';
import { NavigationMixin } from 'lightning/navigation';

export default class CalendarView extends NavigationMixin(LightningElement) {
    textValue = '';
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
        { name: 'Revisit Requested', color: 'orange' },
    ];

    @track isFilterModalOpen = false; // Main filter modal state
    @track isDateRangeModalOpen = false; // Date range modal state
    @track selectedDateFrom = '';
    @track selectedDateTo = '';
    @track selectedDateRangeLabel = 'Select Date Range'; // Default label
    @track brands = [];
    @track selectedBrand = '';
    @track paginatedTrips = [];
    @track currentPage = 1;
    @track totalPages = 0;
    tripsPerPage = 50;

    connectedCallback() {
        if (!this.calendar && this.isCalendarView) {
            Promise.all([loadScript(this, FULLCALENDARJS), loadStyle(this, FULLCALENDARCSS)])
                .then(() => this.initializeCalendar())
                .catch((error) => {
                    console.error('Error loading FullCalendar: ', error);
                });
        }
        this.fetchBrands();
        this.fetchTrips();
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

    fetchTrips() {
        getTrips({
            searchText: this.textValue || '',
            brandId: this.selectedBrand || ''
        })
        .then(data => {
            this.trips = data.map(trip => ({
                id: trip.Id,
                name: trip.Name,
                title: `${trip.Status__c}: ${trip.Name}`,
                start: trip.Date_Time_ETA__c,
                status: trip.Status__c,
               WO: trip.Work_Order__c ? trip.Work_Order__r.WorkOrderNumber : 'N/A',
                workOrderId: trip.Work_Order__c,
                brandId: trip.Brand__c,
               BR: trip.Brand__c ? trip.Brand__r.Name : 'N/A'
            }));

            // Set initial filtered trips to all trips
            this.filteredTrips = [...this.trips];

            // Initialize the calendar with the current trips
            if (this.isCalendarView) {
                this.renderCalendar();
            }
        })
        .catch(error => {
            console.error('Error fetching trips:', error);
        });
    }

    renderCalendar() {
        const calendarElement = this.template.querySelector('.calendar');
        this.calendar = new FullCalendar.Calendar(calendarElement, {
            initialView: 'dayGridMonth',
            events: this.filteredTrips.map(trip => ({
                id: trip.id,
                title: trip.title,
                start: trip.start,
                status: trip.status
            })),
            eventClick: this.handleEventClick.bind(this)
        });
        this.calendar.render();
    }

    handleEventClick(info) {
        const tripId = info.event.id;
        this.navigateToTripRecord(tripId);
    }

    navigateToTripRecord(tripId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: tripId,
                objectApiName: 'Trip__c',
                actionName: 'view'
            }
        });
    } 

    handleStatusChange(event) {
        const status = event.target.dataset.status;
        

        // Toggle the selected status
        if (event.target.checked) {
            this.selectedStatuses.push(status);
        } else {
            this.selectedStatuses = this.selectedStatuses.filter((s) => s !== status);
        }

        // Filter trips based on selected statuses
        this.filteredTrips = this.trips.filter((trip) =>
            this.selectedStatuses.length === 0 || this.selectedStatuses.includes(trip.status)
        );

        // Update calendar events if in Calendar view
        if (this.isCalendarView) {
            this.updateCalendarEvents();
        }
    }

    updateCalendarEvents() {
        // Ensure the calendar is already initialized
        if (this.calendar) {
            this.calendar.removeAllEvents(); // Remove all previous events
            // Add new events based on the filtered trips
            this.calendar.addEventSource(this.filteredTrips.map(trip => ({
                id: trip.id,
                title: trip.title,
                start: trip.start,
                status: trip.status
            })));
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

   /* handleRowClick(event) {
        const tripId = event.currentTarget.dataset.id;
        const clickedTrip = this.trips.find((trip) => trip.id === tripId);
        if (clickedTrip) {
            alert(`Trip: ${clickedTrip.title}`);
        }
    }*/

    openTrip(event) {
        const tripId = event.target.dataset.id;
        window.open(`/lightning/r/Trip__c/${tripId}/view`, '_blank');
    }

    openwo(event) {
        const workOrderId = event.target.dataset.id;
        if (workOrderId) {
            window.open(`/lightning/r/Work_Order__c/${workOrderId}/view`, '_blank');
        } else {
            alert('No Work Order associated with this Trip.');
        }
    }

    openbrand(event) {
        const brandId = event.target.dataset.id;
        if (brandId) {
            window.open(`/lightning/r/Brand__c/${brandId}/view`, '_blank');
        } else {
            alert('No Brand associated with this Trip.');
        }
    }

    handleInputChange(event) {
        this.textValue = event.detail.value.toLowerCase();
        this.fetchTrips(); // Refetch trips when input changes
    }

    /* For Filter */

    openFilterModal() {
        this.isFilterModalOpen = true;
    }

    closeFilterModal() {
        this.isFilterModalOpen = false;
    }

    openDateRangeModal() {
        this.isDateRangeModalOpen = true;
    }

    closeDateRangeModal() {
        this.isDateRangeModalOpen = false;
    }

    handleDateFromChange(event) {
        this.selectedDateFrom = event.target.value;
    }

    handleDateToChange(event) {
        this.selectedDateTo = event.target.value;
    }

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
                this.updateCalendarEvents();
            }
        }
        this.closeDateRangeModal();
    }

    applyFilters() {
        const fromDate = this.selectedDateFrom ? new Date(this.selectedDateFrom) : null;
        const toDate = this.selectedDateTo ? new Date(this.selectedDateTo) : null;

        this.filteredTrips = this.trips.filter((trip) => {
            const tripDate = new Date(trip.start);

            const matchesStatus =
                this.selectedStatuses.length === 0 ||
                this.selectedStatuses.includes(trip.status);

            const matchesDateRange =
                (!fromDate || tripDate >= fromDate) &&
                (!toDate || tripDate <= toDate);

            const matchesBrand = !this.selectedBrand || trip.brandId === this.selectedBrand;

            return matchesStatus && matchesDateRange && matchesBrand;
        });

        if (this.isCalendarView) {
            this.updateCalendarEvents(); // Update calendar with new filtered trips
        }

        this.closeFilterModal();
    }


//Pagination

getTrips() {
    // Mock data generation for 200 trips
    return Array.from({ length: 200 }, (_, index) => ({
        id: index + 1,
        name: `Trip ${index + 1}`,
        workOrderId: `WO${index + 1}`,
        WO: `WO${index + 1}`,
        status: index % 2 === 0 ? 'Scheduled' : 'Completed',
        start: new Date().toISOString().split('T')[0],
        brandId: `Brand${index % 5}`,
        BR: `Brand${index % 5}`,
    }));
}

get isPreviousDisabled() {
    return this.currentPage === 1; // Disable Previous button on the first page
}

get isNextDisabled() {
    return this.currentPage === this.totalPages; // Disable Next button on the last page
}

handlePreviousPage() {
    if (this.currentPage > 1) {
        this.currentPage--;
        this.updatePaginatedTrips(); // Update the paginated trips
    }
}

handleNextPage() {
    if (this.currentPage < this.totalPages) {
        this.currentPage++;
        this.updatePaginatedTrips(); // Update the paginated trips
    }
}

updatePaginatedTrips() {
    const startIdx = (this.currentPage - 1) * this.tripsPerPage;
    const endIdx = this.currentPage * this.tripsPerPage;
    this.paginatedTrips = this.trips.slice(startIdx, endIdx);
}

}