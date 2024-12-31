@Metadata.allowExtensions: true
@EndUserText.label: '###GENERATED Core Data Service Entity'
@AccessControl.authorizationCheck: #CHECK
define root view entity ZC_ZTSD_0002
  provider contract transactional_query
  as projection on ZR_ZTSD_0002
{
  key Werks,
  key Matnr,
  key Meins,
  Price,
  PlantName,
  ProductDescription,
  CreatedBy,
  CreatedAt,
  LastChangedBy,
  LastChangedAt,
  LocalLastChangedAt
  
}
