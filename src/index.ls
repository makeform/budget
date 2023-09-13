module.exports =
  pkg:
    name: "@makeform/sheet", extend: {name: "@makeform/common"}
    dependencies: [ {name: "@plotdb/sheet"} ]
    i18n: {}
  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t}) -> 
  {sheet} = ctx
  lc = {}
  init: ->
  render: ->
  is-empty: (v) -> true
  is-equal: (u, v) -> false
  content: (v) -> return {}

