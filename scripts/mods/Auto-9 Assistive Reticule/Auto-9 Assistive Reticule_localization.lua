return {
	mod_name = {
		en = "Auto-9 Assistive Reticule",
		["zh-cn"] = "机械战警目标扫描锁定框",
	},
	mod_description = {
		en = "RoboCop-style targeting HUD. The reticule boots up on your target during the Skitarii Advanced Combat Doctrines ability, or on ANY class by tagging an enemy, with a scanner readout that names the subject.",
		["zh-cn"] = "机械战警风格锁定HUD。护教军开启「高级作战教条」技能时自动生成目标锁定框；所有职业标记敌人后也可触发，附带扫描面板显示敌人名称。",
	},

	a9_box_group = {
		en = "Target Box",
		["zh-cn"] = "目标方框",
	},
	a9_box_enabled = {
		en = "Show target box",
		["zh-cn"] = "显示目标方框",
	},
	a9_box_thickness = {
		en = "Box line thickness",
		["zh-cn"] = "方框线条粗细",
	},
	a9_box_colour = {
		en = "Box colour",
		["zh-cn"] = "方框颜色",
	},
	a9_box_colour_R = {
		en = "Box colour (red)",
		["zh-cn"] = "方框红色通道",
	},
	a9_box_colour_G = {
		en = "Box colour (green)",
		["zh-cn"] = "方框绿色通道",
	},
	a9_box_colour_B = {
		en = "Box colour (blue)",
		["zh-cn"] = "方框蓝色通道",
	},
	a9_box_opacity = {
		en = "Box opacity",
		["zh-cn"] = "方框透明度",
	},
	a9_slam_duration = {
		en = "Acquisition slam duration",
		["zh-cn"] = "锁定收缩动画时长",
	},
	a9_slam_duration_description = {
		en = "How long the box takes to slam in from full size to the locked target size, in seconds.",
		["zh-cn"] = "方框从全屏大小收缩至目标轮廓的动画时长，单位秒。",
	},

	a9_lines_group = {
		en = "Target Lines",
		["zh-cn"] = "目标十字引线",
	},
	a9_lines_enabled = {
		en = "Show target lines",
		["zh-cn"] = "显示十字引线",
	},
	a9_lines_thickness = {
		en = "Line thickness",
		["zh-cn"] = "引线粗细",
	},
	a9_lines_colour = {
		en = "Line colour",
		["zh-cn"] = "引线颜色",
	},
	a9_lines_colour_R = {
		en = "Line colour (red)",
		["zh-cn"] = "引线红色通道",
	},
	a9_lines_colour_G = {
		en = "Line colour (green)",
		["zh-cn"] = "引线绿色通道",
	},
	a9_lines_colour_B = {
		en = "Line colour (blue)",
		["zh-cn"] = "引线蓝色通道",
	},
	a9_lines_opacity = {
		en = "Line opacity",
		["zh-cn"] = "引线透明度",
	},
	a9_lines_match_box = {
		en = "Lines match box colour",
		["zh-cn"] = "引线跟随方框颜色",
	},
	a9_lines_match_box_description = {
		en = "When enabled, target lines use the box colour instead of their own colour setting.",
		["zh-cn"] = "开启后，十字引线将直接使用方框配色，不再使用独立引线颜色设置。",
	},

	a9_outline_group = {
		en = "Outline",
		["zh-cn"] = "敌人轮廓描边",
	},
	a9_outline_match_lines = {
		en = "Outline matches line colour",
		["zh-cn"] = "描边跟随引线颜色",
	},
	a9_outline_match_lines_description = {
		en = "When enabled, the target outline uses the line colour instead of its own colour.",
		["zh-cn"] = "开启后，敌人轮廓描边复用引线配色，不再使用独立描边颜色。",
	},
	a9_outline_colour = {
		en = "Outline colour",
		["zh-cn"] = "描边颜色",
	},
	a9_outline_colour_R = {
		en = "Outline colour (red)",
		["zh-cn"] = "描边红色通道",
	},
	a9_outline_colour_G = {
		en = "Outline colour (green)",
		["zh-cn"] = "描边绿色通道",
	},
	a9_outline_colour_B = {
		en = "Outline colour (blue)",
		["zh-cn"] = "描边蓝色通道",
	},
	a9_outline_priority = {
		en = "Outline priority",
		["zh-cn"] = "描边渲染层级",
	},
	a9_outline_priority_description = {
		en = "Draw priority against other outline sources. LOWER values win: 0 shows over every other outline; raise it to let vanilla or other mods' outlines take precedence.",
		["zh-cn"] = "控制描边与其他轮廓效果的渲染先后。数值越小层级越高：0会覆盖所有原生/模组描边；提高数值可让游戏原版或其他模组的描边优先显示。",
	},

	a9_scanner_group = {
		en = "Scanner Readout",
		["zh-cn"] = "扫描信息面板",
	},
	a9_scanner_enabled = {
		en = "Show scanner readout",
		["zh-cn"] = "显示扫描信息面板",
	},
	a9_scanner_x = {
		en = "Scanner position (horizontal)",
		["zh-cn"] = "面板横向偏移",
	},
	a9_scanner_y = {
		en = "Scanner position (vertical)",
		["zh-cn"] = "面板纵向偏移",
	},
	a9_scanner_size = {
		en = "Scanner text scale",
		["zh-cn"] = "扫描文字缩放大小",
	},
	a9_scanner_colour = {
		en = "Scanner colour",
		["zh-cn"] = "扫描文字颜色",
	},
	a9_scanner_colour_R = {
		en = "Scanner colour (red)",
		["zh-cn"] = "文字红色通道",
	},
	a9_scanner_colour_G = {
		en = "Scanner colour (green)",
		["zh-cn"] = "文字绿色通道",
	},
	a9_scanner_colour_B = {
		en = "Scanner colour (blue)",
		["zh-cn"] = "文字蓝色通道",
	},

	a9_scanner_scanning = {
		en = "SCANNING",
		["zh-cn"] = "正在扫描",
	},
	a9_scanner_subject = {
		en = "SUBJECT: ",
		["zh-cn"] = "目标：",
	},
	a9_scanner_labels_default = {
		en = "WANTED, TARGET, MARKED",
		["zh-cn"] = "通缉目标,锁定目标,标记目标",
	},
	a9_scanner_labels_veteran = {
		en = "KILL ORDER, SANCTIONED, TERMINATION, EXECUTE",
		["zh-cn"] = "击杀指令,制裁目标,终止目标,处决目标",
	},
	a9_scanner_labels_broker = {
		en = "BOUNTY, CONTRACT, MARKED, COLLECTION",
		["zh-cn"] = "悬赏目标,契约目标,标记目标,待缉目标",
	},
	a9_scanner_labels_adamant = {
		en = "WARRANT, INDICTMENT, GUILTY, SENTENCED",
		["zh-cn"] = "缉捕令,起诉对象,有罪目标,待判决",
	},
	a9_scanner_labels_cryptic = {
		en = "PURGE ORDER, DESIGNATED, TERMINATE, FLAGGED",
		["zh-cn"] = "净化指令,指定目标,终止清除,标记肃清",
	},
	a9_scanner_labels_zealot = {
		en = "HERETIC, CONDEMNED, PENANCE, ANATHEMA",
		["zh-cn"] = "异端分子,受诅罪人,赎罪对象,可憎邪物",
	},
	a9_scanner_labels_psyker = {
		en = "DOOMED, FORESEEN, FATED, UNCLEAN",
		["zh-cn"] = "注定毁灭,预知灾厄,宿命邪物,不洁存在",
	},
	a9_scanner_labels_ogryn = {
		en = "BAD 'UN, SQUASH, NAUGHTY, STOMP",
		["zh-cn"] = "坏家伙,碾碎它,捣蛋分子,一脚踩烂",
	},

	a9_tag_group = {
		en = "Tag Trigger",
		["zh-cn"] = "标记触发设置",
	},
	a9_tag_enabled = {
		en = "Trigger reticle on tagged enemies (any class)",
		["zh-cn"] = "标记敌人时触发锁定准星（全职业生效）",
	},
	a9_tag_own_only = {
		en = "Only my own tags",
		["zh-cn"] = "仅自己标记的敌人生效",
	},
	a9_tag_whirr = {
		en = "Play the Skitarii lock sound on a tagged lock",
		["zh-cn"] = "标记锁定时播放护教军锁定音效",
	},
}