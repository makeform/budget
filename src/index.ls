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
  lc = total: 0
  init: ->
    @on \change, (v = {}) ~>
      lc.total = v.total or 0
      data = JSON.parse(JSON.stringify(v.data)) or []
      data = [heads.map(->t it.name)] ++ data
      lc.sheet.data data
      view.render \total
    heads = ((data.config or {}).fields or [])
    ['total price']
      .filter (n) -> !heads.filter((h)-> h.type == n).length
      .for-each (n) -> heads.push {name: n, type: n}
    types = heads.map(-> it.type)
    typeidx = {}
    ['name', 'unit price', 'quantity', 'total price'].map (n) -> typeidx[n] = types.indexOf(n)
    cls = heads.map ->
      return switch it.type
      | 'total price' =>
        if ~typeidx['unit price'] and ~typeidx['quantity'] => \disabled else ''
      | 'name' => \name-field
      | otherwise => ''
    view = new ldview do
      root: root
      init: sheet: ({node, ctx}) ~>
        lc.sheet = sh = new sheet do
          root: node
          slider: true
          data: [heads.map(->t it.name)]
          frozen: row: 1
          size: col: heads.map(-> if it.type == \name => \250px else '')
          class: row: <[hl]>
          cellcfg: ({row, col, type}) ->
            if type == \readonly =>
              if row == 0 => return true
              if cls[col] == \disabled => return true
              return false
            if type == \class =>
              if row == 0 => return \disabled
              return cls[col] or ''
        sh.on \change, ~>
          up = typeidx['unit price']
          q = typeidx['quantity']
          tp = typeidx['total price']
          data = sh.data!
          lc.total = 0
          if !(~up and ~q) =>
            for i from 1 til data.length
              val = if data[i][tp]? and !isNaN(data[i][tp]) => +data[i][tp] else 0
              lc.total += (val or 0)
          else
            for i from 1 til data.length
              val = if data[i][up]? and data[i][q]? => +data[i][up] * data[i][q] else ''
              val = if val == '' => '' else if val? and !isNaN(val) => +val else 0
              data[i][tp] = val
              lc.total += (val or 0)
            sh.data data
          data = JSON.parse(JSON.stringify(data))
          data.splice 0, 1
          @value {total: lc.total, data}
          view.render \total
      text:
        total: ({node}) -> return lc.total or 0
        unit: ({node}) ~> t(@mod.info.config.unit or '')

  render: ->
  is-empty: (v) -> return !(v and v.data and v.data.length and v.data.filter(->it.length).length)
  is-equal: (u, v) ->
    [eu,ev] = [@is-empty(u), @is-empty(v)]
    if eu and ev => return true
    if eu or ev => return false
    if u.total != v.total => return false
    if u.data.length != v.data.length => return false
    for i from 0 til u.data.length =>
      [au, av] = [u.data[i], v.data[i]]
      if au.length != av.length => return false
      for j from 0 til au.length => if au[j] != av[j] => return false
    return true
  content: (v) -> return v

