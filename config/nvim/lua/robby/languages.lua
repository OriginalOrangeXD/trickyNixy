local lspconfig = require 'lspconfig'
local omnisharp_extended = require 'omnisharp_extended'
local rust_tools = require 'rust-tools'
local treesitter = require 'nvim-treesitter.configs'
local treesitter_context = require 'treesitter-context'
local mason = require 'mason'
local mason_lsp = require 'mason-lspconfig'
local cmp = require 'cmp'
local luasnip = require 'luasnip'

local custom_format = function()
    if vim.bo.filetype == "templ" then
        local bufnr = vim.api.nvim_get_current_buf()
        local filename = vim.api.nvim_buf_get_name(bufnr)
        local cmd = "templ fmt " .. vim.fn.shellescape(filename)

        vim.fn.jobstart(cmd, {
            on_exit = function()
                -- Reload the buffer only if it's still the current buffer
                if vim.api.nvim_get_current_buf() == bufnr then
                    vim.cmd('e!')
                end
            end,
        })
    else
        vim.lsp.buf.format()
    end
end

local function autocmd(args)
    local event = args[1]
    local group = args[2]
    local callback = args[3]

    vim.api.nvim_create_autocmd(event, {
        group = group,
        buffer = args[4],
        callback = function()
            callback()
        end,
        once = args.once,
    })
    vim.api.nvim_create_autocmd({ "BufWritePre" }, { pattern = { "*.templ" }, callback = custom_format })
end

local function on_attach(client, buffer)
    local augroup_highlight = vim.api.nvim_create_augroup("custom-lsp-references", { clear = true })
    local autocmd_clear = vim.api.nvim_clear_autocmds

    local opts = { buffer = buffer, remap = false }

    -- Enable completion triggered by <c-x><c-o>
    vim.bo[buffer].omnifunc = 'v:lua.vim.lsp.omnifunc'

    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<leader>wl', function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<leader>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)

    if client.server_capabilities.documentHighlightProvider then
        autocmd_clear { group = augroup_highlight, buffer = buffer }
        autocmd { "CursorHold", augroup_highlight, vim.lsp.buf.document_highlight, buffer }
        autocmd { "CursorMoved", augroup_highlight, vim.lsp.buf.clear_references, buffer }
    end
end

local function init()

    -- Rust specific setup
    rust_tools.setup {
        server = {
            settings = {
                ['rust-analyzer'] = {
                    cargo = {
                        buildScripts = {
                            enable = true,
                        },
                    },
                    diagnostics = {
                        enable = false,
                    },
                    files = {
                        excludeDirs = { ".direnv", ".git" },
                        watcherExclude = { ".direnv", ".git" },
                    },
                },
            },
            on_attach = on_attach,
        },
    }

    local language_servers = {
        bashls = {},
        cssls = {},
        templ = {},
        dagger = {},
        diagnosticls = {
            filetypes = { "python" },
            init_options = {
                filetypes = {
                    python = "black"
                },
                formatFiletypes = {
                    python = { "black" }
                },
                formatters = {
                    black = {
                        command = "black",
                        args = { "--quiet", "-" },
                        rootPatterns = { "pyproject.toml" },
                    },
                },
            }
        },
        dockerls = {},
        gopls = {
            settings = {
                gopls = {
                    gofumpt = true,
                },
            },
        },
        hls = {},
        html = {
            filetypes = { "html", "templ" },
        },
        htmx = {
            filetypes = { "html", "templ" },
        },
        tailwindcss = {
            filetypes = { "templ", "astro", "javascript", "typescript", "react" },
            init_options = { userLanguages = { templ = "html" } },
        },
        jsonls = {},
        jsonnet_ls = {},
        lua_ls = {
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { 'vim' }
                    },
                    runtime = {
                        version = 'LuaJIT',
                    },
                    telemetry = {
                        enable = false,
                    },
                    workspace = {
                        library = vim.api.nvim_get_runtime_file("", true),
                    },
                },
            }
        },
        nil_ls = {
            settings = {
                ['nil'] = {
                    formatting = { command = { "nixpkgs-fmt" } },
                },
            }
        },
        omnisharp = {
            cmd = { "omnisharp", "--languageserver", "--hostPID", tostring(vim.fn.getpid()) },
            handlers = {
                ["textDocument/definition"] = omnisharp_extended.handler,
            },
        },
        pyright = {
            settings = {
                python = {
                    analysis = {
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        useLibraryCodeForTypes = true
                    },
                },
            },
        },
        terraformls = {},
        tsserver = {},
        yamlls = {
            settings = {
                yaml = {
                    keyOrdering = false,
                },
            },
        },
    }

    -- Initialize servers
    for server, server_config in pairs(language_servers) do
        local config = { on_attach = on_attach }

        if server_config then
            for k, v in pairs(server_config) do
                config[k] = v
            end
        end

        lspconfig[server].setup(config)
    end

    -- Global mappings.
    -- See `:help vim.diagnostic.*` for documentation on any of the below functions
    vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
    vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

    vim.filetype.add({ extension = { templ = "templ" } })

    treesitter.setup {
        highlight = { enable = true },
        indent = { enable = true },
        rainbow = { enable = true },
    }

    treesitter_context.setup()
    cmp.setup({
        completetion = {
            completeopt = "menu,menuone,preview,noselect",
        },
        snippet = {
            -- REQUIRED - you must specify a snippet engine
            expand = function(args)
                luasnip.lsp_expand(args.body) -- For `luasnip` users.
            end,
        },
        mapping = cmp.mapping.preset.insert({
            ['<C-b>'] = cmp.mapping.scroll_docs(-4),
            ['<C-f>'] = cmp.mapping.scroll_docs(4),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<C-e>'] = cmp.mapping.abort(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
        }),
        sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'luasnip' }, -- For luasnip users.
        }, {
                { name = 'buffer' },
            })
    })
    luasnip.setup() 

    mason.setup()
    mason_lsp.setup({
    ensure_installed = {
        "gopls",
        },
    automatic_installation = true,
    }
    )
end

return {
    init = init,
}
