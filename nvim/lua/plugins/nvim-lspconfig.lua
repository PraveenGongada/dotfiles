return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for Neovim
		{ "williamboman/mason.nvim" }, -- NOTE: Must be loaded before dependants

		-- Allows extra capabilities provided by nvim-cmp
		"hrsh7th/cmp-nvim-lsp",
	},
	config = function()
		require("nvchad.lsp")
		local lspconfig = require("lspconfig")
		local util = require("lspconfig/util")

		-- export on_attach & capabilities for custom lspconfigs
		local on_attach = function(client, _)
			if client.server_capabilities.signatureHelpProvider then
				require("nvchad.lsp.signature").setup(client)
			end
		end

		-- disable semantic tokens
		local on_init = function(client, _)
			if client.supports_method("textDocument/semanticTokens") then
				client.server_capabilities.semanticTokensProvider = nil
			end
		end

		local capabilities = vim.lsp.protocol.make_client_capabilities()

		capabilities.textDocument.completion.completionItem = {
			documentationFormat = { "markdown", "plaintext" },
			snippetSupport = true,
			preselectSupport = true,
			insertReplaceSupport = true,
			labelDetailsSupport = true,
			deprecatedSupport = true,
			commitCharactersSupport = true,
			tagSupport = { valueSet = { 1 } },
			resolveSupport = {
				properties = {
					"documentation",
					"detail",
					"additionalTextEdits",
				},
			},
		}

		-- LSP Diagnostics
		vim.diagnostic.config({
			update_in_insert = false,
			virtual_text = {
				spacing = 4,
				source = "if_many",
				prefix = "●",
			},
			float = {
				border = "rounded",
			},
		})

		-- Lua
		lspconfig.lua_ls.setup({
			on_init = on_init,
			on_attach = on_attach,
			capabilities = capabilities,
			cmd = { "lua-language-server" },
			filetypes = { "lua" },
			single_file_support = true,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
				},
			},
		})

		-- Golang
		lspconfig.gopls.setup({
			on_init = on_init,
			on_attach = on_attach,
			capabilities = capabilities,
			cmd = { "gopls" },
			single_file_support = true,
			filetypes = { "go", "gomod", "gowork", "gotmpl" },
			root_dir = util.root_pattern("go.work", "go.mod"),
			settings = {
				gopls = {
					completeUnimported = true,
					usePlaceholders = true,
					gofumpt = true,
				},
			},
		})

		-- TypeScript
		lspconfig.ts_ls.setup({
			on_init = on_init,
			on_attach = on_attach,
			capabilities = capabilities,
			filetypes = { "typescript", "typescriptreact", "typescript.tsx" },
			cmd = { "typescript-language-server", "--stdio" },
		})

		-- tailwind
		lspconfig.tailwindcss.setup({
			on_init = on_init,
			on_attach = on_attach,
			capabilities = capabilities,
		})

		-- css
		lspconfig.cssls.setup({
			on_init = on_init,
			on_attach = on_attach,
			capabilities = capabilities,
		})

		-- Mappings
		local keymap = vim.keymap

		keymap.set("n", "gD", function()
			vim.lsp.buf.declaration()
		end, { desc = "LSP declaration" })
		keymap.set("n", "gd", function()
			vim.lsp.buf.definition()
		end, { desc = "LSP definition" })
		keymap.set("n", "K", function()
			vim.lsp.buf.hover()
		end, { desc = "LSP hover" })
		keymap.set("n", "gi", function()
			vim.lsp.buf.implementation()
		end, { desc = "LSP implementation" })
		keymap.set("n", "<leader>lh", function()
			vim.lsp.buf.signature_help()
		end, { desc = "LSP signature help" })
		keymap.set("n", "<leader>D", function()
			vim.lsp.buf.type_definition()
		end, { desc = "LSP definition type" })
		keymap.set("n", "<leader>rn", function()
			require("nvchad.lsp.renamer")
		end, { desc = "LSP renamer" })
		keymap.set("n", "ca", function()
			vim.lsp.buf.code_action()
		end, { desc = "LSP code action" })
		keymap.set("n", "gr", function()
			vim.lsp.buf.references()
		end, { desc = "LSP references" })
		keymap.set("n", "fd", function()
			vim.diagnostic.open_float({ border = "rounded" })
		end, { desc = "Floating diagnostic" })
		keymap.set("n", "[d", function()
			vim.diagnostic.goto_prev({ float = { border = "rounded" } })
		end, { desc = "Goto prev" })
		keymap.set("n", "]d", function()
			vim.diagnostic.goto_next({ float = { border = "rounded" } })
		end, { desc = "Goto next" })
		keymap.set("n", "<leader>q", function()
			vim.diagnostic.setloclist()
		end, { desc = "Diagnostic setloclist" })
		keymap.set("n", "<leader>wa", function()
			vim.lsp.buf.add_workspace_folder()
		end, { desc = "Add workspace folder" })
		keymap.set("n", "<leader>wr", function()
			vim.lsp.buf.remove_workspace_folder()
		end, { desc = "Remove workspace folder" })
		keymap.set("n", "<leader>wl", function()
			print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
		end, { desc = "List workspace folders" })
	end,
}
