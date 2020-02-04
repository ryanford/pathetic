package.path = "assets/lua/?.lua;" .. package.path

local pathetic = require("pathetic")
local inspect = require("inspect")
local js = require("js")

local window = js.global
local document = window.document

local display = document:getElementById("display")
local form = document:getElementById("ui")
local input = document:getElementById("path_input")
local btn = document:getElementById("submit_btn")

form:addEventListener("submit", function(self, e)
	local input = document:getElementById("path_input")
	display.textContent = inspect(pathetic:parse(input.value))
end)

btn:removeAttribute("disabled")
