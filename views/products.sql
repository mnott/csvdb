#
# Select Products
#
# Parameters:
#
# _WHERE_ (optional)
#
select distinct
  product_desc,
  product
from pipeline p
_WHERE_

order by product_desc
