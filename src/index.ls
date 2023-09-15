module.exports =
  pkg:
    name: "@makeform/budget", extend: {name: "@makeform/common"}
    dependencies: [
      {name: "@plotdb/sheet"}
      {name: "@plotdb/sheet", type: \css}
    ]
    i18n:
      "en": "單位": "unit"
      "zh-TW": "unit": "單位"

  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t}) -> 
  {sheet} = ctx
  lc = {}
  init: ->
    view = new ldview do
      root: root
      init: sheet: ({node, ctx}) ->
        sh = new sheet do
          root: node
          slider: true
          data: [<[品項 單價 數量 金額]>]
          frozen: row: 1
          size: col: <[250px]>
          class: row: <[hl]>
          cellcfg: ({row, col, type}) ->
            if type == \readonly => return col == 3 or row == 0
            if type == \class =>
              if col == 3 or row == 0 => return \disabled
              if col == 0 => return \name-field
              return ''
        sh.on \change, ->
          data = sh.data!
          lc.total = 0
          for i from 1 til data.length
            data[i][3] = if data[i][1]? and data[i][2]? => +data[i][1] * data[i][2] else ''
            lc.total += if data[i][3]? and !isNaN(data[i][3]) => +data[i][3] else 0
          sh.data data
          view.render \total


      text:
        total: ({node}) -> return lc.total or 0
        unit: ({node}) ~> t(@mod.info.config.unit or '')

  render: ->
  is-empty: (v) -> true
  is-equal: (u, v) -> false
  content: (v) -> return {}

