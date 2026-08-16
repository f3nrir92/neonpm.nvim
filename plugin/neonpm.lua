if vim.g.loaded_neonpm then
  return
end
vim.g.loaded_neonpm = true

vim.api.nvim_create_user_command("NeoNpm", function(cmd_opts)
  require("neonpm.dispatch").execute(cmd_opts)
end, {
  nargs = "*",
  desc = "Node.js package manager commands",
  complete = function(arg_lead, cmd_line, cursor_pos)
    return require("neonpm.dispatch").complete(arg_lead, cmd_line, cursor_pos)
  end,
})
