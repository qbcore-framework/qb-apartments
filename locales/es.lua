local Translations = {
    error = {
        to_far_from_door = 'Estás muy lejos del timbre',
        nobody_home = 'No hay nadie en casa..',
        nobody_at_door = 'No hay nadie en la puerta...'
    },
    success = {
        receive_apart = 'Has obtenido un apartamento',
        changed_apart = 'Te has mudado de apartamento',
    },
    info = {
        at_the_door = '¡Hay alguien en la puerta!',
    },
    text = {
        options = '[E] Opciones de aprtamento',
        enter = 'Entrar apartamento',
        ring_doorbell = 'Tocar timbre',
        logout = 'Salir de personaje',
        change_outfit = 'Cambiar ropa',
        open_stash = 'Abrir escondite',
        move_here = 'Moverse aquí',
        open_door = 'Abrir puerta',
        leave = 'Salir del apartamento',
        close_menu = '⬅ Cerrar menú',
        tennants = 'Inquilinos',
    },
}

Lang = Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
