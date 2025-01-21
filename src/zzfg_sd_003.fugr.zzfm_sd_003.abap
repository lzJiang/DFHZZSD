FUNCTION zzfm_sd_003.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI003_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .
  DATA:lt_sub TYPE zzt_sdi003_in.
  DATA(lt_tmp) = i_req-req-item.

  READ TABLE lt_tmp INTO DATA(ls_tmp) INDEX 1.
  gv_salesdocument = ls_tmp-referencesddocument.
  gv_salesdocument = |{ gv_salesdocument ALPHA = IN }|.

  LOOP AT lt_tmp ASSIGNING FIELD-SYMBOL(<fs_tmp>).
    <fs_tmp>-referencesddocument = |{ <fs_tmp>-referencesddocument ALPHA = IN }|.
  ENDLOOP.

  "获取销售订单类型
  SELECT a~salesdocument,
         a~salesdocumentitem,
         a~sddocumentcategory,
         a~orderquantityunit,
         a~baseunit,
         a~product,
         a~ordertobasequantitydnmntr,
         a~ordertobasequantitynmrtr
    FROM i_salesdocumentitem WITH PRIVILEGED ACCESS AS a
   WHERE a~salesdocument = @gv_salesdocument
    INTO TABLE @DATA(lt_salesdocumentitem).
  READ TABLE lt_salesdocumentitem INTO DATA(ls_salesdocumentitem) INDEX 1.
  gv_sddocumentcategory = ls_salesdocumentitem-sddocumentcategory.
  IF sy-subrc = 0.
    CASE gv_sddocumentcategory.
      WHEN 'C'."标准外向交货
        gv_srv = 'API_OUTBOUND_DELIVERY_SRV'.
        gv_flowhead = 'A_OutbDeliveryHeader'.
        gv_flowitem = 'A_OutbDeliveryItem'.
      WHEN 'H'."客户退货
        gv_srv = 'API_CUSTOMER_RETURNS_DELIVERY_SRV'.
        gv_flowhead = 'A_ReturnsDeliveryHeader'.
        gv_flowitem = 'A_ReturnsDeliveryItem'.
    ENDCASE.
  ELSE.

    SELECT a~purchaseorder AS salesdocument,
           a~purchaseorderitem AS salesdocumentitem,
           a~purchaseordercategory AS sddocumentcategory,
           a~purchaseorderquantityunit AS orderquantityunit,
           a~baseunit,
           a~material AS product,
           a~orderitemqtytobaseqtynmrtr AS ordertobasequantitydnmntr,
           a~orderitemqtytobaseqtydnmntr AS ordertobasequantitynmrtr
      FROM i_purchaseorderitemapi01 WITH PRIVILEGED ACCESS AS a
     WHERE a~purchaseorder = @gv_salesdocument
      INTO TABLE @lt_salesdocumentitem.
    IF sy-subrc = 0.
      READ TABLE lt_salesdocumentitem INTO ls_salesdocumentitem INDEX 1.
      gv_sddocumentcategory = ls_salesdocumentitem-sddocumentcategory.
      CASE gv_sddocumentcategory.
        WHEN 'F'."标准外向交货
          gv_srv = 'API_OUTBOUND_DELIVERY_SRV'.
          gv_flowhead = 'A_OutbDeliveryHeader'.
          gv_flowitem = 'A_OutbDeliveryItem'.
      ENDCASE.
    ELSE.
      o_resp-msgty = 'E'.
      o_resp-msgtx = '订单不存在！'.
    ENDIF.
  ENDIF.


  DATA(lt_item) = i_req-req-item.
  "单位转换
  SELECT b~salesdocument,
         b~salesdocumentitem,
         a~unitofmeasurecommercialname
    FROM i_unitofmeasurecommercialname WITH PRIVILEGED ACCESS AS a
    JOIN @lt_salesdocumentitem AS b ON a~unitofmeasure = b~baseunit
   WHERE a~language = 1
     INTO TABLE @DATA(lt_unit).
  DATA: lv_input  TYPE p DECIMALS 3,
        lv_result TYPE p DECIMALS 3.

  LOOP AT lt_item ASSIGNING FIELD-SYMBOL(<fs_item>).
    READ TABLE lt_unit INTO DATA(ls_unit) WITH KEY salesdocumentitem = <fs_item>-referencesddocumentitem.
    IF ls_unit-unitofmeasurecommercialname <> <fs_item>-deliveryquantityunit.
      lv_input = <fs_item>-actualdeliveryquantity.
      READ TABLE lt_salesdocumentitem INTO ls_salesdocumentitem WITH KEY salesdocumentitem = <fs_item>-referencesddocumentitem.

      SELECT SINGLE a~quantitynumerator,a~quantitydenominator
        FROM i_productunitsofmeasure WITH PRIVILEGED ACCESS AS a
        JOIN i_unitofmeasurecommercialname WITH PRIVILEGED ACCESS as b ON a~AlternativeUnit = b~UnitOfMeasure
                                                                      AND b~language = 1
       WHERE product = @ls_salesdocumentitem-product
         AND unitofmeasurecommercialname = @<fs_item>-deliveryquantityunit
        INTO @DATA(ls_measure).

      lv_result = lv_input * ls_measure-quantitynumerator / ls_measure-quantitydenominator.
      <fs_item>-actualdeliveryquantity =  lv_result.

      <fs_item>-deliveryquantityunit = ls_unit-unitofmeasurecommercialname.
    ENDIF.
  ENDLOOP.


  "合并数量
  SELECT a~referencesddocument,
         a~referencesddocumentitem,
    SUM( a~actualdeliveryquantity ) AS actualdeliveryquantity,
        a~deliveryquantityunit
  FROM @lt_item AS a
  GROUP BY a~referencesddocument,a~referencesddocumentitem,a~deliveryquantityunit
  INTO TABLE @gt_create.
  "创建交货单
  CALL FUNCTION 'ZZFM_SD_003_CREATE'
    IMPORTING
      o_resp = o_resp.
  CHECK o_resp-msgty <> 'E'.

  "获取已创建的交货单
  SELECT deliverydocument,
         deliverydocumentitem,
         referencesddocument,
         referencesddocumentitem
    FROM i_deliverydocumentitem WITH PRIVILEGED ACCESS
   WHERE referencesddocument = @gv_salesdocument
     AND goodsmovementstatus = 'A'
    INTO TABLE @DATA(lt_lips).

  "更新交货单
  LOOP AT lt_tmp INTO ls_tmp GROUP BY ( referencesddocumentitem = ls_tmp-referencesddocumentitem
                                        count = GROUP SIZE ) INTO DATA(ls_group).
    IF ls_group-count <> 1.
      LOOP AT GROUP ls_group INTO DATA(ls_sub).
        APPEND ls_sub TO lt_sub.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  SORT lt_sub BY referencesddocumentitem.
  DELETE ADJACENT DUPLICATES FROM lt_sub COMPARING referencesddocumentitem.

  LOOP AT lt_tmp INTO ls_tmp .
    CLEAR:gs_data.
    READ TABLE lt_lips INTO DATA(ls_lips) WITH KEY referencesddocument     = ls_tmp-referencesddocument
                                                   referencesddocumentitem = ls_tmp-referencesddocumentitem.
    IF sy-subrc = 0.
      gs_data-deliverydocument = ls_lips-deliverydocument.
      gs_data-deliverydocumentitem = ls_lips-deliverydocumentitem.
      gs_data-salesdocument = ls_lips-referencesddocument.
      gs_data-salesdocumentitem = ls_lips-referencesddocumentitem.
    ENDIF.

    gs_data-actualdeliveryquantity = ls_tmp-actualdeliveryquantity.
    gs_data-deliveryquantityunit = ls_tmp-deliveryquantityunit.
    gs_data-storagelocation = ls_tmp-storagelocation.
    gs_data-batch = ls_tmp-batch.
    "批次拆分
    READ TABLE lt_sub TRANSPORTING NO FIELDS WITH KEY referencesddocumentitem = ls_tmp-referencesddocumentitem  BINARY SEARCH.
    IF sy-subrc = 0.
      "批次拆分行，先拆批次，再更改库存地点
      CALL FUNCTION 'ZZFM_SD_003_SPLIT'
        IMPORTING
          o_resp = o_resp.
    ELSE.
      "非批次拆分行，先直接更改批次,库存地点
      CALL FUNCTION 'ZZFM_SD_003_UPDATE'
        IMPORTING
          o_resp = o_resp.
    ENDIF.

    IF o_resp-msgty = 'E'.
      EXIT.
    ENDIF.
  ENDLOOP.

  "创建的交货单可能会存在多个
  DATA(lt_lips_tmp) = lt_lips.
  SORT lt_lips_tmp BY deliverydocument.
  DELETE ADJACENT DUPLICATES FROM lt_lips_tmp COMPARING deliverydocument.

  LOOP AT lt_lips_tmp INTO DATA(ls_lips_tmp).
    CLEAR:gs_head.
    gv_deliverydocument = ls_lips_tmp-deliverydocument.
    "更新抬头日期
    gs_head-actualgoodsmovementdate = i_req-req-head-actualgoodsmovementdate.
    gs_head-deliverydocumentbysupplier = i_req-req-head-deliverydocumentbysupplier.
    IF gs_head IS NOT INITIAL.
      gs_head-actualgoodsmovementdate = zzcl_comm_tool=>date2iso( gs_head-actualgoodsmovementdate ).
      CALL FUNCTION 'ZZFM_SD_003_HEAD'
        IMPORTING
          o_resp = o_resp.
    ENDIF.

    IF o_resp-msgty = 'E'.
      CALL FUNCTION 'ZZFM_SD_003_DELETE'.
      CONTINUE.
    ENDIF.
    "交货单过账
    CALL FUNCTION 'ZZFM_SD_003_POST'
      IMPORTING
        o_resp = o_resp.

    IF o_resp-msgty = 'E'.
      CALL FUNCTION 'ZZFM_SD_003_DELETE'.
    ELSE.
      o_resp-sapnum = |{ o_resp-sapnum }/{ gv_deliverydocument }|.
    ENDIF.

  ENDLOOP.

  IF o_resp-sapnum  IS NOT INITIAL.
    o_resp-sapnum  = o_resp-sapnum+1.
  ENDIF.


ENDFUNCTION.
