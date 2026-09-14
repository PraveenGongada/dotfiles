return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		-- Automatically install LSPs and related tools to stdpath for Neovim
		{ "williamboman/mason.nvim" }, -- NOTE: Must be loaded before dependants
	},
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			go = { "golangcilint" },
		}

		local gopls_covered = { staticcheck = true, govet = true, unused = true }
		local gl = lint.linters.golangcilint
		local gl_parser = gl.parser
		gl.parser = function(...)
			return vim.tbl_filter(function(d)
				return not gopls_covered[d.source]
			end, gl_parser(...))
		end

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		-- Keymaps
		vim.keymap.set("n", "<leader>l", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
