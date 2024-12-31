@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_ZTSD_0002
  as select from    zztsd_0002           as data
    left outer join I_ProductDescription as _text  on  data.matnr     = _text.Product
                                                   and _text.Language = $session.system_language
    left outer join I_Plant              as _plant on data.werks = _plant.Plant

  association [0..1] to I_UnitOfMeasure as _UnitOfMeasure on $projection.Meins = _UnitOfMeasure.UnitOfMeasure
{
      @ObjectModel.text.element  : [ 'PlantName' ]
  key data.werks                 as Werks,
      @ObjectModel.text.element  : [ 'ProductDescription' ]
  key data.matnr                 as Matnr,
      @ObjectModel.foreignKey.association: '_UnitOfMeasure'
  key data.meins                 as Meins,
      data.price                 as Price,
      _text.ProductDescription   as ProductDescription,
      _plant.PlantName           as PlantName,
      @Semantics.user.createdBy: true
      data.created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      data.created_at            as CreatedAt,
      @Semantics.user.lastChangedBy: true
      data.last_changed_by       as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      data.last_changed_at       as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      data.local_last_changed_at as LocalLastChangedAt,
      _UnitOfMeasure
}
