#
# Select for Country
#
# Parameters:
#
# OPPI
# _WHERE_ (optional)
#
select
  p.bp_org_name             as Customer,
  p.opportunity_description as Opp_Desc,
  p.opportunity_owner_name  as Client_Partner,
  p.opportunity_owner_name  as Opp_Owner,
  p.opp_phase               as Phase,
  p.closing_date            as Close_Date,
  p.fc_qualification        as Category,
  p.country                 as MU,
  p.opportunity_id          as Opp_Id,
  p.acv_keur                as ACV
from pipeline p
join hcp on p.product = hcp.product
where
      p.revenue_type   = 'New Software'
  and p.opp_status     = 'In process'
  and p.opportunity_id = 'OPPI'
  _WHERE_

order by
  bp_org_name,
  tcv_keur desc

