local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

local latex_augroup = vim.api.nvim_create_augroup("LaTeX", { clear = true })

vim.api.nvim_create_autocmd({"BufNewFile", "BufRead"}, {
    pattern = "*.tex",
    group = latex_augroup,
    callback = function()
        -- Create build directory in the current file's directory
        local build_dir = vim.fn.expand("%:p:h") .. "/.latex-build"
        vim.fn.system("mkdir -p " .. build_dir)
        
        -- If this is a new file, add template
        if vim.fn.expand("%:p:h:t") == "BufNewFile" then
            -- Get the template content
            local template_path = vim.fn.stdpath("config") .. "/templates/template.tex"
            local template = vim.fn.readfile(template_path)
            
            -- Insert template content
            vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
            
            -- Copy style file if it doesn't exist in current directory
            local style_source = vim.fn.stdpath("config") .. "/templates/mystyle.sty"
            local style_dest = vim.fn.expand("%:p:h") .. "/mystyle.sty"
            
            if vim.fn.filereadable(style_dest) == 0 then
                vim.fn.system(string.format("cp %s %s", style_source, style_dest))
            end
        end
    end
})

-- Setup LaTeX keybindings
vim.api.nvim_create_autocmd("FileType", {
    pattern = "tex",
    group = latex_augroup,
    callback = function()
        -- Compile with pdflatex using output directory
        vim.api.nvim_buf_set_keymap(0, 'n', '<leader>c', 
            ':!pdflatex -shell-escape -output-directory=.latex-build % && cp .latex-build/%:t:r.pdf ./<CR>', 
            {noremap = true, silent = false})
            
        -- Open PDF with zathura
        vim.api.nvim_buf_set_keymap(0, 'n', '<leader>v', 
            ':!zathura %:r.pdf &<CR><CR>', 
            {noremap = true, silent = true})
            
        -- Clean auxiliary files
        vim.api.nvim_buf_set_keymap(0, 'n', '<leader>C',
            ':!rm -rf .latex-build/*<CR>',
            {noremap = true, silent = true})
    end
})

vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
     
    {
        "nvim-telescope/telescope.nvim", 
        dependencies = "tsakirist/telescope-lazy.nvim"
    },
    {
        "nvim-lua/plenary.nvim",
    },
    {
        'neovim/nvim-lspconfig',
        dependencies = {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
        },

        config = function()
            -- Add LaTeX specific keybindings
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "tex",
                callback = function()
                    -- Compile with pdflatex
                    vim.api.nvim_buf_set_keymap(0, 'n', '<leader>c', ':!pdflatex %<CR>', {noremap = true, silent = false})
                    -- Open PDF with zathura
                    vim.api.nvim_buf_set_keymap(0, 'n', '<leader>v', ':!zathura %:r.pdf &<CR><CR>', {noremap = true, silent = true})
                end
            })
        end
    },
    {
    'goolord/alpha-nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local alpha = require('alpha')
        local dashboard = require('alpha.themes.dashboard')

        -- Function to get date and time
        local function get_date()
            return os.date(" %d-%m-%Y   %H:%M:%S")
        end

        dashboard.section.header.val = {
            [[                                                                       ]],
            [[  _    _     __          ___  __  _______ _    _         _    _      ]],
            [[ | |  | |   /\ \        / / |/ / |__   __| |  | |  /\   | |  | |    ]],
            [[ | |__| |  /  \ \  /\  / /| ' /     | |  | |  | | /  \  | |__| |    ]],
            [[ |  __  | / /\ \ \/  \/ / |  <      | |  | |  | |/ /\ \ |  __  |    ]],
            [[ | |  | |/ ____ \  /\  /  | . \     | |  | |__| / ____ \| |  | |    ]],
            [[ |_|  |_/_/    \_\/  \/   |_|\_\    |_|   \____/_/    \_\_|  |_|    ]],
            [[                                                                       ]],
        }

        -- Set colors
        vim.api.nvim_set_hl(0, 'AlphaHeader', { fg = '#89b4fa' }) -- You can change the color here
        dashboard.section.header.opts.hl = 'AlphaHeader'
            -- Get info
        local function getInfo()
            local plugins = #vim.tbl_keys(require("lazy").plugins())
            local v = vim.version()
            local datetime = get_date()
            
            return {
                "                                   ",
                " " .. datetime,
                "                                   ",
                " " .. plugins .. " plugins installed",
                " Neovim v" .. v.major .. "." .. v.minor .. "." .. v.patch,
                "                                   ",
            }
        end

        -- Set menu
        dashboard.section.buttons.val = {
            dashboard.button("n", "  New file", ":ene <BAR> startinsert <CR>"),
            dashboard.button("f", "  Find file", ":Files<CR>"),
            dashboard.button("r", "  Recent files", ":History<CR>"),
            dashboard.button("t", "  Find text", ":Rg<CR>"),
            dashboard.button("s", "  Settings", ":e $MYVIMRC <CR>"),
            dashboard.button("u", "  Update plugins", ":Lazy sync<CR>"),
            dashboard.button("q", "  Quit", ":qa<CR>"),
        }

        -- Set footer
        dashboard.section.footer.val = getInfo()

        -- Set colors
        vim.api.nvim_set_hl(0, 'AlphaHeader', { fg = '#89b4fa' })
        vim.api.nvim_set_hl(0, 'AlphaButtons', { fg = '#a6e3a1' })
        vim.api.nvim_set_hl(0, 'AlphaFooter', { fg = '#cba6f7' })

        -- Apply colors
        dashboard.section.header.opts.hl = 'AlphaHeader'
        dashboard.section.buttons.opts.hl = 'AlphaButtons'
        dashboard.section.footer.opts.hl = 'AlphaFooter'

        -- Set layout
        dashboard.config.layout = {
            { type = "padding", val = 2 },
            dashboard.section.header,
            { type = "padding", val = 2 },
            dashboard.section.buttons,
            { type = "padding", val = 2 },
            dashboard.section.footer,
        }

        -- Disable folding for alpha buffer
        vim.cmd([[
            autocmd FileType alpha setlocal nofoldenable
        ]])

        -- Setup alpha
        alpha.setup(dashboard.opts)
    end
}, 

    -- Theme
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = false, -- Changed to false for richer colors
        dim_inactive = {
          enabled = true,
          shade = "dark",
          percentage = 0.15,
        },
        styles = {
          comments = { "italic" },
          conditionals = { "italic" },
          loops = { "italic" },
          functions = { "italic" },
          keywords = { "italic" },
          strings = { "italic" },
          variables = { "italic" },
          numbers = { "italic" },
          booleans = { "italic" },
          properties = { "italic" },
          types = { "italic" },
        },
        integrations = {
          treesitter = true,
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
            },
          },
          cmp = true,
          gitsigns = true,
          nvimtree = true,
          telescope = true,
          markdown = true,
          mason = true,
        }
      })
    end
  },

  -- Treesitter for better syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { 
          "lua", "vim", "vimdoc", "python", "cpp", 
          "javascript", "typescript", "html", "css" 
        },
        sync_install = false,
        auto_install = true,
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
      })
    end
  },

  -- Status line
  {
    "vim-airline/vim-airline",
    dependencies = { "vim-airline/vim-airline-themes" },
    config = function()
      vim.g.airline_powerline_fonts = 1
      vim.g.airline_section_b = '%{getcwd()}'
      vim.g.airline_theme = 'catppuccin'  -- Changed to match catppuccin
      vim.g['airline#extensions#tabline#enabled'] = 1
      vim.g['airline#extensions#tabline#formatter'] = 'unique_tail'
    end,
  },
  
  -- File explorer
  {
    "preservim/nerdtree",
  },
  
  -- Markdown preview
  {
    "iamcco/markdown-preview.nvim",
    build = "cd app && npx --yes yarn install",
    config = function()
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_theme = 'dark'
      vim.g.mkdp_filetypes = {'markdown'}
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = 'middle',
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {},
      }
    end,
  },
  
  -- Fuzzy finder
  {
    "junegunn/fzf",
    build = function()
      vim.fn["fzf#install"]()
    end,
    dependencies = { "junegunn/fzf.vim" },
    config = function()
      vim.g.fzf_vim = {
        preview_window = {'right,50%', 'ctrl-/'}
      }
    end,
  },
  
  -- REPL integration
  {
    "jpalardy/vim-slime",
    ft = "python",
    config = function()
      vim.g.slime_python_ipython = 1
    end,
  },
})
