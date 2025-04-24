/**
 * @description Handles mapping between Salesforce SObjects and Service Channel API JSON structures.
 */
public with sharing class ServiceChannelMapper {

    // --- Inbound Mapping (SC JSON -> SF Object Fields) ---

    /**
     * @description Maps incoming Service Channel Work Order data to Case fields.
     * @param woData The 'Object' part of the SC webhook payload for WorkOrderCreated/Changed.
     * @param targetWorkOrder The Work_Order__c record to populate (can be new or existing).
     * @param corporateId The ID of the related Corporate__c record.
     * @param siteId The ID of the related Sites__c record.
     * @return Work_Order__c The populated Work Order record.
     * @note Uses actual field names like External_WO_ID__c, Corporate__c, Sites__c, NTE__c, Status__c, Trade__c, Estimate_Time_of_Arrival__c.
     */
public static Work_Order__c mapWorkOrderToSF(Map<String, Object> woData, Work_Order__c targetWorkOrder, Id corporateId, Id siteId) {
    System.debug('Mapping SC Work Order to Work_Order__c. Data: ' + JSON.serializePretty(woData));
    
    if (targetWorkOrder == null) targetWorkOrder = new Work_Order__c();


    // description: serviceTicket.Description,
    //   priority: priority?.fmi_priority,
    //   createdBy: 'SYSTEM USER SERVICE CHANNEL',
    //   etaStart: serviceTicket.ScheduledDate
    //     ? new Date(serviceTicket.ScheduledDate).toISOString()
    //     : null,
    //   tenantId: store.tenantId,
    //   nte: Number(serviceTicket.Nte),
    //   originalNte: Number(serviceTicket.Nte),
    //   type: TICKET_TYPE.ORDER,
    //   external_type: EXTERNAL_SERVICE_TYPE.SC,
    //   store: store,
      
    
    // Required relationships
    // targetWorkOrder.Corporate__c = corporateId; // Uncommented - critical for linking to Corporate__c
    // targetWorkOrder.Sites__c = siteId; // Already correct
    
    // Basic fields from payload
    targetWorkOrder.External_WO_ID__c = String.valueOf(woData.get('Id')); // e.g., "309152940"
   // targetWorkOrder.Work_Order_Number__c = (String) woData.get('Number'); // e.g., "WEB-3274522" (assuming this field exists)
    targetWorkOrder.Description__c = (String) woData.get('Description'); // e.g., "Test JMA 11:34"
    targetWorkOrder.External_WO_Provider__c = 'Service Channel'; // Static value
    targetWorkOrder.Sites__c = siteId;

    // Handle NTE
    Object nteValue = woData.get('Nte');
    if (nteValue != null) {
        if (nteValue instanceOf Decimal) {
            targetWorkOrder.NTE__c = (Decimal) nteValue;
            if (targetWorkOrder.Id == null) targetWorkOrder.Original_NTE__c = (Decimal) nteValue;
        } else if (nteValue instanceOf Integer) {
            targetWorkOrder.NTE__c = (Decimal) nteValue;
            if (targetWorkOrder.Id == null) targetWorkOrder.Original_NTE__c = (Decimal) nteValue;
        } else if (nteValue instanceOf String && String.isNotBlank((String) nteValue)) {
            try {
                Decimal parsedNte = Decimal.valueOf((String) nteValue);
                targetWorkOrder.NTE__c = parsedNte;
                if (targetWorkOrder.Id == null) targetWorkOrder.Original_NTE__c = parsedNte;
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Could not parse NTE value: ' + nteValue + '. Error: ' + e.getMessage());
            }
        }
    }

    // Handle Status (adjust for nested Status object in your JSON)
    // Map<String, Object> statusObj = (Map<String, Object>) woData.get('Status');
    // if (statusObj != null && statusObj.containsKey('Primary')) {
    //     String scStatus = (String) statusObj.get('Primary'); // e.g., "IN PROGRESS"
    //     if (targetWorkOrder.Id == null) { // Only set initial status for new records
    //         targetWorkOrder.Status__c = mapStatus(scStatus, true);
    //     }
    // } else {
    //     System.debug(LoggingLevel.WARN, 'Status object missing or invalid in woData: ' + JSON.serialize(woData));
    //     if (targetWorkOrder.Id == null) targetWorkOrder.Status__c = 'New'; // Default for new records
    // }


    // Handle Trade

    // Handle Scheduled Date (ETA)
    String scheduledDateStr = (String) woData.get('ScheduledDate'); // e.g., "2025-04-02T20:34:48Z"
    if (String.isNotBlank(scheduledDateStr)) {
        try {
            Datetime scheduledDt = Datetime.valueOfGmt(scheduledDateStr.replace('T', ' ').replace('Z', ''));
        //    targetWorkOrder.Estimate_Time_of_Arrival__c = scheduledDt;
            if (targetWorkOrder.Id == null) targetWorkOrder.Original_ETA__c = scheduledDt;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to parse ScheduledDate: ' + scheduledDateStr + '. Error: ' + e.getMessage());
        }
    }

    // Add Name field if required (Salesforce often requires a Name field for custom objects)
    if (targetWorkOrder.Id == null && String.isBlank(targetWorkOrder.Name)) {
     //   targetWorkOrder.Name = 'WO-' + targetWorkOrder.External_WO_ID__c; // e.g., "WO-309152940"
    }

    System.debug('Mapped Work_Order__c: ' + JSON.serializePretty(targetWorkOrder));
    return targetWorkOrder;
}

    /**
     * @description Maps incoming Service Channel Note data to CaseComment fields.
     * @param noteData The 'Object' part of the SC webhook payload for WorkOrderNoteAdded.
     * @param parentWorkOrderId The ID of the parent Work_Order__c record.
     * @return CaseComment The populated CaseComment record.
     * @note Assumes CaseComment is used for notes related to Work_Order__c.
     * @note Assumes existence of custom field ServiceChannel_Note_ID__c on CaseComment.
     */
    public static CaseComment mapNoteToCaseComment(Map<String, Object> noteData, Id parentWorkOrderId) {
         System.debug('Mapping SC Note to CaseComment...');
         CaseComment newComment = new CaseComment();
         newComment.ParentId = parentWorkOrderId; // Relate to Work_Order__c
         newComment.CommentBody = (String)noteData.get('NoteData');
         newComment.IsPublished = true; // Defaulting to published
         // TODO: Verify if ServiceChannel_Note_ID__c field exists on CaseComment. Commenting out for now.
         // newComment.ServiceChannel_Note_ID__c = String.valueOf(noteData.get('Id')); // Assumed custom field (External ID)
         
         // Attempt to parse and store original creation date if needed (requires custom field)
         String dateCreatedStr = (String)noteData.get('DateCreated');
         if (String.isNotBlank(dateCreatedStr)) {
             try {
                 // newComment.Original_Created_Date__c = Datetime.valueOfGmt(dateCreatedStr.replace('T', ' ')); // Assumed custom field
             } catch (Exception e) {
                  System.debug(LoggingLevel.WARN, 'Failed to parse Note DateCreated: ' + dateCreatedStr);
             }
         }

         return newComment;
    }

    // --- Outbound Mapping (SF Object -> SC JSON Payload) ---

    /**
     * @description Maps a Salesforce CaseComment to the Service Channel Note format for POSTing.
     * @param comment The CaseComment record.
     * @param mailsTo Optional email address for the 'MailedTo' field.
     * @return Map<String, Object> Payload ready for JSON serialization.
     * @note Based on NestJS CommentMapper. Assumes 'mailsTo' is not directly available on CaseComment, might need context.
     */
    public static Map<String, Object> mapCommentToSCNote(CaseComment comment, String mailsTo) {
        System.debug('Mapping CaseComment to SC Note payload for Comment ID: ' + comment.Id);
        Map<String, Object> notePayload = new Map<String, Object>();
        notePayload.put('Note', comment.CommentBody); // Field name from NestJS mapper
        notePayload.put('ActionRequired', false); // Defaulting based on NestJS mapper
        
        // Handle recipients if provided
        if (String.isNotBlank(mailsTo)) {
             notePayload.put('MailedTo', new List<String>{ mailsTo });
        } else {
             notePayload.put('MailedTo', new List<String>()); // Send empty list if none specified
        }
        
        // Add other required fields based on SC API documentation for adding notes
        // e.g., notePayload.put('Visibility', 'Public'); 
        // e.g., notePayload.put('DateCreated', comment.CreatedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')); 

        System.debug('SC Note Payload: ' + JSON.serialize(notePayload));
        return notePayload;
    }
    
    /**
     * @description Maps Salesforce Trip Check-In data (likely from Trip__c or related) to the Service Channel format.
     * @param checkInData Map containing check-in details from Salesforce (e.g., technicianName, checkInTime, checkInLat, checkInLong, numberTechnician).
     * @return Map<String, Object> Payload ready for JSON serialization.
     * @note Based on NestJS TripCheckInMapper.
     */
    public static Map<String, Object> mapTripCheckInToSC(Map<String, Object> checkInData) {
         System.debug('Mapping Trip Check-In to SC payload. Data: ' + JSON.serialize(checkInData));
         Map<String, Object> scPayload = new Map<String, Object>();
         
         scPayload.put('WorkTypeId', '1'); // Hardcoded based on NestJS mapper
         scPayload.put('TechsCount', checkInData.containsKey('numberTechnician') ? String.valueOf(checkInData.get('numberTechnician')) : '1');
         scPayload.put('Latitude', checkInData.containsKey('checkInLat') ? String.valueOf(checkInData.get('checkInLat')) : '');
         scPayload.put('Longitude', checkInData.containsKey('checkInLong') ? String.valueOf(checkInData.get('checkInLong')) : '');
         
         if (checkInData.get('checkInTime') instanceOf Datetime) {
             scPayload.put('CheckInTime', ((Datetime)checkInData.get('checkInTime')).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
         } else {
              System.debug(LoggingLevel.ERROR, 'Invalid CheckInTime format for Trip Check-In mapping.');
              // Handle error or default value
         }

         System.debug('SC CheckIn Payload: ' + JSON.serialize(scPayload));
         return scPayload;
    }
    
    /**
     * @description Maps Salesforce Trip Check-Out data (likely from Trip__c or related) to the Service Channel format.
     * @param checkOutData Map containing check-out details from Salesforce (e.g., checkOutTime, additionalInformation, checkOutLat, checkOutLong).
     * @return Map<String, Object> Payload ready for JSON serialization.
     * @note Based on NestJS TripCheckOutMapper.
     */
     public static Map<String, Object> mapTripCheckOutToSC(Map<String, Object> checkOutData) {
         System.debug('Mapping Trip Check-Out to SC payload. Data: ' + JSON.serialize(checkOutData));
         Map<String, Object> scPayload = new Map<String, Object>();

         scPayload.put('WorkTypeId', '1'); // Hardcoded based on NestJS mapper
         scPayload.put('PrimaryStatus', 'InProgress'); // Hardcoded based on NestJS mapper
         scPayload.put('ActionStatus', 'Complete'); // Hardcoded based on NestJS mapper
         scPayload.put('Resolution', (String)checkOutData.get('additionalInformation'));
         scPayload.put('Latitude', checkOutData.containsKey('checkOutLat') ? String.valueOf(checkOutData.get('checkOutLat')) : '');
         scPayload.put('Longitude', checkOutData.containsKey('checkOutLong') ? String.valueOf(checkOutData.get('checkOutLong')) : '');

         if (checkOutData.get('checkOutTime') instanceOf Datetime) {
             scPayload.put('CheckOutTime', ((Datetime)checkOutData.get('checkOutTime')).formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));
         } else {
              System.debug(LoggingLevel.ERROR, 'Invalid CheckOutTime format for Trip Check-Out mapping.');
              // Handle error or default value
         }

         System.debug('SC CheckOut Payload: ' + JSON.serialize(scPayload));
         return scPayload;
     }

    /**
     * @description Maps a Salesforce Invoice__c record and its lines to the Service Channel Invoice format.
     * @param invoice The Invoice__c record (queried with line items).
     * @param workOrderId The corresponding Service Channel Work Order ID (External_WO_ID__c).
     * @return Map<String, Object> Payload ready for JSON serialization.
     * @note Assumes Invoice__c object with fields like Name, Tax_Amount__c, Total_Amount__c, Description__c.
     * @note Assumes related list Invoice_Line_Items__r on Invoice__c for Invoice_Line_Item__c object.
     * @note Assumes Invoice_Line_Item__c has fields like Type__c (Picklist: Labor, Material, Trip, Misc, Shipping), Description__c, Quantity__c, Unit_Price__c, Total_Price__c.
     * @note Based on NestJS formatItems logic.
     */
    public static Map<String, Object> mapInvoiceToSC(Invoice__c invoice, String workOrderId) {
        System.debug('Mapping Invoice to SC payload for Invoice ID: ' + invoice.Id);
        Map<String, Object> invoicePayload = new Map<String, Object>();
        
        invoicePayload.put('InvoiceNumber', invoice.Name); // Assumed field for Invoice Number
        invoicePayload.put('WoIdentifier', workOrderId);
        invoicePayload.put('InvoiceTax', invoice.Tax_Amount__c); // Assumed custom field
        invoicePayload.put('InvoiceTotal', invoice.Total_Amount__c); // Assumed custom field
        invoicePayload.put('InvoiceText', invoice.Description__c); // Assumed custom field

        // --- Process Line Items ---
        List<Map<String, Object>> labors = new List<Map<String, Object>>();
        List<Map<String, Object>> materials = new List<Map<String, Object>>();
        List<Map<String, Object>> others = new List<Map<String, Object>>();
        Decimal laborTotal = 0;
        Decimal materialTotal = 0;
        Decimal otherTotal = 0;

        // TODO: Verify Invoice_Line_Items__r relationship name, Invoice_Line_Item__c object/fields existence and accessibility.
        // Commenting out line item processing loop due to compilation errors.
        /*
        // Check if related list exists and is not null before iterating
        if (invoice.Invoice_Line_Items__r != null) { // Assumed related list name
            for (Invoice_Line_Item__c line : invoice.Invoice_Line_Items__r) {
                Map<String, Object> formattedLine = new Map<String, Object>();
                formattedLine.put('Amount', line.Total_Price__c); // Common field

                if (line.Type__c == 'Labor') { // Assumed Type__c picklist field
                    formattedLine.put('SkillLevel', 2); // Default from NestJS
                    formattedLine.put('LaborType', 1); // Default from NestJS
                    formattedLine.put('NumOfTech', 1); // Default from NestJS, adjust if available on line item
                    formattedLine.put('Hours', line.Quantity__c != null ? line.Quantity__c.setScale(2) : 0); // Assumed Quantity__c field
                    formattedLine.put('HourlyRate', line.Unit_Price__c != null ? line.Unit_Price__c.setScale(2) : 0); // Assumed Unit_Price__c field
                    labors.add(formattedLine);
                    laborTotal += line.Total_Price__c != null ? line.Total_Price__c : 0;
                } else if (line.Type__c == 'Material') {
                    formattedLine.put('NumOfTech', 1); // Default from NestJS
                    formattedLine.put('PartNum', ' '); // Default from NestJS
                    formattedLine.put('UnitType', 1); // Default from NestJS
                    formattedLine.put('UnitPrice', line.Unit_Price__c != null ? line.Unit_Price__c.setScale(2) : 0);
                    formattedLine.put('Quantity', line.Quantity__c != null ? line.Quantity__c.setScale(2) : 0);
                    formattedLine.put('Description', String.isNotBlank(line.Description__c) ? line.Description__c : ''); // Assumed Description__c field
                    materials.add(formattedLine);
                    materialTotal += line.Total_Price__c != null ? line.Total_Price__c : 0;
                } else { // Trip, Misc, Shipping etc. fall into 'Other'
                    formattedLine.put('Description', String.isNotBlank(line.Description__c) ? line.Description__c : '');
                    others.add(formattedLine);
                    otherTotal += line.Total_Price__c != null ? line.Total_Price__c : 0;
                }
            }
        } else {
             System.debug(LoggingLevel.WARN, 'No Invoice Line Items found for Invoice ID: ' + invoice.Id);
        }
        */

        invoicePayload.put('InvoiceAmountsDetails', new Map<String, Object>{
            'LaborAmount' => laborTotal,
            'MaterialAmount' => materialTotal,
            'OtherAmount' => otherTotal
        });
        invoicePayload.put('Labors', labors);
        invoicePayload.put('Materials', materials);
        invoicePayload.put('Others', others);

        return invoicePayload;
    }

    // --- Value Mapping Helpers ---

    /**
     * @description Maps Service Channel Priority string to Salesforce Work_Order__c Priority__c picklist value.
     * @param scPriority Priority string from Service Channel.
     * @return String Salesforce Work Order Priority value (e.g., 'High', 'Medium', 'Low').
     * @note Attempts to use Custom Metadata 'Priority_Mapping__mdt' first, falls back to hardcoded map.
     * @note Assumes Priority_Mapping__mdt has fields SC_Priority_Name__c (Text) and FMI_Priority__c (Text).
     * @note Assumes a custom field Priority__c exists on Work_Order__c.
     */
    public static String mapPriority(String scPriority) {
        if (String.isBlank(scPriority)) return 'Medium'; // Default if blank

        // 1. Try Custom Metadata
        // Ensure Priority_Mapping__mdt exists and has SC_Priority_Name__c and FMI_Priority__c fields
        /*
        try {
            List<Priority_Mapping__mdt> mappings = [SELECT FMI_Priority__c 
                                                    FROM Priority_Mapping__mdt 
                                                    WHERE SC_Priority_Name__c = :scPriority 
                                                    LIMIT 1];
            if (!mappings.isEmpty() && String.isNotBlank(mappings[0].FMI_Priority__c)) {
                return mappings[0].FMI_Priority__c;
            }
        } catch (QueryException e) {
             System.debug(LoggingLevel.WARN, 'Could not query Priority_Mapping__mdt. Ensure object and fields exist and are accessible. Error: ' + e.getMessage());
        }
        */

        // 2. Fallback to hardcoded map (based on NestJS PRIORITY_MAPPING logic if applicable)
        // This map should align with the GetPriorityFMI logic if possible
        Map<String, String> priorityMap = new Map<String, String>{
            'Emergency' => 'High', // Example - adjust based on actual SC values and desired SF mapping
            'Urgent' => 'High',
            'Standard' => 'Medium',
            'Next Available' => 'Medium',
            'Low' => 'Low',
            'Safety' => 'High' // Example
            // Add all relevant SC priority strings and their SF equivalents
        };
        String sfPriority = priorityMap.get(scPriority);
        
        System.debug('Mapped SC Priority "' + scPriority + '" to SF Priority "' + (sfPriority != null ? sfPriority : 'Medium (Default)') + '"');
        return String.isNotBlank(sfPriority) ? sfPriority : 'Medium'; // Default if no map found
    }

    /**
     * @description Maps Service Channel Status string to Salesforce Work_Order__c Status__c picklist value.
     * @param scStatus Status string from Service Channel.
     * @param isInitial True if mapping for a new Work Order, false for status update. Allows different initial mapping if needed.
     * @return String Salesforce Work Order Status value (e.g., 'New', 'In Progress', 'Closed').
     * @note Attempts to use Custom Metadata 'Status_Mapping__mdt' first, falls back to hardcoded map.
     * @note Assumes Status_Mapping__mdt has fields SC_Status_Name__c (Text) and SF_Status_Name__c (Text).
     */
    public static String mapStatus(String scStatus, Boolean isInitial) {
        if (String.isBlank(scStatus)) return null; // Don't change status if SC status is blank/null

        // 1. Try Custom Metadata
        // Ensure Status_Mapping__mdt exists and has SC_Status_Name__c and SF_Status_Name__c fields
        /*
        try {
            List<Status_Mapping__mdt> mappings = [SELECT SF_Status_Name__c 
                                                  FROM Status_Mapping__mdt 
                                                  WHERE SC_Status_Name__c = :scStatus.toUpperCase() // Assuming SC status stored uppercase in metadata
                                                  LIMIT 1];
            if (!mappings.isEmpty() && String.isNotBlank(mappings[0].SF_Status_Name__c)) {
                 System.debug('Mapped SC Status "' + scStatus + '" to SF Status "' + mappings[0].SF_Status_Name__c + '" via Metadata');
                return mappings[0].SF_Status_Name__c;
            }
        } catch (QueryException e) {
             System.debug(LoggingLevel.WARN, 'Could not query Status_Mapping__mdt. Ensure object and fields exist and are accessible. Error: ' + e.getMessage());
        }
        */

        // 2. Fallback to hardcoded map
        Map<String, String> statusMap = new Map<String, String>{
            'OPEN' => 'New', 
            'IN PROGRESS' => 'In Progress', // Assuming 'In Progress' exists in SF Status__c picklist
            'COMPLETED' => 'Closed', // Assuming 'Closed' exists
            'CANCELLED' => 'Cancelled', // Assuming 'Cancelled' exists
            'ON HOLD' => 'On Hold' // Assuming 'On Hold' exists
            // Add all relevant SC statuses and their SF equivalents
        };
        String sfStatus = statusMap.get(scStatus.toUpperCase()); // Use uppercase for case-insensitive matching

        System.debug('Mapped SC Status "' + scStatus + '" to SF Status "' + (sfStatus != null ? sfStatus : 'null (No Mapping Found)') + '" via Hardcoded Map');
        
        // If it's an initial mapping and no specific map found, default to 'New'
        if (isInitial && sfStatus == null) {
            return 'New'; // Default initial status
        }
        
        return sfStatus; // Return null if no mapping found for status updates (prevents accidental overwrites)
    }
    
    /**
     * @description Maps Service Channel Trade/Classification string to a Salesforce Work_Order__c Trade__c field value.
     * @param scTrade Trade string from Service Channel.
     * @return String Salesforce value (likely an Id if Trade__c is a lookup, or text if it's text/picklist).
     * @note Attempts to use Custom Metadata 'Trade_Mapping__mdt' first, falls back to pass-through (if Trade__c is text) or null (if lookup).
     * @note Assumes Trade_Mapping__mdt has fields SC_Trade_Name__c (Text) and SF_Trade_Name__c (Text/Lookup ID). Adjust SF field type as needed.
     */
    public static String mapTrade(String scTrade) {
         if (String.isBlank(scTrade)) return null;

         // 1. Try Custom Metadata
         // Ensure Trade_Mapping__mdt exists and has SC_Trade_Name__c and SF_Trade_Name__c fields
         /*
         try {
             List<Trade_Mapping__mdt> mappings = [SELECT SF_Trade_Name__c // Or SF_Trade_ID__c if lookup
                                                  FROM Trade_Mapping__mdt 
                                                  WHERE SC_Trade_Name__c = :scTrade 
                                                  LIMIT 1];
             if (!mappings.isEmpty() && String.isNotBlank(mappings[0].SF_Trade_Name__c)) {
                 System.debug('Mapped SC Trade "' + scTrade + '" to SF Trade "' + mappings[0].SF_Trade_Name__c + '" via Metadata');
                 return mappings[0].SF_Trade_Name__c; // Return Name or ID based on SF_Trade_Name__c field type
             }
         } catch (QueryException e) {
              System.debug(LoggingLevel.WARN, 'Could not query Trade_Mapping__mdt. Ensure object and fields exist and are accessible. Error: ' + e.getMessage());
         }
         */

         // 2. Fallback: If Trade__c on Work_Order__c is a Text field, pass through. If it's a Lookup, return null as we can't guess the ID.
         // Assuming Trade__c is a Lookup for this example, returning null on fallback. Adjust if it's Text.
         System.debug('No mapping found for SC Trade "' + scTrade + '". Returning null (assuming Trade__c is Lookup).');
         return null; // Or return scTrade; if Trade__c is a Text field
    }

}