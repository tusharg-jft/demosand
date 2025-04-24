public with sharing class WorkOrderVendorAssignmentController {
  /**
   * Fetches active vendors associated with the trade of a work order with their approval status
   * @param workOrderId - Id of the Work Order
   * @return List of VendorWrapper records with vendor details and approval status
   */
  @AuraEnabled(cacheable=true)
public static List<VendorWrapper> getActiveVendorsForWorkOrder(Id workOrderId) {
    try {
        // Get the Trade__c from the Work Order
        Work_Order__c workOrder = [
            SELECT Id, Trade__c, Sites__c, Sites__r.CorpUser__c, Status__c
            FROM Work_Order__c
            WHERE Id = :workOrderId
            LIMIT 1
        ];

        if (workOrder.Trade__c == null) {
            return new List<VendorWrapper>();
        }

        // Get active vendors associated with the trade
        List<Vendor__c> vendors = [
            SELECT Id, Name, Status__c, User__c, User__r.Id, IsActive__c
            FROM Vendor__c
            WHERE
                Id IN (
                    SELECT Vendor__c
                    FROM TradeVendor__c
                    WHERE Trade__c = :workOrder.Trade__c
                )
                AND IsActive__c = TRUE
            ORDER BY Name
        ];

        // Get existing VendorWO__c records for this work order
        Map<Id, VendorWO__c> vendorWOMap = new Map<Id, VendorWO__c>();
        for (VendorWO__c vendorWO : [
            SELECT Id, Vendor__c, Status__c
            FROM VendorWO__c
            WHERE Related_Work_Order__c = :workOrderId
        ]) {
            vendorWOMap.put(vendorWO.Vendor__c, vendorWO);
        }

        // Create wrapper objects with vendor details and approval status
        List<VendorWrapper> wrappers = new List<VendorWrapper>();
        for (Vendor__c vendor : vendors) {
            VendorWrapper wrapper = new VendorWrapper();
            wrapper.Id = vendor.Id;
            wrapper.Name = vendor.Name;
            wrapper.Status = vendor.Status__c;
            wrapper.UserId = vendor.User__c;

            // Set ApprovalStatus using the same logic as getPrioritizedVendorsForWorkOrder
            if (vendorWOMap.containsKey(vendor.Id)) {
                String vwoStatus = vendorWOMap.get(vendor.Id).Status__c;
                if (vwoStatus == 'Pending') {
                    wrapper.ApprovalStatus = 'Pending';
                } else if (vwoStatus == 'Approved') {
                    wrapper.ApprovalStatus = 'Approved';
                } else if (vwoStatus == 'Rejected') {
                    wrapper.ApprovalStatus = 'Active';
                } else {
                    wrapper.ApprovalStatus = 'Active';
                }
            } else {
                wrapper.ApprovalStatus = 'Active';
            }

            wrappers.add(wrapper);
        }

        return wrappers;
    } catch (Exception e) {
        throw new AuraHandledException('Error fetching vendors: ' + e.getMessage());
    }
}
  /**
   * Wrapper class for vendor information including approval status
   */
  public class VendorWrapper {
    @AuraEnabled
    public Id Id;
    @AuraEnabled
    public String Name;
    @AuraEnabled
    public String Status;
    @AuraEnabled
    public String ApprovalStatus;
    @AuraEnabled
    public Id UserId;
  }

  /**
   * Creates child work orders for selected vendors and sends notifications
   * @param workOrderId - Id of the Work Order
   * @param vendorIds - List of Ids of selected Vendors
   * @return String - Success or error message
   */
  @AuraEnabled
  public static String assignVendorToWorkOrder(
    Id workOrderId,
    List<Id> vendorIds
  ) {
    try {
      System.debug(
        'assignVendorToWorkOrder called with workOrderId: ' +
          workOrderId +
          ' and vendorIds: ' +
          vendorIds
      );

      if (vendorIds == null || vendorIds.isEmpty()) {
        System.debug('No vendors selected for assignment');
        return 'Please select at least one vendor.';
      }

      // Get the parent Work Order with all necessary fields
      Work_Order__c parentWorkOrder;
      try {
        parentWorkOrder = [
          SELECT
            Id,
            Trade__c,
            Sites__c,
            Sites__r.CorpUser__c,
            Status__c,
            WorkOrderNumber__c,
            Description__c,
            Select__c,
            Original_ETA__c,
            Classification__c,
            Issue__c,
            NTE__c,
            Original_NTE__c,
            Request_By_Person__c
          FROM Work_Order__c
          WHERE Id = :workOrderId
          LIMIT 1
        ];
        System.debug('Retrieved parent work order: ' + parentWorkOrder);
      } catch (Exception e) {
        System.debug('Error retrieving parent work order: ' + e.getMessage());
        throw new AuraHandledException(
          'Could not find work order with ID: ' + workOrderId
        );
      }

      // Get all vendors being assigned
      List<Vendor__c> vendors;
      try {
        vendors = [
          SELECT Id, Name, User__c
          FROM Vendor__c
          WHERE Id IN :vendorIds
        ];
        System.debug('Retrieved vendors: ' + vendors);
      } catch (Exception e) {
        System.debug('Error retrieving vendors: ' + e.getMessage());
        throw new AuraHandledException('Could not retrieve vendor information');
      }

      if (vendors.isEmpty()) {
        System.debug('No valid vendors found for the provided IDs');
        return 'No valid vendors found for the provided IDs.';
      }

      // Create child work orders for each vendor
      List<Work_Order__c> childWorkOrders = new List<Work_Order__c>();
      List<VendorWO__c> vendorWOs = new List<VendorWO__c>();
      Map<Id, Id> vendorToChildWOMap = new Map<Id, Id>();

      Id recordTypeId = [
                SELECT Id 
                FROM RecordType 
                WHERE DeveloperName = 'Child_Work_Order' 
                  AND SObjectType = 'Work_Order__c' 
                LIMIT 1
            ].Id;

      System.debug('Creating child work orders and vendor WO records');
      for (Vendor__c vendor : vendors) {
        // Create child work order
        Work_Order__c child = new Work_Order__c(
            RecordTypeId = recordTypeId,
          ParentWO__c = parentWorkOrder.Id,
          Vendor__c = vendor.Id,
          Trade__c = parentWorkOrder.Trade__c,
          Sites__c = parentWorkOrder.Sites__c,
          Description__c = parentWorkOrder.Description__c,
          Select__c = parentWorkOrder.Select__c,
          Original_ETA__c = parentWorkOrder.Original_ETA__c,
          Classification__c = parentWorkOrder.Classification__c,
          Issue__c = parentWorkOrder.Issue__c,
          NTE__c = parentWorkOrder.NTE__c,
          Original_NTE__c = parentWorkOrder.Original_NTE__c,
          Request_By_Person__c = parentWorkOrder.Request_By_Person__c,
          Status__c = 'Pending Vendor Approval',
          Work_Order_Type__c = 'Child'
        );
        childWorkOrders.add(child);
        System.debug('Created child work order for vendor: ' + vendor.Name);
      }

      System.debug(
        'Inserting ' + childWorkOrders.size() + ' child work orders'
      );

      // Insert child work orders first to get their IDs
      if (!childWorkOrders.isEmpty()) {
        insert childWorkOrders;

        // Create mapping of vendor to child work order
        for (Work_Order__c child : childWorkOrders) {
          vendorToChildWOMap.put(child.Vendor__c, child.Id);
        }

        System.debug('vendorToChildWOMap==' + vendorToChildWOMap);

        // Create VendorWO__c records with the child work order IDs
        for (Vendor__c vendor : vendors) {
          System.debug(
            'vendorToChildWOMap==' + vendorToChildWOMap.get(vendor.Id)
          );

          VendorWO__c vendorWO = new VendorWO__c(
            Related_Work_Order__c = vendorToChildWOMap.get(vendor.Id),
            Vendor__c = vendor.Id,
            Trade__c = parentWorkOrder.Trade__c,
            Status__c = 'Pending'
          );
          vendorWOs.add(vendorWO);
          System.debug('Created VendorWO record for vendor: ' + vendor.Name);
        }
      }

      // Insert all records
      try {
        System.debug('Inserting ' + vendorWOs.size() + ' vendor WO records');
        insert vendorWOs;
      } catch (Exception e) {
        System.debug('Error inserting records: ' + e.getMessage());
        throw new AuraHandledException(
          'Error creating vendor assignments: ' + e.getMessage()
        );
      }

      // Update parent work order status
      try {
        parentWorkOrder.Status__c = 'Assigned to Vendors';
        update parentWorkOrder;
        System.debug(
          'Updated parent work order status to: ' + parentWorkOrder.Status__c
        );
      } catch (Exception e) {
        System.debug('Error updating parent work order: ' + e.getMessage());
        // Continue despite this error as the main operation succeeded
      }

      // Grant access and send notifications for each vendor
      System.debug('Processing vendor notifications');
      for (Vendor__c vendor : vendors) {
        if (vendor.User__c != null) {
          try {
            grantReadAccessToVendor(vendorToChildWOMap.get(vendor.Id), vendor.Id);
            System.debug('Granted access to vendor: ' + vendor.Name);
          } catch (Exception e) {
            System.debug(
              'Error granting access to vendor ' +
                vendor.Name +
                ': ' +
                e.getMessage()
            );
          }

          try {
            sendNotifications(
             vendorToChildWOMap.get(vendor.Id),
              vendor.Id,
              parentWorkOrder.Sites__r.CorpUser__c
            );
            System.debug('Sent notification to vendor: ' + vendor.Name);
          } catch (Exception e) {
            System.debug(
              'Error sending notification to vendor ' +
                vendor.Name +
                ': ' +
                e.getMessage()
            );
          }
        }
      }

      String result =
        'Successfully assigned ' +
        vendors.size() +
        ' vendors.';
      System.debug('assignVendorToWorkOrder completed successfully: ' + result);
      return result;
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error assigning vendors: ' + e.getMessage()
      );
    }
  }

  /**
   * Grants read-only access to the Work Order for vendor users
   * @param workOrderId - Id of the Work Order
   * @param vendorId - Id of the selected Vendor
   */
  private static void grantReadAccessToVendor(Id workOrderId, Id vendorId) {
    try {
      // Get the User Ids associated with the vendors
      List<Vendor__c> vendors = [
        SELECT Id, User__c
        FROM Vendor__c
        WHERE Id = :vendorId AND User__c != NULL
      ];

      List<Id> userIds = new List<Id>();
      for (Vendor__c vendor : vendors) {
        if (vendor.User__c != null) {
          userIds.add(vendor.User__c);
        }
      }

      if (!userIds.isEmpty()) {
        // Create sharing records for the Work Order
        List<Work_Order__Share> shareRecords = new List<Work_Order__Share>();

        for (Id userId : userIds) {
          Work_Order__Share share = new Work_Order__Share();
          share.ParentId = workOrderId;
          share.UserOrGroupId = userId;
          share.AccessLevel = 'Read';
          share.RowCause = Schema.Work_Order__Share.RowCause.Manual;
          shareRecords.add(share);
        }

        if (!shareRecords.isEmpty()) {
          insert shareRecords;
        }
      }
    } catch (Exception e) {
      System.debug('Error granting access: ' + e.getMessage());
      // We don't want to throw an exception here as it would roll back the vendor assignment
    }
  }

  /**
   * Sends notifications to vendor users and corporate user
   * @param workOrderId - Id of the Work Order
   * @param vendorId - Id of the selected Vendor
   * @param corporateUserId - Id of the corporate user
   */
  public static void sendNotifications(
    Id workOrderId,
    Id vendorId,
    Id corporateUserId
  ) {
    System.debug('workOrderId: ' + workOrderId);
    System.debug('vendorId: ' + vendorId);
    System.debug('corporateUserId: ' + corporateUserId);
    try {
      // Get the Work Order details for the notification
      Work_Order__c workOrder = [
        SELECT Id, Name, WorkOrderNumber__c
        FROM Work_Order__c
        WHERE Id = :workOrderId
        LIMIT 1
      ];
      System.debug(workOrder);
      // Get the User Ids associated with the vendors
      List<Vendor__c> vendors = [
        SELECT Id, Name, User__c
        FROM Vendor__c
        WHERE Id = :vendorId AND User__c != NULL
      ];
      System.debug('vendors: ' + vendors);
      // Create a set of user Ids to notify
      Set<Id> userIdsToNotify = new Set<Id>();

      // Add vendor users to the notification list
      for (Vendor__c vendor : vendors) {
        if (vendor.User__c != null) {
          userIdsToNotify.add(vendor.User__c);
        }
      }

      // Add corporate user to the notification list if available
      if (corporateUserId != null) {
        userIdsToNotify.add(corporateUserId);
      }

      if (!userIdsToNotify.isEmpty()) {
        // Get the notification type
        // CustomNotificationType notificationType = [
        //   SELECT Id, DeveloperName
        //   FROM CustomNotificationType
        //   WHERE DeveloperName = 'WOAssignTOVendorNotification'
        //   LIMIT 1
        // ];

        // Create and send the notification
        // Messaging.CustomNotification notification = new Messaging.CustomNotification();
        // notification.setTitle('Work Order Assignment');
        // notification.setBody(
        //   'Work Order ' +
        //     workOrder.WorkOrderNumber__c +
        //     ' has been assigned to a vendor.'
        // );
        // notification.setNotificationTypeId(notificationType.Id);
        // notification.setTargetId(workOrderId);
        // notification.send(userIdsToNotify);


        // Send the notification using the NotificationUtility class


        NotificationUtility.sendNotification(
                'WOAssignTOVendorNotification',
                new List<Id>(userIdsToNotify),
                workOrder.Id,
                'Work Order ' + workOrder.WorkOrderNumber__c + ' has been assigned to a vendor.',
                'Work Order Assignment'
            );

      }
    } catch (Exception e) {
      System.debug('Error sending notifications: ' + e.getMessage());
      // We don't want to throw an exception here as it would roll back the vendor assignment
    }
  }

  /**
   * Checks if the work order is available for vendor assignment
   * @param workOrderId - Id of the Work Order
   * @return Boolean - True if the work order is available for assignment
   */
  @AuraEnabled(cacheable=true)
  public static Boolean isWorkOrderAvailableForAssignment(Id workOrderId) {
    try {
      // Get the Work Order status
      Work_Order__c workOrder = [
        SELECT Id, Status__c
        FROM Work_Order__c
        WHERE Id = :workOrderId
        LIMIT 1
      ];

      // Check if the work order has any existing VendorWO__c records
      Integer vendorWOCount = [
        SELECT COUNT()
        FROM VendorWO__c
        WHERE Work_Order__c = :workOrderId
      ];

      // Work order is available for assignment if:
      // 1. It has no existing VendorWO__c records, or
      // 2. Its status is 'Active'
      return (vendorWOCount == 0 || workOrder.Status__c == 'Active');
    } catch (Exception e) {
      throw new AuraHandledException(
        'Error checking work order status: ' + e.getMessage()
      );
    }
  }

  /**
   * Fetches only the preferred vendors (primary, secondary, tertiary) for a work order
   * based on the work order's trade and site, with priority labels appended to their names.
   * @param workOrderId - Id of the Work Order
   * @return List of VendorWrapper records for preferred vendors only
   */
  /**
   * Fetches preferred vendors (exactly one Primary, Secondary, Tertiary) for a work order
   * based on trade and site, with priority labels appended to their names.
   * Each vendor is stored in a separate Preferred_Trade_Vendor__c record with PreferredType__c.
   * @param workOrderId - Id of the Work Order
   * @return List of VendorWrapper records for preferred vendors only
   */
  @AuraEnabled(cacheable=true)
  public static List<VendorWrapper> getPrioritizedVendorsForWorkOrder(Id workOrderId) {
      try {
          // Get only the necessary fields from the Work Order
          Work_Order__c workOrder = [
              SELECT Trade__c, Sites__c
              FROM Work_Order__c
              WHERE Id = :workOrderId
              LIMIT 1
          ];
  
          if (workOrder.Trade__c == null || workOrder.Sites__c == null) {
              return new List<VendorWrapper>();
          }
  
          // Step 1: Fetch all preferred vendors for the trade and site
          List<Preferred_Trade_Vendor__c> preferredVendors = [
              SELECT Vendor__c, Approval_Status__c, PreferredType__c
              FROM Preferred_Trade_Vendor__c
              WHERE Trade__c = :workOrder.Trade__c
                AND Sites__c = :workOrder.Sites__c
                AND Vendor__c != NULL
                AND PreferredType__c IN ('Primary', 'Secondary', 'Tertiary')
                AND Vendor__r.IsActive__c = TRUE
          ];
          
          // If no preferred vendors, return empty list
          if (preferredVendors.isEmpty()) {
              return new List<VendorWrapper>();
          }
  
          // Step 2: Map preferred vendors by their PreferredType__c for ordering
          Map<String, Preferred_Trade_Vendor__c> priorityMap = new Map<String, Preferred_Trade_Vendor__c>();
          for (Preferred_Trade_Vendor__c pref : preferredVendors) {
              priorityMap.put(pref.PreferredType__c, pref);
          }
  
          // Step 3: Build the list in explicit order: Primary, Secondary, Tertiary
          List<Id> preferredVendorIds = new List<Id>();
          Map<Id, String> vendorApprovalStatus = new Map<Id, String>();
          Map<Id, String> vendorPriorityLabel = new Map<Id, String>();
  
          // Process in fixed order
          for (String priority : new List<String>{ 'Primary', 'Secondary', 'Tertiary' }) {
              if (priorityMap.containsKey(priority)) {
                  Preferred_Trade_Vendor__c pref = priorityMap.get(priority);
                  preferredVendorIds.add(pref.Vendor__c);
                  vendorApprovalStatus.put(pref.Vendor__c, 'Active');
                  vendorPriorityLabel.put(pref.Vendor__c, ' (' + pref.PreferredType__c + ')');
              }
          }
          
          // Step 4: Query VendorWO__c records based on the work order and vendor IDs
          List<VendorWO__c> vendorWOs = [
              SELECT Vendor__c, Status__c 
              FROM VendorWO__c 
              WHERE Related_Work_Order__c = :workOrderId 
                AND Vendor__c IN :preferredVendorIds
          ];
          Map<Id, VendorWO__c> vendorWOMap = new Map<Id, VendorWO__c>();
          for (VendorWO__c vwo : vendorWOs) {
              vendorWOMap.put(vwo.Vendor__c, vwo);
          }
  
          // Step 5: Fetch vendor details for the preferred vendor IDs
          List<Vendor__c> preferredVendorRecords = [
              SELECT Id, Name, Status__c, User__c, User__r.Id, IsActive__c
              FROM Vendor__c
              WHERE Id IN :preferredVendorIds 
                AND IsActive__c = TRUE
          ];
  
          // Step 6: Create wrapper objects in the order of preferredVendorIds
          List<VendorWrapper> wrappers = new List<VendorWrapper>();
          for (Id vendorId : preferredVendorIds) {
              for (Vendor__c vendor : preferredVendorRecords) {
                  if (vendor.Id == vendorId) {
                      VendorWrapper wrapper = new VendorWrapper();
                      wrapper.Id = vendor.Id;
                      wrapper.Name = vendor.Name +
                          (vendorPriorityLabel.containsKey(vendor.Id) ? vendorPriorityLabel.get(vendor.Id) : '');
                      wrapper.UserId = vendor.User__c;
                      
                      // Set Status based on VendorWO__c.Status__c
                      if (vendorWOMap.containsKey(vendor.Id)) {
                          String vwoStatus = vendorWOMap.get(vendor.Id).Status__c;
                          if (vwoStatus == 'Pending') {
                              wrapper.Status = 'Pending';
                          } else if (vwoStatus == 'Approved') {
                              wrapper.Status = 'Approved';
                          } else {
                              wrapper.Status = 'Active'; // For 'Rejected' or any other value
                          }
                      } else {
                          wrapper.Status = 'Active'; // No VendorWO__c record found
                      }
                      
                      // Keep ApprovalStatus as it was (from Preferred_Trade_Vendor__c or VendorWO__c)
                      if (vendorWOMap.containsKey(vendor.Id)) {
                          String vwoStatus = vendorWOMap.get(vendor.Id).Status__c;
                          if (vwoStatus == 'Pending') {
                              wrapper.ApprovalStatus = 'Pending';
                          } else if (vwoStatus == 'Approved') {
                              wrapper.ApprovalStatus = 'Approved';
                          } else if (vwoStatus == 'Rejected') {
                              wrapper.ApprovalStatus = 'Active';
                          } else {
                              wrapper.ApprovalStatus = vendorApprovalStatus.containsKey(vendor.Id) 
                                  ? vendorApprovalStatus.get(vendor.Id) 
                                  : '';
                          }
                      } else {
                          wrapper.ApprovalStatus = vendorApprovalStatus.containsKey(vendor.Id) 
                              ? vendorApprovalStatus.get(vendor.Id) 
                              : '';
                      }
                      
                      wrappers.add(wrapper);
                      break;
                  }
              }
          }
  
          return wrappers;
      } catch (Exception e) {
          throw new AuraHandledException('Error fetching prioritized vendors: ' + e.getMessage());
      }
  }
}