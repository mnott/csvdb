#
# Select Countries where we see opportunities on our products
#
# Parameters:
#
# _WHERE_ (optional)
#
select distinct
  country as Country
from pipeline p
join hcp on product = hcp.product
  _WHERE_
ORDER BY country asc
#  _ORDER_

