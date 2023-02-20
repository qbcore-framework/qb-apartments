local Translations = {
    error = {
        to_far_from_door = 'Je bent te ver van de deurbel',
        nobody_home = 'Er is niemand thuis..',
        nobody_at_door = 'Er is niemand aan de deur...'
    },
    success = {
        receive_apart = 'Je hebt een appartement',
        changed_apart = 'Je bent verhuisd naar appartement',
    },
    info = {
        at_the_door = 'Er staat iemand voor de deur!',
    },
    text = {
        options = '[E] Apartement Opties',
        enter = 'Betreed appartement',
        ring_doorbell = 'Aanbellen',
        logout = 'Karakter Uitloggen',
        change_outfit = 'Verander Outfit',
        open_stash = 'Opbergruimte Openen',
        move_here = 'Verhuis naar hier',
        open_door = 'Deur Openen',
        leave = 'Appartement Verlaten',
        close_menu = '⬅ Menu Sluiten',
        tennants = 'Huurders',
    },
}

if GetConvar('qb_locale', 'en') == 'nl' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
