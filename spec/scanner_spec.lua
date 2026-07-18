local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_scanner()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/scanner.lua")
end

return function()
	runner.suite("scanner")

	runner.it("scramble returns the exact target once elapsed >= duration", function()
		local s = load_scanner()
		runner.eq(s.scramble("Sven Wahlund", 0.4, 0.4), "Sven Wahlund")
		runner.eq(s.scramble("Sven Wahlund", 5, 0.4), "Sven Wahlund")
	end)

	runner.it("scramble preserves length and spaces while resolving", function()
		local s = load_scanner()
		local out = s.scramble("Sven Wahlund", 0.0, 0.4)
		runner.eq(#out, #("Sven Wahlund"), "length preserved")
		runner.eq(out:sub(5, 5), " ", "the space position stays a space")
	end)

	runner.it("scramble reveals left-to-right as elapsed grows", function()
		local s = load_scanner()
		local target = "ABCDEFGH"
		local out = s.scramble(target, 0.2, 0.4)
		runner.eq(out:sub(1, 4), "ABCD", "first half revealed")
		runner.truthy(out:sub(5) ~= "EFGH" or out == target, "second half not yet guaranteed real")
	end)

	runner.it("scramble uses only glyphs from the set for unresolved chars", function()
		local s = load_scanner()
		local out = s.scramble("XXXX", 0.0, 1.0, "AB")
		for i = 1, #out do
			runner.truthy(out:sub(i, i) == "A" or out:sub(i, i) == "B", "unresolved char is from the glyph set")
		end
	end)

	runner.it("scramble is deterministic for the same inputs (no math.random)", function()
		local s = load_scanner()
		runner.eq(s.scramble("Wahlund", 0.1, 0.4), s.scramble("Wahlund", 0.1, 0.4))
	end)

	runner.it("dots cycles 0..3 dots over the period", function()
		local s = load_scanner()
		runner.eq(s.dots(0.0, 0.4), "")
		runner.eq(s.dots(0.4, 0.4), ".")
		runner.eq(s.dots(0.8, 0.4), "..")
		runner.eq(s.dots(1.2, 0.4), "...")
		runner.eq(s.dots(1.6, 0.4), "", "wraps back to zero")
	end)

	runner.it("split_labels splits on commas and trims whitespace", function()
		local s = load_scanner()
		local out = s.split_labels("KILL ORDER, SANCTIONED , EXECUTE")
		runner.eq(#out, 3)
		runner.eq(out[1], "KILL ORDER", "no trailing space")
		runner.eq(out[2], "SANCTIONED", "leading and trailing trimmed")
		runner.eq(out[3], "EXECUTE")
	end)

	runner.it("split_labels drops empty items and preserves inner spaces", function()
		local s = load_scanner()
		local out = s.split_labels("A,, ,B")
		runner.eq(#out, 2, "empty and whitespace-only items dropped")
		runner.eq(out[1], "A")
		runner.eq(out[2], "B")
		runner.eq(s.split_labels("BAD 'UN")[1], "BAD 'UN", "single item, inner space and apostrophe kept")
	end)

	runner.it("split_labels returns an empty table for blank or non-string input", function()
		local s = load_scanner()
		runner.eq(#s.split_labels(""), 0)
		runner.eq(#s.split_labels("   "), 0)
		runner.eq(#s.split_labels(nil), 0, "non-string is safe")
	end)
end
