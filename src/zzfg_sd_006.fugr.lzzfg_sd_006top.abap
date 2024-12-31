FUNCTION-POOL zzfg_sd_006.                  "MESSAGE-ID ..

* INCLUDE LZZFG_SD_006D...                   " Local class definition
TYPES:BEGIN OF ty_lips,
        deliverydocument             TYPE i_deliverydocumentitem-deliverydocument,
        deliverydocumentitem         TYPE i_deliverydocumentitem-deliverydocumentitem,
        actualdeliveredqtyinbaseunit TYPE i_deliverydocumentitem-actualdeliveredqtyinbaseunit,
        batch                        TYPE i_deliverydocumentitem-batch,
        storagelocation              TYPE i_deliverydocumentitem-storagelocation,
      END OF ty_lips.
TYPES:BEGIN OF ty_data,
        deliverydocument       TYPE  i_deliverydocumentitem-deliverydocument,
        deliverydocumentitem   TYPE  i_deliverydocumentitem-deliverydocumentitem,
        storagelocation        TYPE  i_deliverydocumentitem-storagelocation,
        actualdeliveryquantity TYPE  i_deliverydocumentitem-actualdeliveryquantity,
        batch                  TYPE  i_deliverydocumentitem-batch,
        deliveryquantityunit   TYPE  i_deliverydocumentitem-baseunit,
      END OF ty_data.

TYPES:BEGIN OF ty_head,
        actualgoodsmovementdate    TYPE string,
        deliverydocumentbysupplier TYPE string,
      END OF ty_head.
"原始数据
DATA:gt_lips TYPE TABLE OF ty_lips.
"批次拆分数据
DATA:gt_lips_split TYPE TABLE OF ty_lips.
DATA:gs_head TYPE ty_head.
DATA:gs_data TYPE ty_data.
DATA:gv_deliverydocument TYPE i_deliverydocumentitem-deliverydocument.
DATA:gv_srv      TYPE string,  "服务
     gv_flowhead TYPE string,  "抬头实体
     gv_flowitem TYPE string.  "行项目实体
DATA:gv_langu TYPE string VALUE 'sap-language=zh'.
