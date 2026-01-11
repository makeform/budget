module.exports =
  pkg:
    name: \@makeform/budget
    extend: name: \@makeform/common
    host: name: \@grantdash/composer
    dependencies: [
    * name: "papaparse", path: "papaparse.min.js"
    * name: "@plotdb/sheet"
    * name: "@plotdb/sheet", type: \css
    ]
    i18n:
      "en":
        "單位": "Unit"
        "總金額": "Subtotal"
        "追加": "Add"
        "無資料": "No Data"
        sheet: "Sheet"
        table: "Table"
        config:
          mode: name: 'Mode', desc: 'Use either sheet or table for budget editing'
          unit: name: 'Unit', desc: "Display an additional unit label or suffix."
      "zh-TW":
        "單位": "單位"
        "總金額": "總金額"
        "追加": "追加"
        "無資料": "無資料"
        sheet: "試算表"
        table: "一般表格"
        config:
          mode: name: '模式', desc: '使用試算表或一般表格來填寫金額'
          unit: name: '單位', desc: "顯示額外的單位提示"

  init: (opt) ->
    opt.pubsub.on \inited, (o = {}) ~> @ <<< o
    opt.pubsub.fire \subinit, mod: mod.call @, opt

mod = ({root, ctx, data, parent, t}) -> 
  {sheet} = ctx
  hitf = ~> @hitf

  @client = (bid) ~>
    minibar: []
    meta: config:
      mode:
        type: \choice, name: \config.mode.name, desc: \config.mode.desc
        values: [{name: \試算表, value: \sheet}, {name: \一般表格, value: \table}]
      unit: type: \text, name: \config.unit.name, desc: \config.unit.desc
    sample: ~> config: fields: [
      * name: \預算分類, mode: 'select'
        values: <[人事費 事務費 業務費 維護費 旅運費 材料費 其他費]>
        default: \人事費
        width: \300px
      * name: "預算細目", type: 'name'
        width: \300px
      * name: "金額", type: 'total price'
      * name: "說明", width: '280px'
      ]
  init: ->
    lc = total: 0, mode: \edit
    @on \change, (v = {}) ~>
      lc <<< total: v.total or 0, subsidy: v.subsidy or 0
      data = JSON.parse(JSON.stringify(v.data)) or []
      data = [heads.map(->t it.name)] ++ data
      lc._data = JSON.parse(JSON.stringify(data)) or []
      ret = get-sum lc._data
      lc <<< ret{total, subsidy}
      if lc.sheet => lc.sheet.data JSON.parse(JSON.stringify(ret.data))
      update-data lc._data
      view.render \total, \no-row, \row, \head
    @on \meta, -> build-heads!; if view => view.render!
    @on \mode, (m) ~>
      lc.mode = m
      if lc.sheet => lc.sheet.render!
      view.render \no-row, \row, \head, \sheet, \table, \table-viewer, \sheet-viewer
    is-table-mode = ~> (@mod.info.config or {}).mode == \table
    is-readonly = ~>
      meta = @mod.info.meta or {}
      return (lc.mode == \view) or meta.disabled or meta.readonly
    old-heads = []
    heads = []
    types = []
    typeidx = {}
    cls = []
    build-heads = ~>
      heads := hitf!get!?config?fields or []
      # heads-dirty will be reset after sheet is redrawn.
      # this can help reducing rendering of sheet
      lc._heads-dirty = (old-heads != JSON.stringify(heads))
      old-heads := JSON.stringify(heads)
      lc._data = [heads.map -> it]
      ['total price']
        .filter (n) -> !heads.filter((h)-> h.type == n).length
        .for-each (n) -> heads.push {name: n, type: n}
      heads.map (d,i) -> d.idx = i
      types := heads.map(-> it.type)
      typeidx := {}
      ['name', 'unit price', 'quantity', 'total price', 'self-fund', 'subsidy'].map (n) ->
        typeidx[n] = types.indexOf(n)
      cls := heads.map ->
        return switch it.type
        | 'total price' =>
          if ~typeidx['unit price'] and ~typeidx['quantity'] => 'disabled number' else 'number'
        | 'subsidy' => 'disabled number'
        | 'self-fund' => 'number'
        | 'unit price' => 'number'
        | 'quantity' => 'number'
        | 'name' => \name-field
        | otherwise => ''

    build-heads!

    @mod.child.sheet-update = ->
      if !lc.sheet => return
      d = lc.sheet.data!
      d.splice 0, 1
      d = [heads.map(->t it.name)] ++ d
      ret = get-sum d
      lc <<< ret{total, subsidy}
      lc.sheet.data ret.data

    pv = (v) -> ("#v".trim!replace(/,/g,''))
    get-sum = (data) ->
      sum = 0
      sum-subsidy = 0
      up = typeidx['unit price']
      q = typeidx['quantity']
      tp = typeidx['total price']
      sf = typeidx['self-fund']
      subsidy = typeidx['subsidy']
      if !(~up and ~q) =>
        for i from 1 til data.length
          val = if data[i][tp]? and !isNaN(pv(data[i][tp])) => +pv(data[i][tp]) else 0
          sum += (val or 0)
      else
        for i from 1 til data.length
          [_up, _q] = [data[i][up], data[i][q]].map -> pv("#{if it? => it else ''}".trim!)
          val = if _up != '' and _q != '' => +pv(_up) * +pv(_q) else ''
          val = if val == '' => '' else if val? and !isNaN(val) => +val else 0
          data[i][tp] = val
          sum += (val or 0)
      if (~subsidy) =>
        for i from 1 til data.length =>
          _sf = "#{if ~sf => if data[i][sf]? => data[i][sf] else ''}".trim!
          _sf = if isNaN(+pv(_sf)) or !_sf => 0 else +pv(_sf)
          val = data[i][subsidy] = if !data[i][tp]? or data[i][tp] == '' => ''
          else (+pv(data[i][tp]) - (_sf)) >? 0
          val = if !val => 0 else if isNaN(parseFloat(val)) => 0 else +val
          sum-subsidy += (val or 0)
      {data, total: sum, subsidy: sum-subsidy}

    update-data = (data, _view) ~>
      ret = get-sum data
      lc <<< ret{total, subsidy}
      data = JSON.parse(JSON.stringify(ret.data))
      data.splice 0, 1
      @value {total: lc.total, subsidy: lc.subsidy, data} .then ->
        view.render \total
        if !_view => return
        _view.render!
        _update!now!
      return ret

    @mod.child.view = view = new ldview do
      root: root
      init: sheet: ({node, ctx}) ~>
        if is-table-mode! and hitf!readonly! => return
        lc.sheet = sh = new sheet do
          root: node
          slider: true
          data: [heads.map(->t it.name)]
          frozen: row: 1
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
              ret = []
              if is-readonly! => ret.push \readonly
              if cls[col] => ret.push cls[col]
              return ret.join(' ')
        sh.on \change, ~>
          if is-readonly! => return sh.data JSON.parse(JSON.stringify(lc._data))
          data = sh.data!
          ret = update-data data
          sh.data ret.data
      action: click: add: ({node}) ->
        lc._data.push heads.map(->'')
        update-data lc._data, view
      handler:
        sheet: ({node}) ~>
          node.classList.toggle \d-none, (@mode! == \view or is-table-mode!)
          if (is-table-mode! and hitf!readonly!) or !lc._heads-dirty => return
          lc._heads-dirty = false
          size = heads.map ->
            ret = it.width or ''
            if it.type == \name and !ret => ret = \190px
            return ret
          lc.sheet.size col: size
          d = lc.sheet.data!
          d.0 = heads.map(->t it.name)
          lc.sheet.data d
        table: ({node}) ~> node.classList.toggle \d-none, (@mode! == \view or !is-table-mode!)
        "table-viewer": ({node}) ~> node.classList.toggle \d-none, (@mode! != \view or !is-table-mode!)
        "sheet-viewer": ({node}) ~> node.classList.toggle \d-none, (@mode! != \view or is-table-mode!)
        total: ({node}) ~> node.classList.toggle \text-danger, (@status! == 2)
        "head":
          list: -> heads
          key: -> it.idx
          view: handler: "@": ({node, ctx}) ->
            node.innerText = t(ctx.name)
            node.style.width = ctx.width or (if ctx.type == \name => \200px else '')
        "no-row": ({node}) ->
          row-count = (lc._data or [])
            .filter(-> it and it.filter and it.filter(->it?).length)
            .length < 2
          node.classList.toggle \d-none, !row-count
        row:
          list: ->
            itm = is-table-mode!
            ret = (lc._data or []).map (d,i) -> {data: d, idx: i}
            ret = ret.filter(->
              it and it.data.filter and
              # in table mode, empty row has to be shown so user can input data (`itm`)
              # yet in sheet mode, this is only for viewing. no need to show empty row (`or it != ''`)
              it.data.filter(->it? and (itm or it != '')).length
            ).slice 1
            ret
          key: -> it.idx
          view:
            action: click: delete: ({ctx, views}) ~>
              lc._data.splice ctx.idx, 1
              ret = update-data lc._data, view
            handler:
              col:
                list: -> heads
                key: -> it.idx
                view:
                  init:
                    "textarea": ({node, ctx}) ->
                      node.classList.toggle \d-none, (ctx.mode? and ctx.mode == \select)
                  handler:
                    "select":
                      init: "@": ({node, ctxs}) ->
                        node.classList.toggle \d-none, (ctxs.0.mode != \select)
                      action: change: "@": ({node, ctxs, views}) ->
                        lc._data[ctxs.1.idx][ctxs.0.idx] = node.value or ''
                        update-data lc._data, views.2
                      handler:
                        "@": ({node, ctx, ctxs}) ->
                          node.style.width = ctxs.0.width or (if ctxs.0.type == \name => \200px else '')
                          v = if ctxs.1.data[ctxs.0.idx] => ctxs.1.data[ctxs.0.idx] else ctxs.0.default
                          node.value = v
                        option:
                          list: ({ctxs}) -> ctxs.0.values or []
                          key: -> it
                          view: handler: "@": ({node, ctx}) ->
                            node.setAttribute \value, ctx
                            node.textContent = ctx
                    "textarea": ({node, ctx, ctxs, views}) ->
                      node.style.width = ctx.width or (if ctx.type == \name => \200px else '')
                      v = if ctxs.0.data[ctx.idx]? => ctxs.0.data[ctx.idx] else ''
                      node.value = v
                      node.innerText = v
                      _update!
                    "@": ({node, ctx, ctxs, views}) ->
                      node.style.width = ctx.width or (if ctx.type == \name => \200px else '')
                    content: ({node, ctx, ctxs, views}) ->
                      node.style.width = ctx.width or (if ctx.type == \name => \200px else '')
                      v = if ctxs.0.data[ctx.idx]? => ctxs.0.data[ctx.idx] else ''
                      if ctx.mode == \select and !v => v = ctx.default or ''
                      node.innerText = v
                      _update!
                  action:
                    input: "textarea": ({node, ctx, ctxs, views}) ->
                      lc._data[ctxs.0.idx][ctx.idx] = node.value or ''
                      update-data lc._data, views.1
                    change: "textarea": ({node, ctx, ctxs, views}) ->
                      lc._data[ctxs.0.idx][ctx.idx] = node.value or ''
                      update-data lc._data, views.1
      text:
        total: ({node}) -> return lc.total or 0
        unit: ({node}) ~> t(@mod.info.config.unit or '')
    _update = debounce ->
      ld$.find(root, '.lc-sheet-row').map (node) ->
        fields = ld$.find(node, 'textarea,select')
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

