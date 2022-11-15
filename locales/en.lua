local Translations = {
    info = {
        placemode = "<b>You are currently on safe place mode</b><br><br><b>Controls:</b><br>Upper Arrow - Move the object upwards<br>Down Arrow - Move the object downwards<br>Left Arrow - Move object left<br>Right Arrow - Move object right<br>G - Place on Ground<br>R - Rotate Object<br><br><b>Escape or Backspace</b> to exit<br>Press <b>ENTER</b> to place Safe in the current position"
    },
    error = {
        inmode = "You are already in place mode, press ESC or Backspace to cancel place mode!",
        outbounds = "You went out of bounds!",
        failed = "You failed to crack open the door!",
        player_nearby = "No player nearby!",
        not_authorized = "You are not authorized to disintegrate this safe!"
    },
    menu = {
        access_header = 'Access List',
        access_context = 'Safe: %{id}<br>Owner: %{owner}',
        access_add    = '➕ Add Access to a person',
        access_remove = '%{cid}<br>❌ Click here to remove access to this person',

        removesafe_header = '⚠️ You are about to remove / pickup safe!',
        removesafe_context = "Removing the safe will destroy all the items inside the safe so please take your belongings before picking up!",
    
        disintegrate_header = '⚠️ You are about to remove this safe, please make sure to screenshots incase a dispute arises against you for removing the safe!',

        yes = '✅ Confirm',
        no = '❌ Cancel'
    },
    success = {
        access_added = "You've successfully added %{name} to the access list!",
        disintegrate_safe = "You've deleted a safe belonging to Citizen (%{cid})."
    }
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
