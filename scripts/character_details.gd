extends Control

func display_hero(hero: Dictionary):
	# Grundinfos
	#%NameLabel.text = hero["name"] #TODO
	%LvlVal.text = "Level " + str(hero["level"])
	
	# Stats (GridContainer Pfade anpassen)
	%HPVal.text = str(hero["max_hp"])
	%AtkVal.text = str(hero["atk"])
	%DefVal.text = str(hero["def"])
	%SPAtkVal.text = str(hero["sp_atk"])
	%SPDefVal.text = str(hero["sp_def"])
	%SpeedVal.text = str(hero["speed"])
	%LuckVal.text = str(hero["luck"])
	
	# XP
	var req_xp = GameData.get_required_xp(hero["level"])
	%XPBar.max_value = req_xp
	%XPBar.value = hero["xp"]
	#%XPText.text = str(hero["xp"]) + " / " + str(req_xp) #TODO
	
	# Equipment (Wir nehmen an, das Dictionary hat ein "equipment" Feld) #TODO
	#var eq = hero.get("equipment", {})
	#%HeadLabel.text = eq.get("head", "Leer")
	#%BodyLabel.text = eq.get("body", "Leer")
	#%WeaponLabel.text = eq.get("weapon", "Leer")
	
	show()
