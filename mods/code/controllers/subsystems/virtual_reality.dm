/datum/computer_file/program/vr_control
	program_key_state = "generic_key"

//New VR logic, get worn items in simulation and clear templates properly
/datum/controller/subsystem/virtual_reality
	var/static/list/vr_blacklist = list(
		/obj/item/disk/nuclear,
		/obj/item/clothing/accessory/bs_silk,
		/obj/item/device/uplink_service,
		/obj/item/bluespace_crystal,
		/obj/item/stack/telecrystal,
		/obj/item/stock_parts/circuitboard,
		/obj/item/implanter,
		/obj/item/implant,
		/obj/item/device/syndietele,
		/obj/item/device/syndiejaunter,
		/obj/item/organ/internal,
		/obj/item/organ/external,
		/obj/item/device/mmi
	)

/datum/controller/subsystem/virtual_reality/proc/recursive_storage_copy(obj/item/storage/S, obj/item/storage/O)
	for(var/obj/item/I in S.contents)
		qdel(I)

	for(var/obj/item/I in O.contents)
		if(!is_type_in_list(I, vr_blacklist))
			var/obj/item/cloned_I = clone_atom(I)
			S.handle_item_insertion(cloned_I)

			if(istype(cloned_I, /obj/item/storage))
				recursive_storage_copy(cloned_I, I)

/datum/controller/subsystem/virtual_reality/proc/accessories_copy(obj/item/clothing/cloned_I, obj/item/clothing/I)
	for(var/obj/item/clothing/accessory/A in I.accessories)
		if(!is_type_in_list(A, vr_blacklist))
			var/obj/item/clothing/accessory/cloned_A = clone_atom(A)
			cloned_I.attach_accessory(null, cloned_A)

/datum/controller/subsystem/virtual_reality/proc/apply_vr_equipment(mob/living/simulated_mob, mob/living/new_occupant)
	for(var/obj/item/I in new_occupant.contents)
		if(!is_type_in_list(I, vr_blacklist))
			var/obj/item/cloned_I = clone_atom(I)
			var/item_slot = new_occupant.get_inventory_slot(I)

			if(istype(cloned_I, /obj/item/storage))
				recursive_storage_copy(cloned_I, I)

			if(istype(cloned_I, /obj/item/clothing))
				accessories_copy(cloned_I, I)


			simulated_mob.equip_to_slot(cloned_I, item_slot)

/datum/controller/subsystem/virtual_reality/create_virtual_mob(mob/living/new_occupant, mob_type, location, silent = FALSE)
	var/mob/living/simulated_mob = new mob_type(location)
	if (ishuman(simulated_mob) && ishuman(new_occupant)) // Copy human appearance for the new mob
		var/mob/living/carbon/human/H = simulated_mob
		var/mob/living/carbon/human/H_original = new_occupant //new

		new_occupant.client.prefs.copy_to(simulated_mob)
		H.set_nutrition(400)
		H.set_hydration(400)
		H.job = new_occupant.job

		//New logic
		apply_vr_equipment(simulated_mob, new_occupant)

		for(var/obj/item/organ/internal/augment/aug in H_original.internal_organs)
			var/obj/item/organ/internal/augment/augment = clone_atom(aug)

			var/obj/item/organ/external/parent = augment.get_valid_parent_organ(simulated_mob)
			if (!parent)
				to_chat(simulated_mob, SPAN_WARNING("Failed to find a valid organ to install \the [augment] into!"))
				qdel(augment)
				return

			var/surgery_step = GET_SINGLETON(/singleton/surgery_step/internal/replace_organ)

			if (augment.surgery_configure(simulated_mob, simulated_mob, parent, null, surgery_step))
				to_chat(simulated_mob, SPAN_WARNING("Failed to set up \the [augment] for installation in your [parent.name]!"))
				qdel(augment)
				return

			augment.forceMove(simulated_mob)
			augment.replaced(simulated_mob, parent)
			augment.onRoundstart()
		//
		//H.apply_job_equipment()



		for (var/obj/item/I in H)
			if (istype(I, /obj/item/underwear))
				I.canremove = FALSE
				I.verbs -= /obj/item/underwear/verb/RemoveSocks

	log_and_message_admins("entered VR as [simulated_mob] (assigned role: [new_occupant.mind.assigned_role]).", new_occupant)

	var/datum/extension/virtual_surrogate/VM = get_or_create_extension(simulated_mob, /datum/extension/virtual_surrogate)
	VM.set_mob(simulated_mob, src)

	virtual_occupants_to_mobs[new_occupant] = simulated_mob
	virtual_mobs_to_occupants[simulated_mob] = new_occupant
	virtual_clients[new_occupant.client] = simulated_mob

	new_occupant.mind.transfer_to(simulated_mob)

	if (!silent)
		var/dat = ""
		dat += SPAN_NOTICE(SPAN_BOLD(FONT_LARGE("-=-=-=-<br>You have entered VR!<br>")))
		if (!locate(simulated_mob.client) in was_warned)
			dat += SPAN_NOTICE("You are now controlling a virtual body in a virtual environment.<br>")
			dat += SPAN_NOTICE("Your normal body can be found where you entered VR, hopefully secure from outside influence.<br>")
			dat += SPAN_NOTICE("You won't be able to see or hear anything around your normal body, but if your pod loses power or is forced open, you'll be returned.")
			dat += SPAN_NOTICE("<br><br>From an in-character perspective, <b>everything done here is simulated, and will have no <i>direct</i> impact on the round.</b><br>")
			dat += SPAN_NOTICE("Of course, you're still beholden to the server's rules, and you're expected to follow them! Don't beat someone to death without asking.<br>")
			dat += SPAN_NOTICE("If you die in this form, you'll be forced back to your body. You can also use the \[Exit-VR\] verb at any time, which you can find in the VR tab.<br>")
		dat += SPAN_NOTICE(SPAN_BOLD(FONT_LARGE("-=-=-=-")))
		to_chat(simulated_mob, dat)
		playsound(simulated_mob.loc, 'sound/machines/boop1.ogg', 50)
		simulated_mob.languages = new_occupant.languages.Copy()
		simulated_mob.default_language = new_occupant.default_language
	simulated_mob.lastarea = null
	return simulated_mob

/datum/controller/subsystem/virtual_reality/load_template(datum/nano_module/program/vr_control/vr_program, user, zone, template_area)
	if (!zone)
		to_chat(user, SPAN_WARNING("No VR zone selected. Cannot load template."))
		return TRUE

	var/area/zone_area = GLOB.active_vr_areas[zone]
	if (!zone_area)
		to_chat(user, SPAN_WARNING("The system could not find the specified VR zone: [zone]"))
		return TRUE

	var/list/the_matrix = SSvirtual_reality.virtual_occupants_to_mobs
	var/P = GLOB.vr_areas[template_area]
	var/area/A = locate(P)
	if (!A)
		P = GLOB.emagged_vr_areas[template_area]
		A = locate(P)
		if (!A) // if we still don't have our area after checking for emagged ones, throw an error
			to_chat(user, SPAN_WARNING("The system could not find the specified template: [template_area]"))
			return TRUE
	if (zone_area == A)
		return TRUE
	if (the_matrix.len)
		if (alert(user, "Switching the VR area will eject [the_matrix.len] users from the simulation. Continue?", "Change Area", "Yes", "No") != "Yes")
			return TRUE
		log_and_message_admins("changed the VR area to [A.name], ejecting [the_matrix.len] occupants.", user)
	else
		log_and_message_admins("changed the VR area to [A.name].", user)

	//Removing mobs before deleting everything
	var/list/mobs_in_zone = mobs_in_area(zone_area)
	for (var/mob/living/L in mobs_in_zone)
		to_chat(L, SPAN_DANGER(FONT_LARGE("ALERT: Loaded VR template reconfiguring. Terminating connection.")))
		SSvirtual_reality.remove_virtual_mob(L, TRUE)

	var/loaded_normally = TRUE
	if (!vr_program.emagged || prob(75))
		for (var/atom/SO in simulated_objects[zone]) // Clear the entire previous template before we place another one
			if (length(SO.contents))
				for (var/atom/sub_SO in SO.contents)
					qdel(sub_SO)
			qdel(SO)
		for (var/turf/T in zone_area)
			if (!istype(T, /turf/unsimulated/floor/plating))
				T.ChangeTurf(/turf/unsimulated/floor/plating)
				//New logic - deleting everything at changed turfs
				if (length(T.contents))
					for (var/atom/C in T.contents)
						qdel(C)
				//
	else // we're emagged, just fuck our shit up a quarter of the time
		loaded_normally = FALSE
		var/atom/comp_holder = vr_program.program.computer.holder
		comp_holder.audible_message(SPAN_DANGER("\The [comp_holder] buzzes oddly!"))
		to_chat(user, SPAN_WARNING("updatevr.dm:[rand(10000, 20000)]:warning: Previous loaded template did not fully unload. Virtual space may be affected."))
		playsound(vr_program.program.computer.holder, 'sound/machines/buzz-sigh.ogg', 50)

	// in this way, we use the selected area as a template. we copy all of its contents to the actual area,
	// allowing users to "reset" the template by refreshing it
	var/area/active_area = zone_area
	simulated_objects[zone] = A.copy_contents_to(active_area)
	active_area.forced_ambience = A.forced_ambience
	active_area.dynamic_lighting = A.dynamic_lighting
	active_area.sound_env = A.sound_env
	GLOB.vr_spawns[zone] = list()
	for (var/obj/effect/vr_spawn/V in active_area)
		GLOB.vr_spawns[zone] += V

	to_chat(user, SPAN_NOTICE("Successfully loaded new area: [A.name]!"))
	if (loaded_normally)
		playsound(vr_program.program.computer.holder, 'sound/machines/ping.ogg', 50)
	vr_program.area_cooldown = world.time + 30 SECONDS
	return TRUE