# first used in mct-2024, written directly in form

form.opset.register {
  id: "budget"
  i18n: {}
  convert: (v) -> return v
  ops:
    "no-empty":
      func: (v, c = {}) ->
        # 因為有時申請者可能會溢填空白在超出需要的範圍外 (比方說 copy & paste 整個 row)
        # 我們應該只檢查有 header 的欄位, 但 v 並沒有 header 資訊
        # 對 mct-2024 來說案件很多都已送出所以沒辦法要求 v 帶 header
        # 因此用 c.columns 來做 workaround
        ret = v.data.filter -> (it or []).filter(->(it or it == 0) and !/^\s*$/.exec("#{it or ''}".trim!)).length
        if c.columns => ret = ret.map (d) -> d.slice 0, c.columns
        ret = ret.filter(-> it.filter(-> !(it?) or /^\s*$/.exec("#{if it? => it else ''}".trim!)).length).length
        return ret == 0

    "result-not-zero":
      func: (v, c = {}) ->
        return if c.field == \self-fund => (v.total or 0) - (v.subsidy or 0)
        else !!v[c.field]
      config: {field: {type: \string, hint: "result name"}}

    "field-format":
      func: (v, c = {}) ->
        # c.rule: success format.
        # !c.rule -> failed
        # list.map(!c.rule) == 0 no failed
        re = new RegExp(c.rule)
        ret = v.data.filter((d) ->
          v = d[c.field or 0] or ''
          return v? and ("#v".trim!) != '' and !re.exec(v)).length == 0
        return ret
      config:
        field: {type: \number, hint: "field idx"}
        rule: {type: \string, hint: "field rule (in regular expression)"}
}

