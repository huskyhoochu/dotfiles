-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- 자동 읽기 설정
vim.opt.autoread = true

-- CursorHold 이벤트에 대한 자동 명령 설정
vim.api.nvim_create_autocmd({ "CursorHold" }, {
  pattern = { "*" },
  callback = function()
    vim.cmd("checktime")
  end,
})

-- feedkeys 함수 호출
vim.api.nvim_feedkeys("lh", "n", true)
