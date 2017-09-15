#
# Select for CUSTOMER
#
# Parameters:
#
# CUSTOMER
# _WHERE_ (optional)
# _ORDER_ (optional)
#
select
  country                 as Country,
  bp_org_name             as Customer,
  regional_buying_classification as Active,
  opportunity_owner_name  as Opp_Owner,
  opportunity_id          as Opp_Id,
  closing_date            as Close_Date,
  opp_phase               as Phase,
  fc_qualification        as Category,
  opportunity_description as Opp_Desc,
  product                 as Product,
  product_desc            as Product_Desc,
  rnd(acv_keur)           as acv,
  rnd(tcv_keur)           as tcv
from pipeline p
join hcp on product = hcp.product
where
      revenue_type   = 'New Software'
  and opp_status     = 'In process'
  and bp_org_name    like '%CUSTOMER%'
  _WHERE_
  _ORDER_

