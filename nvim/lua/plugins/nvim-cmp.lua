return {
	"hrsh7th/nvim-cmp",
	event = "InsertEnter",
	dependencies = {
		{
			-- snippet plugin
			"L3MON4D3/LuaSnip",
			dependencies = "rafamadriz/friendly-snippets",
			opts = { history = true, updateevents = "TextChanged,TextChangedI" },
			config = function(_, opts)
				require("luasnip").config.set_config(opts)

				-- vscode format
				require("luasnip.loaders.from_vscode").lazy_load()
				require("luasnip.loaders.from_vscode").lazy_load({ paths = vim.g.vscode_snippets_path or "" })

				-- snipmate format
				require("luasnip.loaders.from_snipmate").load()
				require("luasnip.loaders.from_snipmate").lazy_load({ paths = vim.g.snipmate_snippets_path or "" })

				-- lua format
				require("luasnip.loaders.from_lua").load()
				require("luasnip.loaders.from_lua").lazy_load({ paths = vim.g.lua_snippets_path or "" })

				vim.api.nvim_create_autocmd("InsertLeave", {
					callback = function()
						if
							require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
							and not require("luasnip").session.jump_active
						then
							require("luasnip").unlink_current()
						end
					end,
				})
			end,
		},

		-- autopairing of (){}[] etc
		{
			"windwp/nvim-autopairs",
			opts = {
				fast_wrap = {},
				disable_filetype = { "TelescopePrompt", "vim" },
			},
			config = function(_, opts)
				require("nvim-autopairs").setup(opts)

				-- setup cmp for autopairs
				local cmp_autopairs = require("nvim-autopairs.completion.cmp")
				require("cmp").event:on("confirm_done", cmp_autopairs.on_confirm_done())
			end,
		},

		-- cmp sources plugins
		{
			"saadparwaiz1/cmp_luasnip",
			"hrsh7th/cmp-nvim-lua",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
		},
	},
	opts = function()
		local cmp = require("cmp")

		local options = {

			completion = { completeopt = "menu,menuone" },

			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},

			performance = {
				debounce = 60,
				throttle = 30,
				fetching_timeout = 500,
				confirm_resolve_timeout = 80,
				async_budget = 1,
				max_view_entries = 200,
			},

			mapping = {
				["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
				["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
				["<C-u>"] = cmp.mapping.scroll_docs(-4),
				["<C-d>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
				["<Esc>"] = cmp.mapping.abort(), -- close completion window

				["<CR>"] = cmp.mapping.confirm({
					behavior = cmp.ConfirmBehavior.Insert,
					select = true,
				}),

				["<Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_next_item()
					elseif require("luasnip").expand_or_jumpable() then
						vim.fn.feedkeys(
							vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true),
							""
						)
					else
						fallback()
					end
				end, {
					"i",
					"s",
				}),
				["<S-Tab>"] = cmp.mapping(function(fallback)
					if cmp.visible() then
						cmp.select_prev_item()
					elseif require("luasnip").jumpable(-1) then
						vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
					else
						fallback()
					end
				end, {
					"i",
					"s",
				}),
			},
			sources = {
				{ name = "nvim_lsp" },
				{ name = "luasnip" },
				{ name = "buffer" },
				{ name = "nvim_lua" },
				{ name = "path" },
			},
		}

		return vim.tbl_deep_extend("force", options, require("nvchad.cmp"))
	end,
	config = function(_, opts)
		require("cmp").setup(opts)
	end,
}
