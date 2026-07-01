// Адаптивное поведение бокового меню админки (Unfold хранит состояние в
// localStorage 'sidebarOpen'). По умолчанию:
//   • широкий экран (десктоп/большой планшет) — меню ОТКРЫТО;
//   • узкий экран (телефон) — меню ЗАКРЫТО, чтобы не перекрывать контент
//     (открывается кнопкой).
// Выбор пользователя (кнопкой) сохраняется и имеет приоритет.
(function () {
  try {
    if (localStorage.getItem('sidebarOpen') === null) {
      var wide = window.innerWidth >= 1024;
      localStorage.setItem('sidebarOpen', wide ? '1' : '0');
    }
  } catch (e) {}
})();
