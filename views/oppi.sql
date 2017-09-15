#
# Select for Oppi
#
# Parameters:
#
# OPPI
# _WHERE_ (optional)
# _ORDER_ (optional)
#
select
  bp_org_name             as Customer,
  opportunity_description as Opp_Desc,
  opportunity_owner_name  as Client_Partner,
  opportunity_owner_name  as Opp_Owner,
  opp_phase               as Phase,
  closing_date            as Close_Date,
  fc_qualification        as Category,
  country                 as MU,
  opportunity_id          as Opp_Id,
  rnd(acv_keur)           as acv
from pipeline
join hcp on product = hcp.product
where
      revenue_type   = 'New Software'
  and opp_status     = 'In process'
  and opportunity_id = 'OPPI'
  _WHERE_
  _ORDER_