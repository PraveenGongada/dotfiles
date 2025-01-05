return {
	"williamboman/mason.nvim",
	cmd = {
		"Mason",
		"MasonInstall",
		"MasonUpdate",
		"MasonToolsInstall",
		"MasonToolsInstallSync",
		"MasonToolsUpdate",
		"MasonToolsUpdateSync",
	},
	event = "VeryLazy",
	dependencies = {
		{ "WhoIsSethDaniel/mason-tool-installer.nvim" },
	},
	opts = function()
		local opts = {
			ui = {
				icons = {
					package_pending = "",
					package_installed = "󰄳",
					package_uninstalled = "󰚌",
				},
				keymaps = {
					toggle_server_expand = "<cr>",
					install_server = "i",
					update_server = "u",
					check_server_version = "c",
					update_all_servers = "u",
					check_outdated_servers = "c",
					uninstall_server = "x",
					cancel_installation = "<c-c>",
				},
			},
			-- log_level = vim.log.levels.WARN, -- NOTE: To disable the install messages which are coming from mason-tool-installer also
		}

		return opts
	end,
	config = function(_, opts)
		-- import mason
		local mason = require("mason")

		-- import mason-tool-installer
		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup(opts)

		mason_tool_installer.setup({

			ensure_installed = {
				-- Language server
				"gopls",
				"rust-analyzer",
				"typescript-language-server",
				"tailwindcss-language-server",
				"css-lsp",
				"lua-language-server",

				-- Formatters
				"prettierd",
				"stylua",
				"gofumpt",
				"goimports-reviser",
				"golines",

				-- Linters
				"golangci-lint",
				"eslint_d",
			},
		})
	end,
}
