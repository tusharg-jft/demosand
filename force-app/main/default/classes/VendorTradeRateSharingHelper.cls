public with sharing class VendorTradeRateSharingHelper {
    public static void shareVendorTradeRateRecord(Id tradeRateRecordId, Id corporateUserId) {
        try {
            Vendor_Trade_Rate_Management__Share shareRecord = new Vendor_Trade_Rate_Management__Share();
            shareRecord.ParentId = tradeRateRecordId;
            shareRecord.UserOrGroupId = corporateUserId;
            shareRecord.AccessLevel = 'Read';
            shareRecord.RowCause = Schema.Vendor_Trade_Rate_Management__Share.RowCause.Manual;
            
            insert shareRecord;
            System.debug('Record shared successfully with Corporate User ID: ' + corporateUserId);
        } catch (Exception e) {
            System.debug('Error sharing Vendor Trade Rate record: ' + e.getMessage());
        }
    }
}