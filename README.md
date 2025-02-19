# @makeform/budget

## config

 - `fields`: Array of field object with following fields:
   - `name`: field name.
   - `type`: field type. optional; when provided, it should be one of following:
     - `name`: item name.
     - `unit price`: item price, per item.
     - `quantity`: how many entries of this item.
     - `total price`: when `unit price` and `quantity` provided, this will be readonly and calculated automatically.
   - `width`: optional. used for explicitly set cell width (with unit).
 - `mode`: either `sheet` or `table`. default `sheet` if omitted.
   - when setting to `table`, table style edit interface is used. otherwise `@plotdb/sheet` is used.
 - `unit`: unit of the amount (displayed next to total amount field)

## License

MIT
