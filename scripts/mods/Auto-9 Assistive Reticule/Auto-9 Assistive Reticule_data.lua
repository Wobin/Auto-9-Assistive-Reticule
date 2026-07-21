local mod = get_mod("Auto-9 Assistive Reticule")

return {
	name = mod:localize("mod_name"),
	description = mod:localize("mod_description"),
	is_togglable = true,
	options = {
		widgets = {
			{
				setting_id = "a9_box_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "a9_box_enabled",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "a9_box_thickness",
						type = "numeric",
						default_value = 2,
						range = { 1, 10 },
						decimals_number = 0,
					},
					{
						setting_id = "a9_box_colour",
						type = "group",
						sub_widgets = {
							{ setting_id = "a9_box_colour_R", type = "numeric", default_value = 255, range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_box_colour_G", type = "numeric", default_value = 0,   range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_box_colour_B", type = "numeric", default_value = 0,   range = { 0, 255 }, decimals_number = 0 },
						},
					},
					{
						setting_id = "a9_box_opacity",
						type = "numeric",
						default_value = 255,
						range = { 0, 255 },
						decimals_number = 0,
					},
					{
						setting_id = "a9_slam_duration",
						type = "numeric",
						default_value = 0.2,
						range = { 0.05, 1.0 },
						decimals_number = 2,
						step_size_value = 0.05,
					},
				},
			},
			{
				setting_id = "a9_lines_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "a9_lines_enabled",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "a9_lines_thickness",
						type = "numeric",
						default_value = 2,
						range = { 1, 10 },
						decimals_number = 0,
					},
					{
						setting_id = "a9_lines_colour",
						type = "group",
						sub_widgets = {
							{ setting_id = "a9_lines_colour_R", type = "numeric", default_value = 255, range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_lines_colour_G", type = "numeric", default_value = 0,   range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_lines_colour_B", type = "numeric", default_value = 0,   range = { 0, 255 }, decimals_number = 0 },
						},
					},
					{
						setting_id = "a9_lines_opacity",
						type = "numeric",
						default_value = 255,
						range = { 0, 255 },
						decimals_number = 0,
					},
					{
						setting_id = "a9_lines_match_box",
						type = "checkbox",
						default_value = false,
					},
				},
			},
			{
				setting_id = "a9_outline_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "a9_outline_match_lines",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "a9_outline_colour",
						type = "group",
						sub_widgets = {
							{ setting_id = "a9_outline_colour_R", type = "numeric", default_value = 255, range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_outline_colour_G", type = "numeric", default_value = 0,   range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_outline_colour_B", type = "numeric", default_value = 0,   range = { 0, 255 }, decimals_number = 0 },
						},
					},
					{
						setting_id = "a9_outline_priority",
						type = "numeric",
						default_value = 0,
						range = { 0, 5 },
						decimals_number = 0,
					},
				},
			},
			{
				setting_id = "a9_scanner_group",
				type = "group",
				sub_widgets = {
					{
						setting_id = "a9_scanner_enabled",
						type = "checkbox",
						default_value = true,
					},
					{
						setting_id = "a9_scanner_x",
						type = "numeric",
						default_value = 720,
						range = { 0, 1920 },
						decimals_number = 0,
						step_size_value = 5,
					},
					{
						setting_id = "a9_scanner_y",
						type = "numeric",
						default_value = 600,
						range = { 0, 1080 },
						decimals_number = 0,
						step_size_value = 5,
					},
					{
						setting_id = "a9_scanner_size",
						type = "numeric",
						default_value = 24,
						range = { 10, 96 },
						decimals_number = 0,
					},
					{
						setting_id = "a9_scanner_colour",
						type = "group",
						sub_widgets = {
							{ setting_id = "a9_scanner_colour_R", type = "numeric", default_value = 255, range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_scanner_colour_G", type = "numeric", default_value = 176, range = { 0, 255 }, decimals_number = 0 },
							{ setting_id = "a9_scanner_colour_B", type = "numeric", default_value = 0,   range = { 0, 255 }, decimals_number = 0 },
						},
					},
				},
			},
			{
				setting_id = "a9_tag_group",
				type = "group",
				sub_widgets = {
					{ setting_id = "a9_tag_enabled", type = "checkbox", default_value = true },
					{ setting_id = "a9_tag_own_only", type = "checkbox", default_value = true },
					{ setting_id = "a9_tag_whirr", type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "a9_veteran_group",
				type = "group",
				sub_widgets = {
					{ setting_id = "a9_exec_enabled", type = "checkbox", default_value = true },
					{ setting_id = "a9_exec_parallel", type = "checkbox", default_value = false },
				},
			},
			{
				setting_id = "a9_arbites_group",
				type = "group",
				sub_widgets = {
					{ setting_id = "a9_mark_arbites", type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "a9_psyker_group",
				type = "group",
				sub_widgets = {
					{ setting_id = "a9_mark_psyker", type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "a9_skitarii_group",
				type = "group",
				sub_widgets = {
					{ setting_id = "a9_mark_skitarii", type = "checkbox", default_value = true },
				},
			},
			{
				setting_id = "a9_broker_group",
				type = "group",
				sub_widgets = {
					{ setting_id = "a9_mark_broker", type = "checkbox", default_value = true },
				},
			},
		},
	},
}
