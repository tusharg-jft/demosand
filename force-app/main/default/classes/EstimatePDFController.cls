public class EstimatePDFController {
    public Estimate__c estimate { get; private set; }
    public List<Section> EstimateBreakdown { get; private set; }
    public List<Section> IncurredBreakdown { get; private set; }

    public EstimatePDFController(ApexPages.StandardController stdCtrl) {
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

        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        for (String sectionKey : dataMap.keySet()) {
            Object sectionValue = dataMap.get(sectionKey);
            if (!(sectionValue instanceof List<Object>)) continue;

            List<Object> sectionRows = (List<Object>) sectionValue;
            List<List<Field>> fieldRows = new List<List<Field>>();

            for (Object rowObj : sectionRows) {
                Map<String, Object> rowMap = (Map<String, Object>) rowObj;
                List<Field> fieldList = new List<Field>();

                for (String fieldKey : rowMap.keySet()) {
                    fieldList.add(new Field(fieldKey, rowMap.get(fieldKey) != null ? String.valueOf(rowMap.get(fieldKey)) : ''));
                }

                fieldRows.add(fieldList);
            }

            sections.add(new Section(sectionKey, fieldRows));
        }

        return sections;
    }
}