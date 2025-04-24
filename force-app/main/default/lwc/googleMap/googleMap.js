import { LightningElement,wire,track,api } from 'lwc';

import getCompanyLocations from '@salesforce/apex/GoogleMapController.getCompanyLocations';

export default class GoogleMapLWC extends LightningElement {

    @api accountNameParam='Edge Communications';    
    @track error; 
    @track mapMarkers = [];
    @track markersTitle = 'Edge Communications';
    @track zoomLevel = 4;


    @track location  = [
        {
          location: {
            Latitude: 37.7749,
            Longitude: -122.4194
          },
          icon: 'custom:custom26',
          title: 'Edge Communications'
        },
        {
          location: {
            Latitude: 34.0522,
            Longitude: -118.2437
          },
          icon: 'custom:custom26',
          title: 'Burlington Textiles Corp of America'
        },
        {
          location: {
            Latitude: 40.7128,
            Longitude: -74.0060
          },
          icon: 'custom:custom26',
          title: 'United Oil & Gas Corp.'
        }
      ]

    @wire(getCompanyLocations, { accountNameInitial: '$accountNameParam'})
    wiredOfficeLocations({ error, data }) {
        if (data) {            
            data.forEach(dataItem => {
                this.mapMarkers = [...this.mapMarkers ,
                    {
                        location: {
                            Latitude: 51.509865,
                            Longitude: -0.118092
                          },
                        icon: 'custom:custom26',
                        title: dataItem.Name,
                    }                                    
                ];
              });            
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }
    }

}