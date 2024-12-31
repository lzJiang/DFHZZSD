FUNCTION-POOL zzfg_sd_003.                  "MESSAGE-ID ..

* INCLUDE LZZFG_SD_003D...                   " Local class definition
TYPES:BEGIN OF ty_data,
        deliverydocument       TYPE  i_deliverydocumentitem-deliverydocument,
        deliverydocumentitem   TYPE  i_deliverydocumentitem-deliverydocumentitem,
        salesdocument          TYPE  i_salesdocumentitem-salesdocument,
        salesdocumentitem      TYPE  i_salesdocumentitem-salesdocumentitem,
        storagelocation        TYPE  i_deliverydocumentitem-storagelocation,
        actualdeliveryquantity TYPE  i_deliverydocumentitem-actualdeliveryquantity,
        batch                  TYPE  i_deliverydocumentitem-batch,
        deliveryquantityunit   TYPE  i_deliverydocumentitem-baseunit,
      END OF ty_data.
TYPES:BEGIN OF ty_create,
        referencesddocument     TYPE i_deliverydocumentitem-deliverydocument,
        referencesddocumentitem TYPE i_deliverydocumentitem-deliverydocumentitem,
        actualdeliveryquantity  TYPE i_deliverydocumentitem-actualdeliveryquantity,
        deliveryquantityunit    TYPE i_deliverydocumentitem-deliveryquantityunit,
      END OF ty_create.
TYPES:BEGIN OF ty_head,
        actualgoodsmovementdate    TYPE string,
        deliverydocumentbysupplier TYPE string,
      END OF ty_head.


DATA:gv_deliverydocument TYPE i_deliverydocument-deliverydocument.
DATA:gv_salesdocument    TYPE i_salesdocument-salesdocument.
DATA:gv_sddocumentcategory TYPE i_deliverydocument-sddocumentcategory.
DATA:gs_data TYPE ty_data.
DATA:gt_create TYPE TABLE OF ty_create.
DATA:gs_head TYPE ty_head.


DATA:gv_srv      TYPE string,  "服务
     gv_flowhead TYPE string,  "抬头实体
     gv_flowitem TYPE string.  "行项目实体
DATA:gv_langu TYPE string VALUE 'sap-language=zh'.
