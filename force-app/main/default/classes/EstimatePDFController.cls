public class EstimatePDFController {
    public Estimate__c estimate { get; private set; }
    public List<Section> EstimateBreakdown { get; private set; }
    public List<Section> IncurredBreakdown { get; private set; }
 public String AssessmentText { get; private set; }
public String ProposalText { get; private set; }
    
     public Work_Order__c workOrder { get; set; }
    public Vendor__c vendor { get; set; }
    public Sites__c site { get; set; }
    public Trade__c trade { get; set; }
    public Classification__c classification { get; set; }
    public Issue__c issue { get; set; }

public EstimatePDFController(ApexPages.StandardController stdCtrl) {
    estimate = [SELECT Id, Estimate_Data__c, Incurred_Data__c, Name, Work_Orders__c, Status__c, CreatedDate,
                Incurred_Cost__c, Estimated_Cost__c, totalDiscount__c, Tax__c, grandTotal__c, netPrice__c,
                Assessment_Troubleshoot__c, Proposal_For_Repairs__c
                FROM Estimate__c WHERE Id = :stdCtrl.getId()];

    // Step 2: Get the Work Order
    if (estimate.Work_Orders__c != null) {
        workOrder = [
            SELECT Id, Vendor__c, Sites__c, Trade__c, Classification__c, Issue__c
            FROM Work_Order__c
            WHERE Id = :estimate.Work_Orders__c
            LIMIT 1
        ];

        if (workOrder.Vendor__c != null) {
            vendor = [
                SELECT Id, Name, Address__c, Address__Street__s, Address__City__s,
                       Address__PostalCode__s, Email__c, Address__StateCode__s, Address__CountryCode__s
                FROM Vendor__c
                WHERE Id = :workOrder.Vendor__c
                LIMIT 1
            ];
        }

        if (workOrder.Sites__c != null) {
            site = [
                SELECT Id, Address__c, Address__Street__s, Address__City__s,
                       Address__PostalCode__s, Address__StateCode__s, Address__CountryCode__s
                FROM Sites__c
                WHERE Id = :workOrder.Sites__c
                LIMIT 1
            ];
        }

        if (workOrder.Trade__c != null) {
            trade = [
                SELECT Id, Name
                FROM Trade__c
                WHERE Id = :workOrder.Trade__c
                LIMIT 1
            ];
        }

        if (workOrder.Classification__c != null) {
            classification = [
                SELECT Id, Name
                FROM Classification__c
                WHERE Id = :workOrder.Classification__c
                LIMIT 1
            ];
        }

        if (workOrder.Issue__c != null) {
            issue = [
                SELECT Id, Name
                FROM Issue__c
                WHERE Id = :workOrder.Issue__c
                LIMIT 1
            ];
        }
    }

    // Step 3: Parse JSON into sections and filter out empty ones
EstimateBreakdown = parseJsonToSections(estimate.Estimate_Data__c, 'Estimate');


  
    IncurredBreakdown = parseJsonToSections(estimate.Estimate_Data__c, 'Incurred');
   

    // Optional: Parse Assessment & Proposal strings
    if (String.isNotBlank(estimate.Estimate_Data__c)) {
        Map<String, Object> rootMap = (Map<String, Object>) JSON.deserializeUntyped(estimate.Estimate_Data__c);
        AssessmentText = rootMap.containsKey('Assessment') ? String.valueOf(rootMap.get('Assessment')) : '';
        ProposalText = rootMap.containsKey('Proposal') ? String.valueOf(rootMap.get('Proposal')) : '';
    }
}

// Helper method to check if section has any field with value
private Boolean sectionHasValues(Section section) {
    for (List<Field> row : section.fields) {
        for (Field field : row) {
            if (String.isNotBlank(field.value)) {
                return true;
            }
        }
    }
    return false;
}


public class Field {
    public String fieldLabel { get; set; }
    public String value { get; set; }
    public Boolean isNested { get; set; }
    public List<Field> nestedFields { get; set; }

    // Constructor for simple field
    public Field(String fieldLabel, String value) {
        this.fieldLabel = fieldLabel;
        this.value = value;
        this.isNested = false;
    }

    // Constructor for nested field
    public Field(String fieldLabel, List<Field> nestedFields) {
        this.fieldLabel = fieldLabel;
        this.nestedFields = nestedFields;
        this.isNested = true;
    }
}


    public class Section {
        public String label { get; set; }
        public List<List<Field>> fields { get; set; }

        public Section(String label, List<List<Field>> fields) {
            this.label = label;
            this.fields = fields;
        }
        
        
    public Boolean getShouldRender() {
        if (fields == null) return false;

        for (List<Field> row : fields) {
            for (Field field : row) {
                if (field != null) {
                    if (!field.isNested && String.isNotBlank(field.value)) {
                        return true;
                    } else if (field.isNested && field.nestedFields != null) {
                        for (Field nested : field.nestedFields) {
                            if (nested != null && String.isNotBlank(nested.value)) {
                                return true;
                            }
                        }
                    }
                }
            }
        }
        return false;
    }
    }

   private List<Section> parseJsonToSections(String jsonString, String sectionKey) {
    List<Section> sections = new List<Section>();
    if (String.isBlank(jsonString)) return sections;

    Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

    if (!dataMap.containsKey(sectionKey)) return sections;

    List<Object> sectionList = (List<Object>) dataMap.get(sectionKey);

    for (Object sectionObj : sectionList) {
        if (!(sectionObj instanceof Map<String, Object>)) continue;

        Map<String, Object> sectionMap = (Map<String, Object>) sectionObj;
        String sectionLabel = sectionMap.containsKey('Label') ? String.valueOf(sectionMap.get('Label')) : 'Unnamed Section';

        if (!sectionMap.containsKey('Fields')) continue;

        List<Object> fieldRowsObj = (List<Object>) sectionMap.get('Fields');
        List<List<Field>> fieldRows = new List<List<Field>>();

        for (Object rowObj : fieldRowsObj) {
            if (!(rowObj instanceof List<Object>)) continue;

            List<Object> fieldObjs = (List<Object>) rowObj;
            List<Field> fieldList = new List<Field>();

            for (Object fieldObj : fieldObjs) {
                if (!(fieldObj instanceof Map<String, Object>)) continue;

                Map<String, Object> fieldMap = (Map<String, Object>) fieldObj;
                String fieldLabel = fieldMap.containsKey('fieldLabel') ? String.valueOf(fieldMap.get('fieldLabel')) : 'Section';

                // Handle nested field values
                if (fieldMap.containsKey('value') && fieldMap.get('value') instanceof List<Object>) {
                    List<Object> nestedList = (List<Object>) fieldMap.get('value');
                    List<Field> nestedFields = new List<Field>();

                    for (Object nested : nestedList) {
                        if (nested instanceof Map<String, Object>) {
                            Map<String, Object> nestedMap = (Map<String, Object>) nested;
                            String nestedLabel = nestedMap.containsKey('fieldLabel') ? String.valueOf(nestedMap.get('fieldLabel')) : 'Nested Label';
                            String nestedValue = nestedMap.containsKey('value') ? String.valueOf(nestedMap.get('value')) : '';
                            nestedFields.add(new Field(nestedLabel, nestedValue));
                        }
                    }

                    fieldList.add(new Field(fieldLabel, nestedFields));
                } else {
                    String value = fieldMap.containsKey('value') ? String.valueOf(fieldMap.get('value')) : '';
                    fieldList.add(new Field(fieldLabel, value));
                }
            }

            fieldRows.add(fieldList);
        }

        sections.add(new Section(sectionLabel, fieldRows));
    }

    return sections;
}

}