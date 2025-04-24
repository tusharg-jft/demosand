import LightningDatatable from 'lightning/datatable';
import addEditButtonVersionOneTemplate from './addEditButtonVersionOne.html';
import editUpsertButtonTemplate from './editUpsertButton.html';

export default class CustomEstimateDatatable extends LightningDatatable {
    static customTypes = {
        submitApprovalButton: {
            template: addEditButtonVersionOneTemplate,
            standardCellLayout: true,
            typeAttributes: ['row']
        },
        editEstimateButton: {
            template: editUpsertButtonTemplate,
            standardCellLayout: true,
            typeAttributes: ['row']
        }
    };
}
