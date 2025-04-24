public class EditEstimateVFController {
    public Estimate__c estimate { get; private set; }
    public List<Section> EstimateBreakdown { get; private set; }
    public List<Section> IncurredBreakdown { get; private set; }

    public EditEstimateVFController(ApexPages.StandardController stdCtrl) {
        estimate = [SELECT Id, Estimate_Data__c, Incurred_Data__c FROM Estimate__c WHERE Id = :stdCtrl.getId()];
        EstimateBreakdown = parseJsonToSections(estimate.Estimate_Data__c);
        IncurredBreakdown = parseJsonToSections(estimate.Incurred_Data__c);
    }

    public class Field {
        public String fieldLabel { get; set; }
        public String value { get; set; }

        public Field(String fieldLabel, String value) {
            this.fieldLabel = fieldLabel;
            this.value = value;
        }
    }

    public class Section {
        public String label { get; set; }
        public List<List<Field>> fields { get; set; }

        public Section(String label, List<List<Field>> fields) {
            this.label = label;
            this.fields = fields;
        }
    }

    private List<Section> parseJsonToSections(String jsonString) {
        List<Section> sections = new List<Section>();
        if (String.isBlank(jsonString)) return sections;

        // Parse Estimate or Incurred from top-level
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        for (String mainKey : dataMap.keySet()) {
            if (!(dataMap.get(mainKey) instanceof List<Object>)) continue;

            List<Object> sectionList = (List<Object>) dataMap.get(mainKey);

            for (Object sectionObj : sectionList) {
                Map<String, Object> sectionMap = (Map<String, Object>) sectionObj;
                String label = (String) sectionMap.get('Label');
                List<Object> fieldsRaw = (List<Object>) sectionMap.get('Fields');

                List<List<Field>> fieldRows = new List<List<Field>>();

                for (Object rowObj : fieldsRaw) {
                    List<Object> rowList = (List<Object>) rowObj;
                    List<Field> fieldList = new List<Field>();

                    for (Object fieldObj : rowList) {
                        Map<String, Object> fieldMap = (Map<String, Object>) fieldObj;
                        String fieldLabel = (String) fieldMap.get('fieldLabel');
                        String value = fieldMap.get('value') != null ? String.valueOf(fieldMap.get('value')) : '';
                        fieldList.add(new Field(fieldLabel, value));
                    }

                    fieldRows.add(fieldList);
                }

                sections.add(new Section(label, fieldRows));
            }
        }

        return sections;
    }
}
