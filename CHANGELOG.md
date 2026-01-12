# Change Log

## v1.0.0

 - support `@grantdash/composer` host
 - support selectable field in table mode


## v0.1.0

 - tweak DOM based on updated `@makeform/common` DOM structure.


## v0.0.24

 - fix bug: readonly flag read from incorrect field.
 - add `readonly` css class for indicating readonly status


## v0.0.23

 - fix bug: 0 is not shown in sheet view mode
 - fix bug: the first row is not shown in sheet view mode


## v0.0.22

 - tweak name field size


## v0.0.21

 - align number to the right
 - proper handle number with comma
 - update data and set lc field when needed
 - show error as text instead of tip


## v0.0.20

 - remove unused log


## v0.0.19

 - use `sheet-viewer` / `table-viewer` for viewer of corresponding edit mode
 - use table for sheet-viewer for better layout and alignment
 - tweak sheet cell max height
 - check empty line against `undefined` and also `''` (only for sheet-viewer)
 - skip sheet update if not in sheet mode to prevent data corruption
 - move `lc` into `init` function to prevent unexpected wrong scope
 - force cell size for name fields also in viewer mode
 - ensure minimal cell width 5.5em for viewer mode


## v0.0.18

 - remove unnecessary log


## v0.0.17

 - provide calculated `subsidy` in value


## v0.0.16

 - use correct key function when iterating cols in ldview


## v0.0.15

 - make subsidy readonly and calculated automatically by self-fund field


## v0.0.14

 - fix bug: table headers are not correctly translated


## v0.0.13

 - fix bug: sheet headers are not correctly translated
 - tweak i18n


## v0.0.12

 - fix bug: render should call view.render to update widget content


## v0.0.11

 - fix bug: border radius incorrectly styled for header
 - tweak cell to always make it higher a little to prevent unexpected scrolling


## v0.0.10

 - fix bug: `delete` accidentally remove one additional row


## v0.0.9

 - support alternative editing mode by setting `config.mode` to `table`.
 - add `no data` hint.


## v0.0.8

 - support plain text viewing mode
 - limit sheet widget scrolling and cell sizing to optimize user experience


## v0.0.7

 - use `mf-note` to replace styling in note-related tag.


## v0.0.6

 - add error tip and status indicator in number node


## v0.0.5

 - tweak for i18n


## v0.0.4

 - add `papaparse` as dependency
 - update field update mechanism to prevent unexpected zero


## v0.0.3

 - add `width` option in field objects.
 - support readonly mode for using in view mode or when widget is disabled / set as readonly.


## v0.0.2

 - abstract fields with `name`, `unit price`, `quantity`, `total price`.
 - correctly support get / set dynamics 


## v0.0.1

init release
