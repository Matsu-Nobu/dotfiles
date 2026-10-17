return {
  "hrsh7th/cmp-cmdline",
  lazy = false,
  config = function()
    local cmp = require "cmp"

    -- コマンドライン補完の設定
    cmp.setup.cmdline(':', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = cmp.config.sources({
        { name = 'path' }
      }, {
        { name = 'cmdline' }
      }),
      window = {
        completion = cmp.config.window.bordered(),
      },
      formatting = {
        fields = { "abbr", "kind", "menu" },
      },
    })

    -- 検索補完の設定
    cmp.setup.cmdline('/', {
      mapping = cmp.mapping.preset.cmdline(),
      sources = {
        { name = 'buffer' }
      },
      window = {
        completion = cmp.config.window.bordered(),
      },
      formatting = {
        fields = { "abbr", "kind", "menu" },
      },
    })
  end,
}
