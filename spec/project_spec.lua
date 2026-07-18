local runner = require("spec.runner")
local engine = require("spec.mock_engine")

local function load_project()
	return dofile(engine.MOD_ROOT .. "/scripts/mods/Auto-9 Assistive Reticule/modules/project.lua")
end

local vec = engine.vec

-- A camera at the origin looking down +y. Projects with a 1000px focal length,
-- centred on a 1920x1080 back buffer. Chosen so expected pixels are hand-checkable.
local function make_ctx(inverse_scale)
	local ctx = {}
	ctx.camera = "CAMERA"
	ctx.camera_position = vec(0, 0, 0)
	ctx.camera_direction = vec(0, 1, 0)
	ctx.screen_offset_x = 0
	ctx.screen_offset_y = 0
	ctx.inverse_scale = inverse_scale or 1
	return ctx
end

local function install_camera(behind_is_nil)
	_G.Camera = {
		world_to_screen = function(_cam, p)
			if p.y <= 0 then
				return vec(0, 0, 0)
			end
			return vec(960 + (p.x / p.y) * 1000, 540 - (p.z / p.y) * 1000, 0)
		end,
		inside_frustum = function(_cam, p)
			if behind_is_nil then return -1 end
			return p.y > 0 and 1 or -1
		end,
	}
end

return function()
	runner.suite("project")

	runner.it("projects a unit ahead of the camera to a centred box", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx()
		local positions = { low = vec(0, 10, 0), mid = vec(0, 10, 0.9), high = vec(0, 10, 1.8) }
		local cx, cy, half_w, half_h = project.box_from_positions(ctx, positions, 0.3)
		runner.near(cx, 960, 0.5, "centred horizontally")
		runner.near(cy, 540 - 90, 0.5, "centred on the mid node")
		runner.near(half_h, 90, 0.5, "half-height is half the projected low-to-high span")
		runner.truthy(half_w > 0, "width derived from the breed aspect")
	end)

	runner.it("returns nil for a target behind the camera", function()
		-- Isolate the dot-product guard: force inside_frustum to ALWAYS report inside, so
		-- the frustum check cannot be what rejects this fixture. Also point the camera down
		-- -y while the target sits at +y, so the mock's world_to_screen (which only zeroes
		-- out on p.y <= 0) does NOT independently collapse the projection to (0,0,0) and
		-- mask the guard behind half_h <= 0. Only the guard's own dot-product sign test can
		-- reject this fixture.
		_G.Camera = {
			world_to_screen = function(_cam, p)
				if p.y <= 0 then
					return vec(0, 0, 0)
				end
				return vec(960 + (p.x / p.y) * 1000, 540 - (p.z / p.y) * 1000, 0)
			end,
			inside_frustum = function(_cam, _p)
				return 1
			end,
		}
		local project = load_project()
		local ctx = make_ctx()
		ctx.camera_direction = vec(0, -1, 0)
		local positions = { low = vec(0, 10, 0), mid = vec(0, 10, 0.9), high = vec(0, 10, 1.8) }
		runner.falsy(project.box_from_positions(ctx, positions, 0.3),
			"behind the camera must be rejected, not projected to garbage")
	end)

	runner.it("returns nil when outside the frustum", function()
		install_camera(true)
		local project = load_project()
		local ctx = make_ctx()
		local positions = { low = vec(0, 10, 0), mid = vec(0, 10, 0.9), high = vec(0, 10, 1.8) }
		runner.falsy(project.box_from_positions(ctx, positions, 0.3))
	end)

	runner.it("a nearer target yields a bigger box", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx()
		local near = { low = vec(0, 5, 0), mid = vec(0, 5, 0.9), high = vec(0, 5, 1.8) }
		local far = { low = vec(0, 20, 0), mid = vec(0, 20, 0.9), high = vec(0, 20, 1.8) }
		local _, _, _, near_h = project.box_from_positions(ctx, near, 0.3)
		local _, _, _, far_h = project.box_from_positions(ctx, far, 0.3)
		runner.truthy(near_h > far_h, "perspective: closer must be larger")
	end)

	-- THE RESOLUTION BUG. Omitting the scale conversion is correct at exactly one
	-- resolution and silently wrong at every other.
	runner.it("applies the scenegraph offset and inverse scale", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx(0.5)
		ctx.screen_offset_x = 100
		ctx.screen_offset_y = 50
		local positions = { low = vec(0, 10, 0), mid = vec(0, 10, 0.9), high = vec(0, 10, 1.8) }
		local cx, cy = project.box_from_positions(ctx, positions, 0.3)
		runner.near(cx, (960 - 100) * 0.5, 0.5, "offset subtracted, then inverse scale applied")
		runner.near(cy, (540 - 90 - 50) * 0.5, 0.5)
	end)

	runner.it("wider breeds yield wider boxes at the same distance", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx()
		local positions = { low = vec(0, 10, 0), mid = vec(0, 10, 0.9), high = vec(0, 10, 1.8) }
		local _, _, trash_w = project.box_from_positions(ctx, positions, 0.3)
		local _, _, ogryn_w = project.box_from_positions(ctx, positions, 0.5)
		runner.truthy(ogryn_w > trash_w, "half_extent_right must drive width")
	end)

	-- THE ASPECT BUG. enemy_aim_target_01/03 sit at a sub-box of the breed's full
	-- height (precision_target_finder_auto_aim.lua:360-362), not the full silhouette.
	-- Deriving pixels-per-metre from an assumed full breed height (rather than the
	-- actual low-to-high node span) systematically under-widens every box. This
	-- fixture's span (1.2m) deliberately does NOT equal the "breed height" (1.8m) an
	-- old height-based algebra would have assumed, so it only passes if width is
	-- derived from the real span.
	runner.it("derives width from the actual node span, not an assumed breed height", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx()
		local positions = { low = vec(0, 10, 0), mid = vec(0, 10, 0.6), high = vec(0, 10, 1.2) }
		local _, _, half_w, half_h = project.box_from_positions(ctx, positions, 0.3)
		local expected_aspect = (0.3 * 2) / 1.2
		runner.near(half_w, half_h * expected_aspect, 0.01,
			"width must scale with the 1.2m node span, not a 1.8m breed-height assumption")
	end)

	-- THE QUADRUPED BUG. A dog carries enemy_aim_target_01/03 front-to-back at near-equal HEIGHT
	-- (03 is the head, per chaos_hound_breed aim_config), so the world vertical span |high.z-low.z|
	-- collapses toward zero and jitters as the dog lunges, while the nodes differ in DEPTH. Deriving
	-- width as half_h * (2*half_extent_right / world_span) then makes the box explode sideways and
	-- change shape every frame. Width must come from the projected horizontal half-extent at the
	-- target's distance, independent of the vertical node span.
	runner.it("keeps box width stable for a quadruped whose aim nodes are near-level (dog)", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx()
		local pose_a = { low = vec(0, 12, 0.40), mid = vec(0, 10, 0.45), high = vec(0, 8, 0.50) }
		local pose_b = { low = vec(0, 11, 0.42), mid = vec(0, 10, 0.43), high = vec(0, 9, 0.44) }
		local _, _, wa = project.box_from_positions(ctx, pose_a, 0.3)
		local _, _, wb = project.box_from_positions(ctx, pose_b, 0.3)
		runner.near(wa, 30, 2, "width is the projected 0.3m half-extent at depth 10, not a span-driven blowup")
		runner.near(wa, wb, 1, "width must not swing as the near-level node span jitters between poses")
	end)

	-- Completing half of the quadruped fix. A near-level dog projects its low/high aim nodes to
	-- almost the same screen-y, so the raw node-span half-height collapses toward zero and the box
	-- becomes a flat horizontal sliver that flickers as the dog turns. Height is floored to a
	-- fraction of the (now stable, distance-driven) width so the box keeps a sane shape. Tall
	-- humanoid boxes, whose half_h already exceeds the floor, are unaffected.
	runner.it("floors box height so a near-level quadruped box never collapses to a flat sliver", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx()
		local flat = { low = vec(-0.05, 10, 0.450), mid = vec(0, 10, 0.450), high = vec(0.05, 10, 0.451) }
		local _, _, half_w, half_h = project.box_from_positions(ctx, flat, 0.3)
		runner.truthy(half_h >= half_w * 0.5 - 0.001,
			"height floored to at least half the width, not a near-zero sliver")
	end)

	runner.it("does NOT inflate a tall humanoid box (height floor only lifts degenerate boxes)", function()
		install_camera(false)
		local project = load_project()
		local ctx = make_ctx()
		local humanoid = { low = vec(0, 10, 0), mid = vec(0, 10, 0.9), high = vec(0, 10, 1.8) }
		local _, _, _, half_h = project.box_from_positions(ctx, humanoid, 0.3)
		runner.near(half_h, 90, 0.5, "tall box keeps its real projected height, floor does not trigger")
	end)

	runner.it("lerp_slam_size starts at the oversized slam size at progress 0", function()
		local project = load_project()
		local w, h = project.lerp_slam_size(50, 30, 0, 2000)
		runner.near(w, 2000, 0.001)
		runner.near(h, 2000, 0.001)
	end)

	runner.it("lerp_slam_size collapses exactly onto the projected box at progress 1", function()
		local project = load_project()
		local w, h = project.lerp_slam_size(50, 30, 1, 2000)
		runner.near(w, 100, 0.001, "full width is twice half_w")
		runner.near(h, 60, 0.001, "full height is twice half_h")
	end)

	runner.it("lerp_slam_size is linear at the midpoint", function()
		local project = load_project()
		local w = project.lerp_slam_size(50, 30, 0.5, 2000)
		runner.near(w, 2000 + (100 - 2000) * 0.5, 0.001)
	end)

	runner.it("lerp_slam_size defaults to project.SLAM_FULL_SIZE when full_size is omitted", function()
		local project = load_project()
		local w = project.lerp_slam_size(50, 30, 0)
		runner.near(w, project.SLAM_FULL_SIZE, 0.001)
	end)
end
