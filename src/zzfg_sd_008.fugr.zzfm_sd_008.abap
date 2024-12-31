FUNCTION zzfm_sd_008.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REQ) TYPE  ZZS_SDI003_REQ OPTIONAL
*"  EXPORTING
*"     REFERENCE(O_RESP) TYPE  ZZS_REST_OUT
*"----------------------------------------------------------------------
  .
  DATA(ls_tmp) = i_req-req.


  "创建交货单
  DATA:lt_create  TYPE TABLE FOR ACTION IMPORT i_customerreturnsdeliverytp~createdlvfromsalesdocument.
  APPEND INITIAL LINE TO lt_create ASSIGNING FIELD-SYMBOL(<fs_create>).
  <fs_create>-%param = VALUE #( %control =  VALUE #( shippingpoint = if_abap_behv=>mk-on )
                                shippingpoint = '1010'
                                _referencesddocumentitem = VALUE #(
                                  FOR ls_item  IN ls_tmp-item
                                      (  %control = VALUE #( referencesddocument = if_abap_behv=>mk-on
                                                             referencesddocumentitem = if_abap_behv=>mk-on )
                                         referencesddocument = |{ ls_item-referencesddocument ALPHA = IN }|
                                         referencesddocumentitem = ls_item-referencesddocumentitem  )
                                       )    ).

  MODIFY ENTITIES OF i_customerreturnsdeliverytp
   ENTITY customerreturnsdelivery
   EXECUTE createdlvfromsalesdocument AUTO FILL CID WITH lt_create
   MAPPED DATA(ls_mapped)
   REPORTED DATA(ls_reported)
   FAILED DATA(ls_failed).
  IF ls_failed IS NOT INITIAL.
    ROLLBACK ENTITIES.
    DATA(lv_msg) = zzcl_comm_tool=>get_bo_msg( is_reported = ls_reported iv_component = 'CUSTOMERRETURNSDELIVERY' ).

    o_resp-msgty = 'E'.
    o_resp-msgtx = |交货单创建失败：{ lv_msg }|.
    RETURN.
  ELSE.
    DATA: ls_temporary_key TYPE STRUCTURE FOR KEY OF i_customerreturnsdeliverytp.
    COMMIT ENTITIES BEGIN
    RESPONSE OF i_customerreturnsdeliverytp
    FAILED DATA(ls_failed_save)
    REPORTED DATA(ls_reported_save).
    CONVERT KEY OF i_customerreturnsdeliverytp FROM ls_temporary_key TO DATA(ls_final_key).
    COMMIT ENTITIES END.
  ENDIF.




  MODIFY ENTITIES OF i_customerreturnsdeliverytp
   ENTITY customerreturnsdeliveryitem
   UPDATE
   FIELDS ( actualdeliveredqtyinorderunit orderquantityunit )
   WITH VALUE #( ( actualdeliveredqtyinorderunit = '7'
   orderquantityunit = 'L'
   %tky-customerreturndelivery = '0080000001'
   %tky-customerreturndeliveryitem = '000010' ) )
   FAILED DATA(ls_failed_upd)
   REPORTED DATA(ls_reported_upd).


ENDFUNCTION.
