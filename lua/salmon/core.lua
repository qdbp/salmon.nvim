-- please see https://github.com/qdbp/SalmonTheme?tab=readme-ov-file#the-restraint-scheme
-- for an explanation for the motivation and design language used here

---@class Salmon
---@field H table Table containing all highlight groups
---@field S table Table containing all sign definitions
---@field build_from_palette function Builds the color scheme from a given palette
---@field apply_highlights function Sets all highlight groups
---@field apply_signs function Sets all sign definitions
local M = {}

H = {} -- highlights definitions
S = {} -- signs definitions

function M.build_from_palette(palette)
  local c = palette.colors

  -- *** SEMANTIC GROUP DEFINITIONS ***
  -- used to add a layer of indirection for consistency
  -- TODO use systematically, this is just a stub for now
  -- TODO inject alongside palette?
  local sem = {
    bg_tree_selected = c.hlbg_7,
    bg_selected = c.wht_7,
    bg_active = c.wht_5,
    bg_entry = c.wht_4,

    text_lowkey = c.fg_light,
    text = c.fg,
    text_focus = c.black,
    text_tag = c.tone_5, -- labels, identifiers, enums
    text_tag_alt = c.tone_1, -- alternate tag when several types of tags are present

    nav_file = c.fg_dark,
    nav_dir = c.pri_5,
    nav_guide_lowkey = c.tint_0, -- deemphasized guides: aligners, indices into text, etc.
  }

  -- *** SEMANTIC HIGHLIGHTING (SCHEME) ***
  H.base_scheme = {

    -- we have a hierarchy of truth for highlighting information
    -- at the apex are LSP semantic token highlights
    -- LSP
    -- lsp mods
    ["@lsp.mod.builtin"] = { fg = c.ult_0 },
    ["@lsp.mod.defaultLibrary"] = "@lsp.builtin",
    -- TODO this doesn't work, need to use a callback to handle it properly!
    -- or better, fix upstream
    -- ['@lsp.mod.definition'] = { bold = false },
    ["@lsp.mod.classScope"] = "@lsp.property",

    -- lsp types
    ["@lsp.type.comment"] = { fg = c.fg_light },
    ["@lsp.type.unknown"] = { fg = c.fg_dark },
    -- text-like
    -- literal-like
    ["@lsp.type.boolean"] = { fg = c.tone_1, bold = true },
    ["@lsp.type.number"] = { fg = c.tone_1 },
    ["@lsp.type.string"] = { fg = c.tone_3 },
    ["@lsp.type.character"] = { fg = c.tone_4 },
    ["@lsp.type.regexp"] = { fg = c.tone_4 },
    -- class-like
    ["@lsp.type.enum"] = { fg = c.tone_1 },
    ["@lsp.type.class"] = { fg = c.tone_5 },
    ["@lsp.type.struct"] = { fg = c.tone_1 },
    -- function-like
    ["@lsp.type.function"] = { fg = c.black },
    ["@lsp.type.method"] = { fg = c.black },
    -- variable-like
    ["@lsp.type.constant"] = { fg = c.ult_5 },
    ["@lsp.type.parameter"] = { fg = c.pri_4 },
    ["@lsp.type.variable"] = { fg = c.fg_dark },
    ["@lsp.type.property"] = { fg = c.pri_1 },
    ["@lsp.type.enumMember"] = { fg = c.ult_1 },
    -- control flow-like
    ["@lsp.type.keyword"] = { fg = c.black, bold = true },
    ["@lsp.type.operator"] = "@lsp.type.keyword",
    ["@lsp.type.macro"] = { fg = c.ult_4 },
    ["@lsp.type.label"] = { fg = c.ult_2, bold = true },
    -- metaprogramming and scoping-like
    ["@lsp.type.decorator"] = { fg = c.ult_1 },
    ["@lsp.type.namespace"] = { fg = c.tint_3 },

    -- lsp legacy types; older LSPs still issue these?
    ["@lsp.enumMember"] = "@lsp.type.enumMember",
    ["@lsp.typeParameter"] = "@lsp.type.parameter",
    ["@lsp.operator"] = "@lsp.type.operator",
    ["@lsp.constant"] = "@lsp.type.constant",

    -- we're kind of making these one up, but they're handy
    ["@lsp.metadata"] = { fg = c.ult_1 },
    ["@lsp.label"] = "@lsp.type.label",

    -- base
    -- TODO fill out all entries from vim docs
    Comment = "@lsp.type.comment",
    SpecialComment = { fg = c.tint_5, bold = true },
    Todo = { fg = c.tint_1, bold = true },
    Constant = "@lsp.constant",

    -- primitives
    String = "@lsp.string",
    Character = "@lsp.type.regexp",
    Special = "@lsp.type.regexp",
    SpecialChar = { fg = c.tone_4 },
    Number = "@lsp.type.number",
    Float = "@lsp.typenumber",
    Boolean = "@lsp.typeboolean",

    -- variables
    Identifier = "@lsp.variable",
    Function = "@lsp.function",
    Metadata = "@lsp.type.decorator",
    PreProc = "@lsp.type.decorator",
    Define = "@lsp.type.macro",
    Macro = "@lsp.type.macro",
    Include = "@lsp.type.macro",

    -- conrol flow
    Keyword = "@lsp.type.keyword",
    Statement = "Keyword",
    Conditional = "Keyword",
    Repeat = "Keyword",
    Label = { fg = c.ult_2, bold = true },
    Operator = "@lsp.type.operator",

    -- syntax
    StorageClass = "@lsp.type.keyword",
    Exception = "@lsp.type.keyword",
    Type = "@lsp.type.class",
    PreCondit = "@lsp.type.keyword",
    Structure = "@lsp.type.struct",
    -- TODO make unique
    Typedef = "@lsp.type.class",
    Tag = "@lsp.type.keyword",
    Delimiter = { fg = c.fg_light }, -- unobtrusive

    -- meta
    Debug = "@lsp.keyword",
    Underlined = { underline = true },
    Ignore = { link = "Comment" },
    Error = { fg = c.pri_1 },
    Added = "@diff.plus",
    Changed = "@diff.delta",
    Removed = "@diff.minus",

    LspReferenceRead = { bg = c.hl_0 },
    LspReferenceWrite = { bg = c.hl_5 },

    -- TREESITTER
    -- note: most of these should be defined in links pointing back to LSP
    -- only add cases here that are not well-covered by LSP
    ["@comment"] = "Comment",

    -- TODO unsorted

    -- variable-like
    ["@attribute"] = "@lsp.type.metadata",
    ["@variable"] = "@lsp.type.variable",
    ["@variable.builtin"] = "@lsp.type.builtin",
    ["@variable.parameter"] = "@lsp.type.parameter",
    ["@variable.member"] = "@lsp.type.property",
    ["@field"] = "@lsp.type.property",
    ["@constant"] = "@lsp.type.constant",
    ["@constant.builtin"] = "@lsp.type.constant",
    ["@parameter"] = "@lsp.type.parameter",
    ["@property"] = "@lsp.type.property",

    -- primite-like
    ["@boolean"] = "@lsp.type.boolean",
    ["@character"] = "@lsp.type.string",
    ["@constant.macro"] = "@lsp.type.macro",
    ["@constructor"] = "@lsp.type.method",
    ["@exception"] = "@lsp.type.keyword",
    ["@function"] = "@lsp.type.function",
    ["@function.builtin"] = "@lsp.type.builtin",
    ["@function.macro"] = "@lsp.type.macro",

    -- keyword-like
    ["@conditional"] = "@lsp.type.keyword",
    ["@include"] = "@lsp.type.keyword",
    ["@keyword"] = "Keyword",
    ["@keyword.conditional"] = "@keyword",
    ["@keyword.function"] = "@keyword",
    ["@keyword.operator"] = "@keyword",
    ["@operator"] = "@lsp.type.operator",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.bracket"] = "@lsp.type.operator",
    ["@punctuation.special"] = "@lsp.type.operator",
    ["@repeat"] = "@lsp.type.keyword",
    ["@label"] = "@lsp.type.label",

    -- function-like
    ["@method"] = "@lsp.type.method",
    ["@function.call"] = { bold = true },
    ["@function.method.call"] = { bold = true },

    -- namespace-like
    ["@namespace"] = "@lsp.type.namespace",
    ["@module"] = "@lsp.type.namespace",

    ["@number"] = "@lsp.type.number",
    ["@number.float"] = "@lsp.type.number",
    ["@string"] = "@lsp.type.string",
    ["@string.documentation"] = { fg = c.tint_2, bold = true },
    ["@string.regex"] = "SpecialChar",
    ["@string.escape"] = "SpecialChar",
    ["@tag"] = "@lsp.type.keyword",
    ["@tag.attribute"] = "@lsp.type.property",
    ["@tag.delimiter"] = "@lsp.type.operator",
    ["@text"] = "@lsp.type.variable",
    ["@type"] = "@lsp.type.class",
    ["@type.builtin"] = "@lsp.type.class",

    -- language specific
    -- C/C++
    ["@attribute.cpp"] = { fg = c.tint_1 }, -- make it less garish
    -- Python
    ["@punctuation.delimiter.python"] = "@lsp.type.keyword", -- needs this weight
    -- TODO need a general solution for this `@spell` issue...
    ["@spell.python"] = "Comment",

    -- yaml
    ["@property.yaml"] = { fg = c.black },
    ["@string.yaml"] = { fg = c.tone_3 },

    -- zsh
    zshDeref = "@lsp.type.parameter",
    zshString = "String",
    zshStringDelimeter = "String",
    zshPOSIXString = "String",
  }

  -- THEME: styling the window and non-code elements
  H.base_theme = {
    -- cursor tweaks
    Cursor = { fg = c.bg_light, bg = c.black },
    ICursor = { fg = c.black, bg = c.black },

    -- basics
    Normal = { fg = c.fg_dark, bg = c.bg },
    NormalNC = { fg = c.fg },
    WinSeparator = { fg = c.dbg_3, bg = c.dbg_3 },
    Identifier = { link = "Normal" },
    Special = { fg = c.tone_4 },
    ErrorMsg = { fg = c.pri_1 },

    -- window tile
    WinBar = { bg = c.dbg_3, fg = c.black },
    WinBarNC = { bg = c.dbg_3, fg = c.fg },

    -- bottom of screen
    -- basic
    MsgArea = { fg = c.fg, bg = c.bg_3 },
    StatusLine = { fg = c.fg_dark, bg = c.bg_3 },
    StatusLineNC = { fg = c.fg_light, bg = c.bg_3 },
    ModeMsg = { fg = c.fg, bold = true, bg = c.bg_3 },
    MoreMsg = { fg = c.fg, bold = true, bg = c.bg_3 },

    -- left of screen, gutter, and cursor rows
    LineNr = { fg = c.fg_light, bg = c.bg_3 },
    CursorLine = { bg = c.wht_4 },
    CursorLineNR = { fg = c.tone_1, bg = c.bg_3, bold = true },
    FoldColumn = { fg = sem.nav_guide_lowkey, bg = c.bg_3 },
    SignColumn = { link = "FoldColumn" },
    -- create new generic group that any plugin can be configured to use
    IndentGuide = { fg = sem.nav_guide_lowkey },

    -- top of screen
    TabLineFill = { bg = c.bg_3, fg = c.fg },
    TabLineSel = { bg = c.wht_4, fg = c.black },
    TabLine = { bg = c.bg_3, fg = c.fg },

    -- popups and modals
    NormalFloat = { bg = c.bg_3 },
    FloatBorder = { bg = c.hlbg_7 },
    FloatTitle = { bg = c.hlbg_7 },
    FloatFooter = { bg = c.hlbg_7 },
    Pmenu = { fg = c.fg, bg = c.bg_7 },
    PmenuSel = { fg = c.fg, bg = c.wht_6 },
    PmenuThumb = { fg = c.fg, bg = c.bg_3 },
    QuickFixLine = { bg = c.hlbg_7, bold = true },

    -- selection, folded, search and match highlights
    Visual = { bg = c.hl_0 },
    Folded = { fg = c.fg_light, bg = c.bg_7 },
    MatchParen = { bg = c.hl_7 },
    Search = { bg = c.hl_4 },

    -- diagnostics
    DiagnosticError = { fg = c.black, bg = c.hl_2 },
    DiagnosticUnderlineError = { sp = c.hyper_2, undercurl = true },
    DiagnosticWarn = { fg = c.fg, bg = c.hl_3 },
    DiagnosticUnderlineWarn = { sp = c.hyper_3, undercurl = true },
    DiagnosticInfo = { fg = c.fg, bg = c.hl_0 },
    DiagnosticUnderlineInfo = { sp = c.hl_0, underline = true },
    DiagnosticHint = { fg = c.fg, bg = c.hl_7 },
    DiagnosticUnderlineHint = { sp = c.hl_7, underline = true },
    DiagnosticOK = { fg = c.fg, bg = c.hl_5 },
    DiagnosticUnnecessary = { fg = c.fg_light, undercurl = true },
    WarningMsg = { fg = c.hyper_2 },
    -- debugging
    Breakpoint = { fg = c.hyper_2, bold = true, bg = c.wht_6 },
    BreakpointCondition = { fg = c.hyper_1, bold = true, bg = c.wht_6 },

    -- diffs
    DiffAdd = { bg = c.hl_5 },
    DiffDelete = { bg = c.bg_darker },
    DiffChange = { bg = c.hl_7 },
    DiffText = "DiffChange",

    ["@diff.plus"] = { bg = c.hl_5 },
    ["@diff.delta"] = { bg = c.hl_7 },
    ["@diff.minus"] = { bg = c.hl_2 },

    -- file navigation
    Directory = { fg = sem.nav_dir },

    -- Markdown et al
    ["@markup.raw"] = { bg = c.wht_7 }, -- stop the garishness!
    Title = { fg = c.black, bold = true },
    Question = { fg = c.ult_5 },
    RenderMarkdownCode = { bg = c.wht_7 },
  }

  -- PLUGIN SPECIFIC
  -- mason
  H.mason = {
    MasonHighlight = { fg = c.pri_0 },
  }

  H.avante = {
    -- TODO avante diff resolution
    AvanteTitle = { fg = c.black, bg = c.bg_3, bold = true },
    AvanteSubtitle = { fg = c.black, bg = c.bg_3 },
    AvanteThirdTitle = { fg = c.fg, bg = c.bg_3 },
    AvanteReversedTitle = "AvanteTitle",
    AvanteReversedSubtitle = "AvanteSubtitle",
    AvanteReversedThirdTitle = "AvanteThirdTitle",
    AvantePopupHint = "Comment",
    AvanteInlineHint = { fg = c.fg_light },
  }

  -- telescope
  H.telecope = {
    TelescopeNormal = { fg = c.fg_dark, bg = c.wht_4 },
    TelescopeMatching = { bold = true, bg = c.hl_4 },
  }

  -- nvim-tree
  H.nvim_tree = {
    NvimTreeNormal = { bg = c.bg_3 },
    NvimTreeExecFile = { fg = c.pri_1 },
    NvimTreeImageFile = { fg = c.pri_3 },
    NvimTreeFolderIcon = "Directory",
    NvimTreeGitNewIcon = { fg = c.pri_3 },
    NvimTreeGitDirtyIcon = { fg = c.pri_4 },
  }

  -- gitsigns
  H.gitsigns = {
    GitSignsChangedelete = { bg = c.hl_3 },
    GitSignsStagedAdd = "GitSignsAdd",
    GitSignsStagedDelete = "GitSignsDelete",
    GitSignsStagedChange = "GitSignsChange",
    GitSignsStagedChangedelete = "GitSignsChangedelete",
  }

  -- neogit
  H.neogit_highlights = {
    -- branch-like
    NeogitBranch = { fg = c.black, underline = true },
    NeogitRemote = { fg = c.tone_2, underline = true },
    NeogitBranchHead = { fg = c.black, underline = true },
    NeogitTagName = { fg = sem.text_tag },

    -- object-like
    -- TODO factor common git items out to share with e.g. blame
    NeogitObjectId = { fg = sem.text_tag_alt },

    NeogitChangeAdded = { fg = c.pri_3, bold = true, italic = true },
    NeogitChangeCopied = { fg = c.pri_5, bold = true, italic = true },
    NeogitChangeDeleted = { fg = c.pri_1, bold = true, italic = true },
    NeogitChangeModified = { fg = c.pri_5, bold = true },
    NeogitChangeNewFile = { fg = c.pri_3, bold = true, italic = true },
    NeogitChangeRenamed = { fg = c.pri_5, bold = true, italic = true },
    NeogitChangeUnmerged = { fg = c.pri_0, bold = true, italic = true },
    NeogitChangeUnstaged = { fg = c.pri_4, bold = true, italic = true },
    NeogitChangeUpdated = { fg = c.pri_4, bold = true, italic = true },
    NeogitCommitViewHeader = { fg = c.fg_dark, bg = c.hl_7 },
    NeogitCommitViewDescription = { fg = c.fg_dark, bold = true },
    NeogitDiffAdd = { fg = c.fg_dark, bg = c.hl_5 },
    NeogitDiffAddCursor = { fg = c.fg_dark, bg = c.hl_5 },
    NeogitDiffAddHighlight = { fg = c.fg_dark, bg = c.hl_5 },
    NeogitDiffAdditions = { bg = c.hl_5, fg = c.fg_dark },
    NeogitDiffContext = { bg = c.bg_3 },
    NeogitDiffContextCursor = { bg = c.bg_3 },
    NeogitDiffContextHighlight = { bg = c.bg_3 },
    NeogitDiffDelete = { fg = c.fg_light, bg = c.hl_2 },
    NeogitDiffDeleteCursor = { fg = c.fg_dark, bg = c.hl_2 },
    NeogitDiffDeleteHighlight = { fg = c.fg_dark, bg = c.hl_2 },
    NeogitDiffDeletions = { bg = c.hl_2, fg = c.fg_dark },
    NeogitDiffHeader = { fg = c.pri_5, bg = c.bg_3, bold = true },
    NeogitDiffHeaderHighlight = { fg = c.pri_4, bg = c.bg_3, bold = true },
    NeogitFilePath = { fg = c.pri_5 },
    NeogitFloatHeader = { bg = c.bg_dark, bold = true },
    NeogitFloatHeaderHighlight = { fg = c.pri_5, bg = c.bg_3, bold = true },
    NeogitGraphAuthor = { fg = c.tone_2 },
    NeogitGraphBlue = { fg = c.tone_5 },
    NeogitGraphBoldBlue = { fg = c.pri_5, bold = true },
    NeogitGraphBoldCyan = { fg = c.pri_4, bold = true },
    NeogitGraphBoldGray = { fg = c.neutral, bold = true },
    NeogitGraphBoldGreen = { fg = c.pri_3, bold = true },
    NeogitGraphBoldOrange = { fg = c.pri_2, bold = true },
    NeogitGraphBoldPurple = { fg = c.pri_0, bold = true },
    NeogitGraphBoldRed = { fg = c.pri_1, bold = true },
    NeogitGraphBoldWhite = { fg = c.white, bold = true },
    NeogitGraphBoldYellow = { fg = c.pri_2, bold = true },
    NeogitGraphCyan = { fg = c.tone_4 },
    NeogitGraphGray = { fg = c.neutral },
    NeogitGraphGreen = { fg = c.tone_3 },
    NeogitGraphOrange = { fg = c.tone_2 },
    NeogitGraphPurple = { fg = c.tone_0 },
    NeogitGraphRed = { fg = c.pri_1 },
    NeogitGraphWhite = { fg = c.white },
    NeogitGraphYellow = { fg = c.tone_2 },
    NeogitHunkHeader = { fg = c.fg_dark, bg = c.hl_7, bold = true },
    NeogitHunkHeaderCursor = { fg = c.fg_dark, bg = c.hl_0, bold = true },
    NeogitHunkHeaderHighlight = { fg = c.fg_dark, bg = c.hl_0, bold = true },
    NeogitHunkMergeHeader = { fg = c.fg_dark, bg = c.hl_7, bold = true },
    NeogitHunkMergeHeaderCursor = { fg = c.fg_dark, bg = c.hl_7, bold = true },
    NeogitHunkMergeHeaderHighlight = { fg = c.fg_dark, bg = c.hl_0, bold = true },
    NeogitPopupBold = { bold = true },
    NeogitPopupActionKey = { fg = c.ult_1, bold = true },
    NeogitPopupConfigKey = "NeogitPopupActionKey",
    NeogitPopupOptionKey = "NeogitPopupActionKey",
    NeogitPopupSwitchKey = "NeogitPopupActionKey",
    NeogitSubtitleText = { bg = c.black },
    NeogitSectionHeader = { fg = c.fg_dark },
    NeogitTagDistance = { fg = c.tone_2 },
    NeogitUnmergedInto = { fg = c.pri_5, bold = true },
    NeogitUnpulledFrom = { fg = c.pri_5, bold = true },
    NeogitUnpushedTo = { fg = c.pri_5, bold = true },
  }

  -- dapui
  H.dapui_highlights = {
    DapUIScope = { fg = c.pri_4 },
    DapUIType = { fg = c.pri_0 },
    DapUIValue = "Normal",
    DapUIModifiedValue = { fg = c.pri_4, bold = true },
    DapUIDecoration = { fg = c.pri_4 },
    DapUIThread = { fg = c.pri_3 },
    DapUIStoppedThread = { fg = c.tone_2 },
    DapUIFrameName = "Normal",
    DapUISource = { fg = sem.nav_file },
    DapUILineNumber = { fg = sem.nav_guide_lowkey },
    DapUIBreakpointsLine = "DapUILineNumber",
    DapUIFloatNormal = "NormalFloat",
    DapUIFloatBorder = { fg = c.pri_4 },
    DapUIWatchesEmpty = { fg = c.pri_1 },
    DapUIWatchesValue = { fg = c.pri_3 },
    DapUIWatchesError = { fg = c.pri_1 },
    DapUIBreakpointsPath = "Directory",
    DapUIBreakpointsInfo = { fg = c.pri_3 },
    DapUIBreakpointsCurrentLine = { fg = c.pri_3, bold = true },
    DapUIBreakpointsDisabledLine = { fg = c.neutral },
    DapUICurrentFrameName = "DapUIBreakpointsCurrentLine",
    DapUIStep = { fg = c.pri_4 },
    DapUIStepOver = "DapUIStep",
    DapUIStepInto = "DapUIStep",
    DapUIStepBack = "DapUIStep",
    DapUIStepOut = "DapUIStep",
    DapUIStop = { fg = c.pri_1 },
    DapUIPlayPause = { fg = c.pri_3 },
    DapUIRestart = { fg = c.pri_3 },
    DapUIUnavailable = { fg = c.neutral },
    DapUIWinSelect = { fg = c.pri_4, bold = true },
    DapUIEndofBuffer = "EndOfBuffer",
    DapUINormalNC = { bg = c.dbg_3, link = "Normal" },
    DapUIPlayPauseNC = { fg = c.pri_3, bg = c.dbg_3 },
    DapUIRestartNC = { fg = c.pri_3, bg = c.dbg_3 },
    DapUIStopNC = { fg = c.pri_1, bg = c.dbg_3 },
    DapUIUnavailableNC = { fg = c.neutral, bg = c.dbg_3 },
    DapUIStepNC = { fg = c.pri_4, bg = c.dbg_3 },
    DapUIStepOverNC = "DapUIStepNC",
    DapUIStepIntoNC = "DapUIStepNC",
    DapUIStepBackNC = "DapUIStepNC",
    DapUIStepOutNC = "DapUIStepNC",
    SignatureMarkText = { fg = c.pri_3, bg = c.pri_4 },
  }

  -- diffview
  H.diffview = {
    DiffViewSecondary = { fg = c.pri_1 },
    DiffViewFilePanelTitle = { bold = true },
    DiffViewFilePanelCounter = "Number",
    DiffviewFilePanelFileName = { fg = c.fg },
    DiffViewFilePanelSelected = { fg = c.black, bg = sem.bg_tree_selected },
  }

  -- trouble
  H.trouble = {
    TroubleCode = { fg = sem.text_tag },
    TroubleDiagnosticsItemSource = { fg = sem.text_tag_alt },
    TroubleDiagnosticsPos = { fg = sem.nav_guide_lowkey },
  }

  -- Set highlight groups
  M.highlights = H
  function M.apply_highlights()
    -- theme cursor correctly
    vim.cmd("set guicursor=n-v-c:block-Cursor,i:ver1-ICursor")

    for _, highlight_group in pairs(H) do
      for key, hl in pairs(highlight_group) do
        if type(hl) == "string" then
          vim.api.nvim_set_hl(0, key, { link = hl })
        else
          vim.api.nvim_set_hl(0, key, hl)
        end
      end
    end
  end

  -- SIGNS
  -- Existing dap_signs definition
  S.dap_signs = {
    DapBreakpoint = { text = "O", texthl = "Breakpoint" },
    DapBreakpointCondition = { text = "O", texthl = "BreakpointCondition" },
    DapStopped = { text = ">", texthl = "Breakpoint", linehl = "DiagnosticWarn" },
    DapBreakpointRejected = { text = "X", texthl = "Comment" },
  }

  M.signs = S
  function M.apply_signs()
    for _, sign_group in pairs(M.signs) do
      for sign_name, sign_def in pairs(sign_group) do
        vim.fn.sign_define(sign_name, sign_def)
      end
    end
  end
end

-- TODO package as plugin, move the above to setup step
return M
