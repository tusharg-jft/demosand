export const currentFormData = {
"Estimate": [ 
  {
  "Label": "Labour",
"Picklist":false,
  "Fields": [
    [
      {
        "fieldLabel": "Qty",
        "required": true,
        "inputType": "number",
        "isDisabled": false,
        "track": true,
        "autoUpdate": false,
        "value": ""
      },
      {
        "fieldLabel": "Tech",
        "required": true,
        "inputType": "text",
        "isDisabled": false,
        "track": false,
        "autoUpdate": false,
        "value": ""
      },
      {
        "fieldLabel": "LabourPicklist",
        // "required": true,
        // "inputType": "text",
        "isDisabled": false,
        "track": false,
        "autoUpdate": false,
        "value": ""
      },
      
      {
        "fieldLabel": "Details",
        "required": false,
        "inputType": "text",
        "isDisabled": false,
        "track": false,
        "autoUpdate": false,
        "value": ""
      },
      {
        "fieldLabel": "Unit Price",
        "required": true,
        "inputType": "number",
        "isDisabled": false,
        "track": true,
        "autoUpdate": false,
        "value": ""
      },
      {
        "fieldLabel": "Net Price1 ($)",
        "required": false,
        "inputType": "number",
        "isDisabled": true,
        "track": false,
        "autoUpdate": true,
        "value": "",
        "className": "netPrice"
      }
    ],
  ]
}
  ,
  {
  "Label": "Trip",
  "Picklist":false,
  "Fields": [
    [
      {
        "fieldLabel": "Qty",
        "required": true,
        "inputType": "number",
        "isDisabled": false,
        "track": true,
        "autoUpdate": false,
        "value": ""
      },
      {
        "fieldLabel": "Detail",
        "required": false,
        "inputType": "text",
        "isDisabled": false,
        "track": false,
        "autoUpdate": false,
        "value": ""
      },
      {
        "fieldLabel": "Unit Price ($)",
        "required": true,
        "inputType": "number",
        "isDisabled": false,
        "track": true,
        "autoUpdate": false,
        "value": ""
      },
      {
        "fieldLabel": "Net Price ($)",
        "required": false,
        "inputType": "number",
        "isDisabled": true,
        "track": false,
        "autoUpdate": true,
        "value": "",
        "className": "netPrice"
      }
    ]
  ]
}
  ,
  {
  "Label": "Miscellaneous",
  "Picklist":false,
  "Fields": [
    [
      {
        "fieldLabel": "Qty",
        "required": true,
        "inputType": "number",
        "isDisabled": false,
        "track": true,
        "autoUpdate": false,
        "value": 0
      },
      {
        "fieldLabel": "Detail",
        "required": false,
        "inputType": "text",
        "isDisabled": false,
        "track": false,
        "autoUpdate": false,
        "value": 0
      },
      {
        "fieldLabel": "Unit Price ($)",
        "required": true,
        "inputType": "number",
        "isDisabled": false,
        "track": true,
        "autoUpdate": false,
        "value": 0
      },
      {
        "fieldLabel": "Net Price ($)",
        "required": false,
        "inputType": "number",
        "isDisabled": true,
        "track": false,
        "autoUpdate": true,
        "value": 0,
        "className": "netPrice"
      }
    ]
  ]
}
 ]

}
;