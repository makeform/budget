module.exports =
  pkg:
    name: "@makeform/budget", extend: {name: "@makeform/common"}
    dependencies: [
      {name: "papaparse", path: "papaparse.min.js"}
      {name: "@plotdb/sheet"}
      {name: "@plotdb/sheet", type: \css}
    ]
    i18n:
      "en":
        "單位": "Unit"
        "總金額": "Subtotal"
        "追加": "Add"
        "無資料": "No Data"
      "zh-TW":
        "單位": "單位"
        "總金額": "總金額"
        "追加": "追加"
        "無資料": "無資料"

  init: (opt) -> opt.pubsub.fire \subinit, mod: mod(opt)

mod = ({root, ctx, data, parent, t}) -> 
  {sheet} = ctx
  lc = total: 0, mode: \edit
  init: ->
    @on \change, (v = {}) ~>
      lc.total = v.total or 0
      data = JSON.parse(JSON.stringify(v.data)) or []
      data = [heads.map(->t it.name)] ++ data
      lc._data = JSON.parse(JSON.stringify(data)) or []
      if lc.sheet => lc.sheet.data data
      view.render \total, \no-row, \row, \head
    @on \mode, (m) ~>
      lc.mode = m
      if lc.sheet => lc.sheet.render!
      view.render \no-row, \row, \head, \sheet, \table, \viewer
    is-table-mode = ~> (@mod.info.config or {}).mode == \table
    is-readonly = ~>
      meta = @mod.info.config.meta or {}
      return (lc.mode == \view) or meta.disabled or meta.readonly
    heads = ((@mod.info.config or {}).fields or [])
    lc._data = [heads.map -> it]
    ['total price']
      .filter (n) -> !heads.filter((h)-> h.type == n).length
      .for-each (n) -> heads.push {name: n, type: n}
    heads.map (d,i) -> d.idx = i
    @mod.child.sheet-update = ->
      d = lc.sheet.data!
      d.splice 0, 1
      d = [heads.map(->t it.name)] ++ d
      lc.sheet.data d
    types = heads.map(-> it.type)
    typeidx = {}
    ['name', 'unit price', 'quantity', 'total price'].map (n) -> typeidx[n] = types.indexOf(n)
    cls = heads.map ->
      return switch it.type
      | 'total price' =>
        if ~typeidx['unit price'] and ~typeidx['quantity'] => \disabled else ''
      | 'name' => \name-field
      | otherwise => ''

    get-sum = (data) ->
      sum = 0
      up = typeidx['unit price']
      q = typeidx['quantity']
      tp = typeidx['total price']
      if !(~up and ~q) =>
        for i from 1 til data.length
          val = if data[i][tp]? and !isNaN(data[i][tp]) => +data[i][tp] else 0
          sum += (val or 0)
      else
        for i from 1 til data.length
          [_up, _q] = [data[i][up], data[i][q]].map -> "#{if it? => it else ''}".trim!
          val = if _up != '' and _q != '' => +_up * +_q else ''
          val = if val == '' => '' else if val? and !isNaN(val) => +val else 0
          data[i][tp] = val
          sum += (val or 0)
      {data, sum}

    update-data = (data, _view) ~>
      ret = get-sum data
      lc.total = ret.sum
      data = JSON.parse(JSON.stringify(ret.data))
      data.splice 0, 1
      @value {total: lc.total, data} .then ->
        view.render \total
        if !_view => return
        _view.render!
        _update!now!
      return ret

    @mod.child.view = view = new ldview do
      root: root
      init: sheet: ({node, ctx}) ~>
        size = heads.map ->
          ret = it.width or ''
          if it.type == \name and !ret => ret = \250px
          return ret
        lc.sheet = sh = new sheet do
          root: node
          slider: true
          data: [heads.map(->t it.name)]
          frozen: row: 1
          size: col: size
          class: row: <[hl]>
          scroll-lock: true
          enable-scrolling: false
          cellcfg: ({row, col, type}) ->
            if type == \readonly =>
              if is-readonly! => return true
              if row == 0 => return true
              if cls[col] == \disabled => return true
              return false
            if type == \class =>
              if row == 0 => return \disabled
              return cls[col] or ''
        sh.on \change, ~>
          if is-readonly! => return sh.data JSON.parse(JSON.stringify(lc._data))
          data = sh.data!
          ret = update-data data
          sh.data ret.data
      action: click: add: ({node}) ->
        lc._data.push heads.map(->'')
        update-data lc._data, view
      handler:
        sheet: ({node}) ~> node.classList.toggle \d-none, (@mode! == \view or is-table-mode!)
        table: ({node}) ~> node.classList.toggle \d-none, (@mode! == \view or !is-table-mode!)
        viewer: ({node}) ~> node.classList.toggle \d-none, @mode! != \view
        total: ({node}) ~> node.classList.toggle \text-danger, (@status! == 2)
        "head":
          list: -> heads
          key: -> it.idx
          view: handler: "@": ({node, ctx}) ->
            node.innerText = t(ctx.name)
            node.style.width = ctx.width or ''
        "no-row": ({node}) ->
          row-count = (lc._data or [])
            .filter(-> it and it.filter and it.filter(->it?).length)
            .length < 2
          node.classList.toggle \d-none, !row-count
        row:
          list: ->
            ret = (lc._data or []).map (d,i) -> {data: d, idx: i}
            ret.filter(-> it and it.data.filter and it.data.filter(->it?).length).slice 1
          key: -> it.idx
          view:
            action: click: delete: ({ctx, views}) ~>
              lc._data.splice ctx.idx, 1
              ret = update-data lc._data, view
            handler:
              col:
                list: -> heads
                key: -> it
                view:
                  handler: "@": ({node, ctx, ctxs, views}) ->
                    node.style.width = ctx.width or ''
                    v = ctxs.0.data[ctx.idx] or ''
                    node.value = v
                    node.innerText = v
                    _update!
                  action:
                    input: "@": ({node, ctx, ctxs, views}) ->
                      lc._data[ctxs.0.idx][ctx.idx] = node.value or ''
                      update-data lc._data, views.1
                    change: "@": ({node, ctx, ctxs, views}) ->
                      lc._data[ctxs.0.idx][ctx.idx] = node.value or ''
                      update-data lc._data, views.1
      text:
        total: ({node}) -> return lc.total or 0
        unit: ({node}) ~> t(@mod.info.config.unit or '')
    _update = debounce ->
      ld$.find(root, '.lc-sheet-row').map (node) ->
        fields = ld$.find(node, \textarea)
        fields.map -> it.style.height = "0px"
        sh = Math.max.apply Math, fields.map -> it.scrollHeight
        fields.map -> it.style.height = "#{sh + 2}px"

  render: ->
    if @mod.child.view => @mod.child.view.render!
    if @mod.child.sheet-update => @mod.child.sheet-update!
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

