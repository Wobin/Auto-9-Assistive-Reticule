return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`Auto-9 Assistive Reticule` encountered an error loading the Darktide Mod Framework.")

		new_mod("Auto-9 Assistive Reticule", {
			mod_script       = "Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule",
			mod_data         = "Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule_data",
			mod_localization = "Auto-9 Assistive Reticule/scripts/mods/Auto-9 Assistive Reticule/Auto-9 Assistive Reticule_localization",
		})
	end,
	version = "1.0.0",
	packages = {},
}
