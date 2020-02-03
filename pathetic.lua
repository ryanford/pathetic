local lpeg = require("lpeg")
local P, S, R, V, C, Cc, Cf = lpeg.P, lpeg.S, lpeg.R, lpeg.V, lpeg.C, lpeg.Cc, lpeg.Cf

local pathetic = {}

local pchar = P{
	"pchar",
	pchar = V"unreserved" + V"pct_encoded" + V"sub_delims" + S":@",
	pct_encoded = P"%" * V"hexdig" * V"hexdig",
	unreserved = V"alpha" + V"digit" + S"-._~",
	gen_delims = S":/?#[]@",
	sub_delims = S"!$&'()*+,;=",
	alpha = R("AZ", "az"),
	digit = R"09",
	hexdig = R("AF", "af", "09")
}

function pathetic.parse_query(self, query)
	local set = {}
	return P{
		"parsed_query",
		parsed_query = Cf(Cc{} * (V"stmt" * (P"&" * V"stmt") ^ 0) ^ -1, function(acc, x)
			if acc[1] then -- match is value
				local key = acc[1]
				if acc[key] then -- key already used
					if type(acc[key]) == "table" then -- key used more than once already
						if not set[key][x] then
							table.insert(acc[key], x)
							set[key][x] = true
						end
					else
						if acc[key] ~= x then -- key used but different value
							acc[key] = { acc[key], x }
							set[key][x] = true
						end
					end
				else -- new key
					acc[key] = x
					set[key] = { [x] = true }
				end
				acc[1] = nil
			else -- match is key
				acc[1] = x
			end

			return acc
		end),
		stmt = V"pair" + V"single",
		single = V"key" * Cc"",
		pair = V"key" * P"=" * V"value",
		key = Cc(self) * C((pchar - S"&=") ^ 1) / self.unescape,
		value = Cc(self) * C((pchar - P"&") ^ 0) / self.unescape,
	}:match(query)
end

local query = (pchar + S"/?") ^ 0

local fragment = (pchar + S"/?") ^ 0

local path_part = P{
	"path_part",
	path_part = V"path_abempty" + V"path_absolute" + V"path_noscheme" + V"path_rootless" + V"path_empty",
	path_abempty = (P"/" * V"segment") ^ 0,
	path_absolute = P"/" * (V"segment_nz" * (P"/" * V"segment") ^ 0) ^ -1,
	path_noscheme = V"segment_nz_nc" * (P"/" * V"segment") ^ 0,
	path_rootless = V"segment_nz" * (P"/" * V"segment") ^ 0,
	path_empty = P(-1),
	segment = pchar ^ 0,
	segment_nz = pchar ^ 1,
	segment_nz_nc = (pchar - P":") ^ 1,
}

function pathetic.unescape(self, str)
	local unescaped = str:gsub("%%(%w%w)", function(hex) return string.char("0x" .. hex) end)
	return unescaped
end

function pathetic.escape(self, str)
	local escaped = str:gsub("[%:%/%?%#%[%]%@%!%$%&%'%(%)%*%+%,%;%=%s]", function(c)
		local byte = string.format("%x", string.byte(c)):upper()
		return "%" .. (#byte == 2 and byte or "0" .. byte)
	end)
	return escaped
end

function pathetic.parse(self, path)
	local parsed
	local raw_path, raw_query, raw_fragment = P(C(path_part) * (P"?" * C(query)) ^ -1 * (P"#" * C(fragment)) ^ -1):match(path)
	parsed = {
		raw_path = raw_path,
		raw_query = raw_query,
		raw_fragment = raw_fragment,
		path = self:unescape(raw_path),
		query = self:parse_query(raw_query),
		fragment = self:unescape(raw_fragment),
	}
	return parsed
end

function pathetic.get_raw_path(self, path)
	return P(C(path_part) * (P"?" * query) ^ -1 * (P"#" * fragment) ^ -1):match(path)
end

function pathetic.get_path(self, path)
	return P((Cc(self) * C(path_part) / self.unescape) * (P"?" * query) ^ -1 * (P"#" * fragment) ^ -1):match(path)
end

function pathetic.get_raw_query(self, path)
	return P(path_part * (P"?" * C(query)) ^ -1 * (P"#" * fragment) ^ -1):match(path)
end

function pathetic.get_query(self, path)
	return P(path_part * (P"?" * ((Cc(self) * C(query)) / self.parse_query)) ^ -1 * (P"#" * fragment)):match(path)
end

function pathetic.get_raw_fragment(self, path)
	return P(path_part * (P"?" * query) ^ -1 * (P"#" * C(fragment)) ^ -1):match(path)
end

function pathetic.get_fragment(self, path)
	return P(path_part * (P"?" * query) ^ -1 * (P"#" * (Cc(self) * C(fragment) / self.unescape)) ^ -1):match(path)
end

return pathetic
