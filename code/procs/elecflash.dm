

var/global/mutable_appearance/elecflash_ma = null

/proc/elecflash(var/atom/center, var/radius = 0, var/power=1, var/exclude_center = 1)//power 1 to 6
	if (!center || center.qdeled || center.pooled || center.disposed)
		return

	var/turf/center_turf = get_turf(center)
	if (!elecflash_ma)
		elecflash_ma = new
		elecflash_ma.name = "electricity"
		elecflash_ma.icon = 'icons/effects/electile.dmi'
		elecflash_ma.alpha = 255
		elecflash_ma.invisibility = 0
		elecflash_ma.layer = TURF_LAYER
		elecflash_ma.plane = PLANE_FLOOR
		elecflash_ma.mouse_opacity = 0

	elecflash_ma.icon_state = "[power][pick("a","b","c")]"

	var/sound = null
	switch(power)
		if (1)
			sound = "sparks"
		if (2)
			sound = "sound/effects/electric_shock_short.ogg"
		if (3,4)
			sound = "sound/effects/electric_shock.ogg"
		else
			sound = "sound/effects/elec_bzzz.ogg"
	var/atom/E = null

	var/list/chain_to = list()
	var/list/fluid_groups_touched = list()

	if (exclude_center) // copy paste its a little faster ok!
		for (var/turf/T in oview(radius,center_turf))
			if (T.active_liquid?.group && radius + power > 1)
				if (!(T.active_liquid.group in fluid_groups_touched))
					fluid_groups_touched += T.active_liquid.group
					chain_to |= T.active_liquid.get_connected_fluid_members(power * 10)
					playsound(T, sound, 50, 1)
			else
				chain_to += T
	else	// copy paste also!
		for (var/turf/T in view(radius,center_turf))
			if (T.active_liquid?.group && radius + power > 1)
				if (!(T.active_liquid.group in fluid_groups_touched))
					fluid_groups_touched += T.active_liquid.group
					chain_to |= T.active_liquid.get_connected_fluid_members(power * 5)
					playsound(T, sound, 50, 1)
			else
				chain_to += T

	if (radius <= 0)
		for (var/turf/T in oview(1,center_turf))
			if (prob(21))
				chain_to += T

	var/turf/T = null


	var/matrix/M = matrix()
	M.Scale(0.25, 0.25)

	var/list/elecs = list()
	for (var/x in chain_to)
		T = x
		E = new/obj/overlay/tile_effect(T)
		E.appearance = elecflash_ma
		T.hotspot_expose(1000,100,usr, electric = power)
		elecs += E
		if (radius <= 0 && chain_to.len < 8)
			E.pixel_x = (center_turf.x - E.x) * 32
			E.pixel_y = (center_turf.y - E.y) * 32
			animate(E, alpha = 0, transform = M, pixel_x = rand(-18,18), pixel_y = rand(-18,18), time = (0.9 SECONDS) + (power * (0.12 SECONDS)), easing = EASE_IN)
		else
			animate(E, alpha = 0, time = (0.6 SECONDS) + (power * (0.12 SECONDS)), easing = BOUNCE_EASING | EASE_IN)



	playsound(center_turf, sound, 50, 1)

	SPAWN_DBG(3 SECONDS)
		for(var/atom in elecs)
			var/atom/A = atom
			qdel(A)

//disorient + LIGHT burn

/atom/proc/electric_expose(var/power = 1)

/mob/living/electric_expose(var/power = 1)
	if (power > 1)
		src.do_disorient(stamina_damage = 10 + power * 20, weakened = 1 SECONDS + (power * (0.2 SECONDS)), stunned = 0, paralysis = 0, disorient = 1 SECONDS + (power * (0.2 SECONDS)), remove_stamina_below_zero = 0, target_type = DISORIENT_BODY)
		src.TakeDamage("chest", 0, rand(0.00,1.00) * power * 1.2, DAMAGE_BURN) // pretty light damage :)