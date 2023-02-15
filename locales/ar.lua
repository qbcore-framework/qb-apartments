local Translations = {
    error = {
        to_far_from_door = 'أنت بعيد عن جرس الباب',
        nobody_home = 'لا يوجد أحد في المنزل',
        nobody_at_door = 'لا يوجد أحد عند الباب'
    },
    success = {
        receive_apart = 'لديك شقة',
        changed_apart = 'انتقلت الشقق',
    },
    info = {
        at_the_door = 'شخص ما على الباب',
    },
    text = {
        options = '[E] خيارات الشقة',
        enter = 'أدخل الشقة',
        ring_doorbell = 'جرس الباب',
        logout = 'تغير الشخصية',
        change_outfit = 'يغير الملابس',
        open_stash = 'فتح الحقيبة',
        move_here = 'التغير الى هنا',
        open_door = 'فتح الباب',
        leave = 'الخروج من الشقة',
        close_menu = '⬅ اغلاق القائمة',
        tennants = 'التغير',
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
