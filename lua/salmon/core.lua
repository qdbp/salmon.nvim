--!strict
-- please see https://github.com/qdbp/SalmonTheme?tab=readme-ov-file#the-restraint-scheme for an explanation for the motivation and design language used here

---@class HlGroup
---@field fg? string # Foreground color (hex or name)
---@field bg? string # Background color (hex or name)
---@field sp? string # Special color (hex or name)
---@field bold? boolean # Bold text
---@field italic? boolean # Italic text
---@field underline? boolean # Underlined text
---@field undercurl? boolean # Undercurled text
---@field underdouble? boolean # Double underlined text
---@field underdotted? boolean # Dotted underlined text
---@field strikethrough? boolean # Strikethrough text
---@field reverse? boolean # Reverse colors
---@field cterm? table # Terminal attributes
---@field blend? integer # Transparency (0-100)
---@field nocombine? boolean # Don't combine with other highlights

---@class SignDefinition
---@field text string The character(s) to display in the sign column
---@field texthl? string Name of the highlight group for the sign text
---@field numhl? string Name of the highlight group for the number column
---@field linehl? string Name of the highlight group for the whole line
---@field culhl? string Name of the highlight group used when the cursor is on the line
---@field icon? string Path to an icon file to display (GUI only)
---@field priority? integer Sign priority for overlapping signs

---@class HlTable
---@field [string] {[string]: string | HlGroup}

---@class SignTable
---@field [string] {[string]: SignDefinition}

---@class Salmon
---@field H HlTable Table containing all highlight groups
---@field S SignTable SignDefinition Table containing all sign definitions
---@field build_from_palette function Builds the color scheme from a given palette
---@field apply_highlights function Sets all highlight groups
---@field apply_signs function Sets all sign definitions
local M = {}

---@type HlTable
H = {} -- highlights definitions

---@type SignTable
S = {} -- signs definitions

function M.build_from_palette(palette)
  local c = palette.colors

  -- first we define some semantic indirection tables
  -- that lets us refer to colors by their indended use
  -- and swap out large swatches at once if needed in a consistent way

  -- semantic color table
  local sc = {

    -- THEME
    bg_base = c.bg_3,
    bg_alt = c.bg_1,
    bg_editable = c.bg,

    bg_tree_selected = c.hlbg_7,
    bg_selected = c.wht_7,
    bg_active = c.wht_5,
    bg_entry = c.wht_4,

    text_lowkey = c.fg_light,
    text_focus = c.black,
    text_tag = c.tone_5, -- labels, identifiers, enums
    text_tag_alt = c.tone_1, -- alternate tag when several types of tags are present

    nav_file = c.fg_dark,
    nav_dir = c.pri_5,
    nav_guide_lowkey = c.tint_0, -- deemphasized guides: aligners, indices into text, etc.

    bg_fail = c.hl_2,
    bg_pending = c.hl_4,
    bg_warn = c.hl_3,
    bg_success = c.hl_5,
    bg_missing = c.bg_darker,

    text = {
      infobox = { bg = c.wht_7 },
      entry = { bg = c.wht_5 },
      results = { bg = c.wht_2 },
    },

    diff = {
      plus = c.hl_5,
      change = c.hl_7,
      minus = c.hl_2,
      delete = c.bg_darker,
    },

    diff_subtle = {
      plus = c.hlbg_5,
      change = c.hlbg_7,
      minus = c.hlbg_2,
      delete = c.bg_darker,
    },

    diag = {
      bg = {
        ok = c.hl_6,
        minor = c.tint_5,
        hint = c.bg_7,
        warn = c.hyperhl_3,
        err = c.hyperhl_2,
      },
      ul = {
        ok = c.hl_6,
        minor = c.tint_5,
        hint = c.shd_7,
        warn = c.hyperhl_3,
        err = c.hyperhl_2,
      },
    },

    hint = {
      faint = { fg = c.shd_7 },
      inlay = { fg = c.fg_light, italic = true },
    },
  }

  -- then we define our highlighting scheme at a high level
  -- we coordinate the meanings of the colors here with respect to these
  -- more abstract concepts. This way every language will have a consistent
  -- feel.
  local hl = {
    -- core
    keyword = { fg = c.black, bold = true },
    metadata = { fg = c.ult_1 },
    label = { fg = c.ult_2, bold = true },
    namespace = { fg = c.tint_3 },
    lifetime = { fg = c.tint_1, italic = true },
    macro = { fg = c.pri_0, bold = true },
    -- punctuation
    -- this is defined semantically, not literally
    punc = {
      -- separators ought to be very unostrusive
      separator = { fg = c.fg_light },
      -- brackets are visible but not overdone
      -- this should be overriden by language settings, since the desired weight
      -- varies a lot by language and bracket type.
      bracket = { fg = c.black },
      -- operators are like keywords and calls. major control flow requireing major weight.
      operator = { fg = c.black, bold = true },
    },
    -- literals (ex. string)
    lit = {
      int = { fg = c.tone_1 },
      float = { fg = c.tone_1 },
      bool = { fg = c.tone_1, bold = true },
    },
    -- type level identifiers
    -- design: muted colors. redder are more literal like, bluer are more abstract
    -- exception: avoid very string-like green
    cls = {
      param = { fg = c.tone_0 },
      struct = { fg = c.tone_1 },
      enum = { fg = c.tone_1 },
      interface = { fg = c.tone_3, italic = true },
      abstract = { fg = c.tone_4 },
      class = { fg = c.tone_5 },
    },
    -- variable level identifiers
    -- brighter colors for special varables
    -- the one notable design decision: black for all functions and method
    -- this makes the call skeleton of the program really stand out and feel "serious"
    -- I would argue this is the aesthetic crux of the entire theme!
    var = {
      -- basic, neutral, restrained
      var = { fg = c.fg_dark },
      fun = { fg = c.black },
      method = { fg = c.black },
      -- more colorful, special
      -- TODO should member not be a mod?
      param = { fg = c.pri_4 },
      member = { fg = c.pri_1 },
      constant = { fg = c.pri_5 },
      enum_member = { fg = c.ult_1 },
      -- TODO add closure
      captured = { fg = c.pri_3 }, -- as in by a closure
    },
    -- string like, muted greenish tones all round
    str = {
      str = { fg = c.tone_3 },
      doc = { fg = c.tint_2, bold = true },
      special = { fg = c.tone_4, bold = true },
      regex = { fg = c.pri_2, bold = true },
      comment = { fg = c.fg_light },
      todo = { fg = c.tint_1, bold = true },
    },
    -- modifiers
    mod = {
      builtin = { fg = c.pri_0 },
      -- again the BIG aesthetic decision here. make control flow pop!
      call = { bold = true },
    },
  }

  -- *** SEMANTIC HIGHLIGHTING (SCHEME) ***
  H.base_scheme = {
    -- we have a hierarchy of truth for highlighting information
    -- at the apex are LSP semantic token highlights
    -- LSP
    -- lsp mods
    ["@lsp.mod.builtin"] = hl.mod.builtin,
    -- TODO this doesn't work, need to use a callback to handle it properly!
    -- or better, fix upstream
    -- ['@lsp.mod.definition'] = { bold = false },

    -- lsp types
    ["@lsp.type.comment"] = hl.str.comment,
    ["@lsp.type.unknown"] = { fg = c.fg_dark },
    -- text-like
    -- literal-like
    ["@lsp.type.boolean"] = hl.lit.bool,
    ["@lsp.type.number"] = hl.lit.int,
    ["@lsp.type.string"] = hl.str.str,
    ["@lsp.type.character"] = hl.str.str,
    ["@lsp.type.regexp"] = hl.str.regex,
    -- class-like
    ["@lsp.type.enum"] = hl.cls.enum,
    ["@lsp.type.interface"] = hl.cls.interface,
    ["@lsp.type.class"] = hl.cls.class,
    ["@lsp.type.struct"] = hl.cls.struct,
    ["@lsp.type.typeParameter"] = hl.cls.param,
    -- function-like
    ["@lsp.type.function"] = hl.var.fun,
    ["@lsp.type.method"] = hl.var.method,
    -- variable-like
    ["@lsp.type.variable"] = hl.var.var,
    ["@lsp.type.constant"] = hl.var.constant,
    -- TODO is builtin also a type or only a mod?
    ["@lsp.type.builtin"] = hl.mod.builtin,
    ["@lsp.type.parameter"] = hl.var.param,
    ["@lsp.type.property"] = hl.var.member,
    ["@lsp.type.enumMember"] = hl.var.enum_member,
    -- control flow-like
    ["@lsp.type.keyword"] = hl.keyword,
    ["@lsp.type.operator"] = hl.keyword,
    ["@lsp.type.macro"] = hl.macro,
    ["@lsp.type.label"] = hl.label,
    -- metaprogramming and scoping-like
    ["@lsp.type.decorator"] = hl.metadata,
    ["@lsp.type.namespace"] = hl.namespace,
    -- TODO hl entry
    ["@lsp.type.lifetime"] = hl.lifetime,

    -- base
    -- TODO fill out all entries from vim docs
    Comment = "@lsp.type.comment",
    Todo = hl.str.todo,
    Constant = "@lsp.constant",

    -- primitives
    String = "@lsp.string",
    Character = "@lsp.type.regexp",
    Special = "@lsp.type.regexp",
    SpecialChar = hl.str.special,
    Number = "@lsp.type.number",
    Float = "@lsp.typenumber",
    Boolean = "@lsp.typeboolean",

    -- variables
    Identifier = "@lsp.variable",
    Function = "@lsp.function",
    Metadata = hl.metadata,
    PreProc = hl.metadata,
    Define = hl.macro,
    Macro = hl.macro,
    Include = hl.macro,

    -- conrol flow
    Keyword = hl.keyword,
    Statement = hl.keyword,
    Conditional = hl.keyword,
    Repeat = hl.keyword,
    Label = hl.label,
    Operator = hl.keyword,

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

    -- Hints and similar (mostly LSP)
    LspCodeLens = sc.hint.faint,
    LspInlayHint = sc.hint.inlay,

    LspSignatureActiveParameter = { underline = true, bold = true, sp = c.black },

    LspReferenceText = "LspReferenceRead",
    LspReferenceRead = { bg = c.hl_0 },
    LspReferenceWrite = { bg = c.hl_5 },

    -- TREESITTER
    -- note: most of these should be defined in links pointing back to LSP
    -- only add cases here that are not well-covered by LSP
    ["@comment"] = hl.str.comment,

    -- TODO unsorted

    -- variable-like
    ["@attribute"] = hl.metadata,
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
    ["@method"] = hl.var.method,
    ["@function.call"] = hl.mod.call,
    ["@function.method.call"] = hl.mod.call,

    -- namespace-like
    ["@namespace"] = hl.namespace,
    ["@module"] = hl.namespace,

    ["@number"] = hl.lit.int,
    ["@number.float"] = hl.lit.float,
    ["@string"] = hl.str.str,
    ["@string.documentation"] = hl.str.doc,
    ["@string.regex"] = hl.str.regex,
    ["@string.escape"] = hl.str.special,
    ["@tag"] = "@lsp.type.keyword",
    ["@tag.attribute"] = "@lsp.type.property",
    ["@tag.delimiter"] = "@lsp.type.operator",
    ["@text"] = "@lsp.type.variable",
    ["@type"] = "@lsp.type.class",
    ["@type.builtin"] = "@lsp.mod.builtin",

    -- TODO break these out to other files
    -- language specific
    -- C/C++
    ["@attribute.cpp"] = { fg = c.tint_1 }, -- make it less garish

    -- Python
    ["@punctuation.delimiter.python"] = "@lsp.type.keyword", -- needs this weight
    ["@constant.builtin.python"] = "@lsp.type.keyword", -- needs this weight
    ["@keyword.import.python"] = "@lsp.type.keyword",
    -- TODO need a general solution for this `@spell` issue...
    ["@spell.python"] = "Comment",
    -- ["@lsp.mod.readonly.python"] = "@lsp.type.constant",

    -- JAVA
    ["@lsp.type.modifier.java"] = hl.keyword,

    -- RUST
    -- everything in rust is a struct so we spread the colors out to make it less red
    ["@lsp.type.struct.rust"] = hl.cls.class,
    -- ["@lsp.type.selfKeyword.rust"] = hl.var.captured,

    -- yaml
    ["@property.yaml"] = { fg = c.black, bold = true },
    ["@string.yaml"] = { fg = c.tone_3 },

    -- zsh
    zshDeref = hl.var.param,
    zshString = hl.str.str,
    zshStringDelimeter = hl.str.str,
    zshPOSIXString = hl.str.str,
  }

  -- THEME: styling the window and non-code elements
  H.base_theme = {
    -- cursor tweaks
    Cursor = { fg = c.bg_light, bg = c.black },
    ICursor = { fg = c.black, bg = c.black },
    rCursor = { fg = c.ult_1, bg = c.ult_1 },

    -- basics
    Normal = { fg = c.fg_dark, bg = c.bg },
    NormalNC = { fg = c.fg },

    -- extmarks handling
    Bold = { bold = true },
    Underlined = { underline = true },

    -- separators
    WinSeparator = { fg = c.shd_3, bg = c.shd_3 },

    -- TODO move to THEME??
    Identifier = { link = "Normal" },

    -- TODO random bag of crap, sort it out
    Special = { fg = c.tone_4 },
    ErrorMsg = { fg = c.pri_1 },
    -- meta
    -- Debug = "@lsp.keyword",
    -- TODO what is this?
    Ignore = hl.str.comment,
    Error = { fg = sc.diag.err },
    Added = "@diff.plus",
    Changed = "@diff.delta",
    Removed = "@diff.minus",

    -- window tile
    WinBar = { bg = c.dbg_3, fg = c.black },
    WinBarNC = { bg = c.dbg_3, fg = c.fg },

    -- bottom of screen
    -- basic
    MsgArea = { fg = c.fg, bg = sc.bg_base },
    StatusLine = { fg = c.fg_dark, bg = sc.bg_base },
    StatusLineNC = { fg = c.fg_light, bg = sc.bg_base },
    ModeMsg = { fg = c.fg, bold = true, bg = sc.bg_base },
    MoreMsg = { fg = c.fg, bold = true, bg = sc.bg_base },

    -- left of screen, gutter, and cursor rows
    LineNr = { fg = c.fg_light, bg = sc.bg_base },
    CursorLine = { bg = c.bg_4 },
    CursorLineNR = { fg = c.tone_1, bg = sc.bg_base, bold = true },
    FoldColumn = { fg = sc.nav_guide_lowkey, bg = sc.bg_base },
    SignColumn = { link = "FoldColumn" },

    -- TODO move to semantic table, not fake groups
    -- create new generic group that any plugin can be configured to use
    IndentGuide = { fg = c.bg_2 },
    SignatureMarkText = { fg = c.hyper_0, bold = true, standout = true, bg = c.wht_0 },

    -- top of screen
    TabLineFill = { bg = sc.bg_base, fg = c.fg },
    TabLineSel = { bg = c.wht_4, fg = c.black },
    TabLine = { bg = sc.bg_base, fg = c.fg },

    -- TODO need semantic indirection here a lot of duplication happening
    -- popups and modals
    NormalFloat = { bg = c.wht_2 },
    FloatBorder = { bg = c.bg_2 },
    FloatTitle = { bg = c.bg_2 },
    FloatFooter = { bg = c.bg_2 },
    QuickFixLine = { bg = c.hlbg_7, bold = true },

    Pmenu = { fg = c.fg, bg = c.bg_7 },
    PmenuSel = { fg = c.fg, bg = c.wht_6 },
    PmenuThumb = { fg = c.fg, bg = sc.bg_base },

    -- selection, folded, search and match highlights
    Visual = { bg = c.hyperhl_7 },
    Folded = { fg = c.fg_light, bg = c.bg_7 },
    MatchParen = { bg = c.hl_7 },
    Search = { bg = c.hl_4 },

    -- DIAGNOSTICS
    -- errors
    DiagnosticError = { fg = c.black, bg = sc.diag.bg.err, bold = true },
    DiagnosticUnderlineError = { sp = sc.diag.ul.err, undercurl = true },
    DiagnosticFloatingError = { fg = c.black, sp = sc.diag.ul.err }, -- no bold
    -- warnings
    DiagnosticWarn = { fg = c.fg, bg = sc.diag.bg.warn },
    DiagnosticUnderlineWarn = { sp = sc.diag.ul.warn, undercurl = true },
    WarningMsg = { fg = c.hyper_2 },
    -- info
    DiagnosticInfo = { fg = c.fg, bg = sc.diag.bg.info },
    DiagnosticUnderlineInfo = { sp = sc.diag.ul.info, underline = true },
    -- hints
    DiagnosticHint = { fg = c.fg, bg = sc.diag.bg.hint },
    DiagnosticUnderlineHint = { sp = sc.diag.ul.hint, underline = true },
    -- ok
    DiagnosticOK = { fg = c.fg, bg = sc.diag.bg.ok },
    -- misc
    DiagnosticUnnecessary = { fg = c.fg_light, sp = sc.diag.ul.minor, undercurl = true },

    -- DEBUGGING
    Breakpoint = { fg = c.hyper_2, bold = true, bg = c.wht_6 },
    BreakpointCondition = { fg = c.hyper_1, bold = true, bg = c.wht_6 },

    -- DIFFS
    DiffAdd = { bg = sc.diff_subtle.plus },
    DiffDelete = { bg = sc.diff_subtle.delete },
    DiffChange = { bg = sc.diff_subtle.change },
    DiffTextAdd = { bg = sc.diff.add },
    DiffText = { bg = sc.diff.change },

    ["@diff.plus"] = { bg = sc.diff.plus },
    ["@diff.delta"] = { bg = sc.diff.change },
    ["@diff.minus"] = { bg = sc.diff.minus },

    -- file navigation
    Directory = { fg = sc.nav_dir },

    -- Markdown et al
    ["@markup.raw"] = {}, -- stop the garishness!
    Title = { fg = c.black, bold = true },
    Question = { fg = c.ult_5 },
  }

  -- PLUGIN SPECIFIC
  -- nvim-cmp
  H.cmp = {
    -- Pmenu items
    -- TODO this is ridiculous need to auto-generate
    -- CmpItemAbbr = { fg = c.fg_dark, bg = sc.bg_base },
    -- CmpItemAbbrMatch = { fg = c.black, bg = c.hl_3, bold = true },
    -- CmpItemAbbrMatchFuzzy = { fg = c.black, bg = c.hl_3, bold = true },
    CmpItemKindConstant = "@lsp.type.constant",
    CmpItemKindText = "Normal",
    CmpItemKindMethod = "@lsp.type.method",
    CmpItemKindFunction = "@lsp.type.function",
    CmpItemKindConstructor = "@lsp.type.class",
    CmpItemKindField = "@lsp.type.property",
    CmpItemKindVariable = "@lsp.type.variable",
    CmpItemKindClass = "@lsp.type.class",
    CmpItemKindStruct = "@lsp.type.struct",
    CmpItemKindEnum = "@lsp.type.enum",
    CmpItemKindInterface = "@lsp.type.interface",
    CmpItemKindModule = "@lsp.type.namespace",
    CmpItemKindProperty = "@lsp.type.property",
    CmpItemKindUnit = { fg = c.pri_4 },
    CmpItemKindValue = { fg = c.pri_5 },
    CmpItemKindEnumMember = "@lsp.type.enumMember",
    CmpItemKindKeyword = "Keyword",
    CmpItemKindSnippet = "Parameter",
    CmpItemKindFile = "File",
    CmpItemKindFolder = "Directory",
    -- doc items
    -- winhighlight = 'FloatNormal:CmpDoc,FloatBorder:CmpDocBorder',
    CmpDoc = sc.text.infobox,
    CmpDocBorder = sc.text.infobox, -- looks better with no frills
  }

  -- mason
  H.mason = {
    MasonHighlight = { fg = c.pri_0 },
  }

  -- snacks
  H.snacks = {
    SnacksInputNormal = sc.text.entry,
    SnacksInputBorder = "FloatBorder",
    SnacksInputTitle = "FloatTitle",
  }

  -- telescope
  H.telecope = {
    TelescopeBorder = "FloatBorder",
    TelescopeNormal = sc.text.results,
    TelescopeSelection = { fg = c.black, bg = c.hl_7 },
    TelescopeMatching = { bold = true, bg = c.hl_3 },
    TelescopePrompt = sc.text.entry,
  }

  -- nvim-tree
  H.nvim_tree = {
    NvimTreeNormal = { bg = sc.bg_base },
    NvimTreeExecFile = { fg = c.pri_1 },
    NvimTreeImageFile = { fg = c.pri_3 },
    NvimTreeFolderIcon = "Directory",
    NvimTreeGitNewIcon = { fg = c.pri_3 },
    NvimTreeGitDirtyIcon = { fg = c.pri_4 },
  }

  -- gitsigns
  H.gitsigns = {
    GitSignsChangedelete = { bg = sc.diff.minus, bold = true },
    GitSignsStagedAdd = "GitSignsAdd",
    GitSignsStagedDelete = "GitSignsDelete",
    GitSignsStagedChange = "GitSignsChange",
    GitSignsStagedChangedelete = "GitSignsChangedelete",
  }

  -- neogit
  H.neogit_highlights = {

    NeogitNormal = "NormalFloat",

    -- branch-like
    NeogitBranch = { fg = c.black, underline = true },
    NeogitRemote = { fg = c.tone_2, underline = true },
    NeogitBranchHead = { fg = c.black, underline = true },
    NeogitTagName = { fg = sc.text_tag },

    -- object-like
    -- TODO factor common git items out to share with e.g. blame
    NeogitObjectId = { fg = sc.text_tag_alt },

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

    -- diff preview
    NeogitDiffHeader = { fg = c.black, bg = c.bg_2, bold = true },
    NeogitDiffHeaderHighlight = "NeogitDiffHeader",

    NeogitHunkHeader = { fg = c.black, bg = c.bg_2 },
    NeogitHunkHeaderHighlight = "NeogitHunkHeader",
    NeogitHunkHeaderCursor = "NeogitHunkHeaderHighlight",

    NeogitDiffContext = sc.text.infobox,
    NeogitDiffContextCursor = sc.text.infobox,
    NeogitDiffContextHighlight = sc.text.infobox,

    -- TODO still seeing changes in response to cursor... need to fing hidden groups
    NeogitDiffAdd = { fg = c.fg_dark, bg = sc.diff_subtle.plus },
    NeogitDiffAddCursor = "NeogitDiffAdd",
    NEogitDiffAddHighlight = "NeogitDiffAdd",
    NeogitDiffAdditions = "NeogitDiffAdd",

    NeogitDiffDelete = { fg = c.fg_light, bg = sc.diff_subtle.delete },
    NeogitDiffDeleteCursor = "NeogitDiffDelete",
    NeogitDiffDeleteHighlight = "NeogitDiffDelete",
    NeogitDiffDeletions = "NeogitDiffDelete",

    NeogitFilePath = { fg = c.pri_5, bold = true },
    NeogitFloatHeader = { bg = c.bg_dark, bold = true },
    NeogitFloatHeaderHighlight = { fg = c.pri_5, bg = sc.bg_base, bold = true },

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

  H.neotest = {
    NeotestFile = { fg = sc.nav_file },
    NeotestDir = { fg = sc.nav_dir, bold = true },
    NeotestPassed = { bg = sc.bg_success, fg = c.black },
    NeotestFailed = { bg = sc.bg_fail, fg = c.black },
    NeotestRunning = { bg = sc.bg_pending, fg = c.black },
    NeotestSkipped = { bg = sc.bg_missing, fg = c.black },
    -- put a box around watches
    NeotestWatching = { underline = true, bold = true },
    NeotestNamespace = "@lsp.type.namespace",
    NeotestAdapterName = "@lsp.type.decorator",
    NeotestMarked = "@lsp.type.label",
    NeotestTarget = "Constant",
    -- TODO, just got rid of garishness for now
    NeotestExpandMarker = "Normal",
    NeotestWinSelect = "Normal",
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
    DapUISource = { fg = sc.nav_file },
    DapUILineNumber = { fg = sc.nav_guide_lowkey },
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
  }

  -- diffview
  H.diffview = {
    DiffviewSecondary = { fg = c.pri_1 },
    DiffviewFilePanelTitle = { bold = true },
    DiffviewFilePanelCounter = "Number",
    DiffviewFilePanelFileName = { fg = c.fg },
    DiffviewFilePanelSelected = { fg = c.black, bg = sc.bg_tree_selected },
    -- extra groups for use with  enhanced_diff_hl = true
    DiffviewDiffAddAsDelete = { bg = sc.diff_subtle.delete.bg },
    DiffviewDiffDelete = { bg = sc.diff.delete.bg },
  }

  -- trouble
  H.trouble = {
    TroubleCode = { fg = sc.text_tag },
    TroubleDiagnosticsItemSource = { fg = sc.text_tag_alt },
    TroubleDiagnosticsPos = { fg = sc.nav_guide_lowkey },
  }

  -- Set highlight groups
  M.highlights = H
  function M.apply_highlights()
    -- theme cursor correctly
    vim.cmd(
      "set guicursor=n-v-c:block-Cursor,r-cr:block-RCursor,i-ci:ver25-blinkwait200-blinkon200-blinkoff100-ICursor"
    )

    for _, block in pairs(H) do
      for key, gl in pairs(block) do
        if type(gl) == "string" then
          vim.api.nvim_set_hl(0, key, { link = gl })
        else
          vim.api.nvim_set_hl(0, key, gl)
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

  -- TODO really the palette should define e.g. ansi_0.
  -- right now we're exploiting an idisoyncracy of the existing salmon palettes
  -- but hey, first party privilege.
  function M.apply_ansi()
    vim.g.terminal_color_0 = c.black -- black
    vim.g.terminal_color_1 = c.tone_2 -- red
    vim.g.terminal_color_2 = c.tone_4 -- green
    vim.g.terminal_color_3 = c.tone_3 -- yellow
    vim.g.terminal_color_4 = c.tone_0 -- blue
    vim.g.terminal_color_5 = c.tone_1 -- magenta
    vim.g.terminal_color_6 = c.tone_5 -- cyan
    vim.g.terminal_color_7 = c.bg -- white
    vim.g.terminal_color_8 = c.fg_dark -- bright black
    vim.g.terminal_color_9 = c.ult_2 -- bright red
    vim.g.terminal_color_10 = c.ult_4 -- bright green
    vim.g.terminal_color_11 = c.ult_3 -- bright yellow
    vim.g.terminal_color_12 = c.ult_0 -- bright blue
    vim.g.terminal_color_13 = c.ult_1 -- bright magenta
    vim.g.terminal_color_14 = c.ult_5 -- bright cyan
    vim.g.terminal_color_15 = c.white -- bright white
  end
end

-- TODO package as plugin, move the above to setup step
return M
