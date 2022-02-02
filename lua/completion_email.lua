local M = {}

local function is_in_from_field(line)
	if vim.startswith(line, "From:") then
		return true
	end
	return false
end

local function is_in_recipients_field(line)
	for _, header in pairs({ "Bcc:", "Cc:", "Reply-To:", "To:" }) do
		if vim.startswith(line, header) then
			return true
		end
	end
	return false
end

local function get_sender(filename)
	local sender = {}
	for _, line in pairs(vim.fn.readfile(filename)) do
		for value in line:gmatch("from ([%w%p%-]+@[%w%p%-]+)") do
			table.insert(sender, value)
		end
	end
	return sender
end

local function get_recipients()
	local recipients = {}
	-- TODO: cache result of io.popen
	local addresses = assert(io.popen("notmuch address --format=text --deduplicate=address '*'"))
	for line in addresses:lines() do
		table.insert(recipients, line)
	end
	return recipients
end

local function fuzzy_score(prefix, input)
	local util = require("completion/util")
	local score = util.fuzzy_score(prefix, input)
	return score < #prefix / 3 or #prefix == 0
end

function M.setup_completion(msmtp_fn)
	local sender = get_sender(msmtp_fn)
	local recipients = get_recipients()

	local function complete_from_address(prefix)
		local items = {}
		local line = vim.api.nvim_get_current_line()

		if is_in_from_field(line) then
			for _, contact in pairs(sender) do
				if fuzzy_score(prefix, contact) then
					table.insert(items, {
						word = contact,
						kind = "msmtp",
					})
				end
				return items
			end
		end

		if is_in_recipients_field(line) then
			for _, contact in pairs(recipients) do
				if fuzzy_score(prefix, contact) then
					table.insert(items, {
						word = contact,
						kind = "notmuch",
					})
				end
			end
			return items
		end
	end

	require("completion").addCompletionSource("email", { item = complete_from_address })
end

function M.setup_cmp(msmtprc)
	local sender = vim.tbl_map(function(contact)
		return { label = contact, detail = "msmtp" }
	end, get_sender(msmtprc))

	local recipients = vim.tbl_map(function(contact)
		return { label = contact, detail = "notmuch" }
	end, get_recipients())

	local source = {}

	function source.get_debug_name()
		return "email"
	end

	function source.is_available()
		return vim.bo.filetype == "mail"
	end

	function source.complete(_, _, callback)
		local line = vim.api.nvim_get_current_line()
		if is_in_from_field(line) then
			callback({ items = sender })
		elseif is_in_recipients_field(line) then
			callback({ items = recipients })
		end
	end

	return source
end

return M
