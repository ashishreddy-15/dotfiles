-- Minimal monochrome + one accent
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then vim.cmd("syntax reset") end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.g.colors_name = "mono"

-- Palette "Carbon & Pewter", the same as the desktop (quickshell/Theme.qml) and kitty, so the editor and the
-- terminal it runs in are one surface. `muted` sits between text and dim (strings, operators).
local c = {
  bg = "#111111", surface = "#141414", raised = "#1b1b1b", border = "#262626",
  dim = "#666a6e", muted = "#878b8f", fg = "#adb0b3", bright = "#d0d3d6",
  accent = "#6c7f91", red = "#a67a7e", amber = "#a8976f",
}
-- Code gets a few muted hues so its parts are easy to tell apart (the interface above stays monochrome). They are
-- the desktop's status colours (ok = sage, warn = sand, err = rose) and its pewter, each lifted a little so it stands
-- out from plain text on the dark background.
local syn = {
  keyword = "#8ca3ba",   -- pewter, lifted        public, class, if, return
  type    = "#86ab95",   -- sage                 String, List, int, MyClass
  fn      = c.bright,    -- bright                methods and functions
  field   = "#a9bfcd",   -- mist blue-grey        this.name, record components
  string  = "#b8a576",   -- sand                 "text", 'c'
  const   = "#c4989c",   -- rose, lifted          42, true, null, MAX_SIZE, enum constants
  annot   = "#a99bc2",   -- lavender-grey         @Override, @Service
}
local function hl(g, o) vim.api.nvim_set_hl(0, g, o) end

local groups = {
  Normal = { fg = c.fg, bg = c.bg }, NormalNC = { fg = c.fg, bg = c.bg },
  NormalFloat = { fg = c.fg, bg = c.surface }, FloatBorder = { fg = c.border, bg = c.surface },
  FloatTitle = { fg = c.accent, bg = c.surface },
  Cursor = { fg = c.bg, bg = c.fg }, CursorLine = { bg = c.surface }, CursorLineNr = { fg = c.accent },
  LineNr = { fg = c.dim }, SignColumn = { bg = c.bg }, ColorColumn = { bg = c.surface },
  Visual = { bg = c.raised }, Search = { fg = c.bg, bg = c.accent }, IncSearch = { fg = c.bg, bg = c.amber },
  CurSearch = { fg = c.bg, bg = c.amber }, MatchParen = { fg = c.accent, bold = true },
  VertSplit = { fg = c.border }, WinSeparator = { fg = c.border },
  StatusLine = { fg = c.fg, bg = c.surface }, StatusLineNC = { fg = c.muted, bg = c.surface },
  Pmenu = { fg = c.fg, bg = c.surface }, PmenuSel = { fg = c.accent, bg = c.raised },
  PmenuSbar = { bg = c.surface }, PmenuThumb = { bg = c.dim },
  TabLine = { fg = c.muted, bg = c.surface }, TabLineSel = { fg = c.accent, bg = c.bg }, TabLineFill = { bg = c.surface },
  Folded = { fg = c.muted, bg = c.surface }, NonText = { fg = c.dim }, Whitespace = { fg = c.border },
  EndOfBuffer = { fg = c.bg }, Directory = { fg = c.accent }, Title = { fg = c.fg, bold = true },
  ErrorMsg = { fg = c.red }, WarningMsg = { fg = c.amber }, MoreMsg = { fg = c.accent }, Question = { fg = c.accent },
  -- syntax (see `syn` above)
  Comment = { fg = c.dim, italic = true }, Constant = { fg = syn.const }, String = { fg = syn.string },
  Character = { fg = syn.string }, Number = { fg = syn.const }, Boolean = { fg = syn.const }, Float = { fg = syn.const },
  Identifier = { fg = c.fg }, Function = { fg = syn.fn },
  Statement = { fg = syn.keyword }, Keyword = { fg = syn.keyword }, Conditional = { fg = syn.keyword },
  Repeat = { fg = syn.keyword }, Exception = { fg = syn.keyword }, Label = { fg = syn.keyword },
  Operator = { fg = c.muted }, PreProc = { fg = syn.keyword }, Include = { fg = syn.keyword },
  Type = { fg = syn.type }, StorageClass = { fg = syn.keyword }, Structure = { fg = syn.type },
  Special = { fg = syn.annot }, SpecialChar = { fg = syn.annot }, Delimiter = { fg = c.muted },
  Underlined = { fg = c.accent, underline = true }, Todo = { fg = c.amber, bold = true },
  Error = { fg = c.red },
  -- diagnostics
  DiagnosticError = { fg = c.red }, DiagnosticWarn = { fg = c.amber },
  DiagnosticInfo = { fg = c.muted }, DiagnosticHint = { fg = c.dim },
  DiagnosticUnderlineError = { undercurl = true, sp = c.red }, DiagnosticUnderlineWarn = { undercurl = true, sp = c.amber },
  -- diff / gitsigns
  DiffAdd = { fg = c.fg, bg = c.raised }, DiffChange = { bg = c.surface }, DiffDelete = { fg = c.red },
  DiffText = { fg = c.accent, bg = c.raised }, Added = { fg = c.muted }, Changed = { fg = c.amber }, Removed = { fg = c.red },
  GitSignsAdd = { fg = c.muted }, GitSignsChange = { fg = c.amber }, GitSignsDelete = { fg = c.red },
  -- telescope
  TelescopeBorder = { fg = c.border }, TelescopeSelection = { fg = c.accent, bg = c.raised },
  TelescopeMatching = { fg = c.accent, bold = true }, TelescopePromptPrefix = { fg = c.accent },
}
for g, o in pairs(groups) do hl(g, o) end

-- Treesitter captures (and, through Neovim's defaults, LSP semantic tokens) onto the colours above.
local ts = {
  ["@variable"] = { fg = c.fg }, ["@variable.builtin"] = { fg = syn.keyword },          -- this, super
  ["@variable.parameter"] = { fg = c.fg, italic = true },
  ["@variable.parameter.bash"] = { fg = c.fg },        -- bash calls a command's arguments "parameters": not italic
  ["@variable.member"] = { fg = syn.field }, ["@property"] = { fg = syn.field }, ["@field"] = { fg = syn.field },
  ["@function"] = { fg = syn.fn, bold = true }, ["@function.method"] = { fg = syn.fn, bold = true },
  ["@function.call"] = { fg = syn.fn }, ["@function.method.call"] = { fg = syn.fn },
  ["@function.builtin"] = { fg = syn.fn }, ["@constructor"] = { fg = syn.type },
  ["@keyword"] = { fg = syn.keyword }, ["@keyword.function"] = { fg = syn.keyword },
  ["@keyword.return"] = { fg = syn.keyword }, ["@keyword.conditional"] = { fg = syn.keyword },
  ["@keyword.repeat"] = { fg = syn.keyword }, ["@keyword.exception"] = { fg = syn.keyword },
  ["@keyword.import"] = { fg = syn.keyword }, ["@keyword.modifier"] = { fg = syn.keyword },
  ["@keyword.type"] = { fg = syn.keyword }, ["@keyword.operator"] = { fg = syn.keyword },
  ["@type"] = { fg = syn.type }, ["@type.builtin"] = { fg = syn.type }, ["@type.definition"] = { fg = syn.type },
  ["@module"] = { fg = c.muted },                                                          -- package names
  ["@attribute"] = { fg = syn.annot }, ["@annotation"] = { fg = syn.annot },
  ["@string"] = { fg = syn.string }, ["@string.escape"] = { fg = syn.annot }, ["@character"] = { fg = syn.string },
  ["@number"] = { fg = syn.const }, ["@number.float"] = { fg = syn.const }, ["@boolean"] = { fg = syn.const },
  ["@constant"] = { fg = syn.const }, ["@constant.builtin"] = { fg = syn.const },          -- null
  ["@comment"] = { fg = c.dim, italic = true }, ["@comment.documentation"] = { fg = c.dim, italic = true },
  ["@operator"] = { fg = c.muted }, ["@punctuation"] = { fg = c.muted },
  ["@punctuation.bracket"] = { fg = c.muted }, ["@punctuation.delimiter"] = { fg = c.muted },
  ["@tag"] = { fg = syn.keyword }, ["@tag.attribute"] = { fg = syn.field }, ["@tag.delimiter"] = { fg = c.muted },
  -- LSP semantic tokens that do not already map onto the captures above
  ["@lsp.type.annotation"] = { fg = syn.annot }, ["@lsp.type.modifier"] = { fg = syn.keyword },
  ["@lsp.type.enumMember"] = { fg = syn.const }, ["@lsp.type.typeParameter"] = { fg = syn.type, italic = true },
  ["@lsp.mod.static"] = { italic = true },                                                  -- static members
}
for g, o in pairs(ts) do vim.api.nvim_set_hl(0, g, o) end
