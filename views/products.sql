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
from pipeline
_WHERE_
order by product_desc
