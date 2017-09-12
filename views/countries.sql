#
# Select Countries where we see opportunities on our products
#
# Parameters:
#
# _WHERE_ (optional)
#
select distinct
  p.country as Country
from pipeline p
join hcp on p.product = hcp.product
  _WHERE_
order by
  country

