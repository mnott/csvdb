#
# Select for Country
#
# Parameters:
#
# COUNTRY
# _WHERE_ (optional)
#
select
  p.country                 as Country,
  p.bp_org_name             as Customer,
  p.regional_buying_classification as Active,
  p.opportunity_owner_name  as Opp_Owner,
  p.sw_fc_template          as Relevant,
  p.opportunity_id          as Opp_Id,
  p.closing_date            as Close_Date,
  p.opp_phase               as Phase,
  p.fc_qualification        as Category,
  p.opportunity_description as Opp_Desc,
  p.product                 as Product,
  p.product_desc            as Product_Desc,
  p.acv_keur                as ACV,
  p.tcv_keur                as TCV
from pipeline p
join hcp on p.product = hcp.product
where
      p.revenue_type   = 'New Software'
  and p.opp_status     = 'In process'
  and p.country        like '%COUNTRY%'
  _WHERE_
order by
  bp_org_name,
  tcv_keur desc

