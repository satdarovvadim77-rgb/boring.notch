> [!NOTE]
> **Это неофициальная кастомная сборка** [TheBoredTeam/boring.notch](https://github.com/TheBoredTeam/boring.notch), основанная на версии **v2.7.3**.
> Оригинальный проект и все права на него принадлежат The Bored Team. Распространяется под той же лицензией [GPL-3.0](LICENSE).
>
> Об ошибках этой сборки сообщайте в [Issues этого репозитория](https://github.com/satdarovvadim77-rgb/boring.notch/issues), а не в оригинальный проект.

## 🚀 Изменения относительно оригинального репозитория (`v2.7.3`)

### 🎵 Медиа и плееры
- **Интеграция с Яндекс Музыкой (`YandexMusicController`, `YandexMusicHelper`)**:
  - Поддержка Яндекс Музыки (`ru.yandex.desktop.music`) как отдельного медиаконтроллера.
  - Реализация кнопок «Лайк» и «Дизлайк» через macOS Accessibility API (`AXUIElement`) и нативные команды.
  - Кэширование состояния процесса Яндекс Музыки через уведомления `NSWorkspace` вместо опроса списка процессов на каждом обновлении стейта.
  - Точная фильтрация `bundleIdentifier` без ложного приписывания сторонних треков Яндекс Музыке и без рассинхронизации оптимистичного `togglePlay()`.
- **Фолбэк контроллеров (`AppleMusicController`, `NowPlayingController`)**:
  - Восстановлен `AppleMusicController` в `MediaControllerType` как полноценный рабочий фолбэк при устаревании `NowPlayingController` на новых версиях macOS.
  - Выделены отдельные сервисы для работы с текстами песен (`LyricsService` с предкомпилированным регулярным выражением LRC) и обложками альбомов (`ArtworkService`).
- **Перехват медиаклавиш (`MediaKeyInterceptor`)**:
  - Улучшена маршрутизация системных медиаклавиш и управление громкостью активного плеера.

### 🎨 Интерфейс, кастомизация и режимы работы
- **Пользовательские иконки приложения (`AppIconManager`, `AppIconCropSheet`)**:
  - Выбор пресетов и загрузка собственной иконки с интерактивным кадрированием.
  - Безопасная смена иконки в рантайме (`NSApp.applicationIconImage` + `NSApp.dockTile`) только при её реальном изменении — без записи `Icon\r` в `.app`-бандл, без поломки цифровой подписи/Sparkle и без перезапуска Dock.
- **Экран даты и времени в Notch (`NotchDateTimeView`)**:
  - Отображение часов, даты и быстрых индикаторов в свёрнутом/развёрнутом состояниях.
- **Энергосбережение и Игровой режим (`EnergySaverManager`, `GameModeManager`)**:
  - Автоматическое снижение частоты кадров анимаций и отключение тяжёлых визуальных эффектов при низком заряде батареи, в режиме энергосбережения или при запуске полноэкранных игр.
- **Кастомный акцентный цвет (`Color+AccentColor`, `VisualEffectView`)**:
  - Поддержка пользовательского акцентного цвета и улучшенное сглаживание углов (`NotchShape`).

### 🔒 Безопасность и архитектура
- **Защита XPC-хелпера (`BoringNotchXPCHelper`)**:
  - Проверка клиентского процесса по `bundleIdentifier` (`theboringteam.boringnotch`), пути родительского `.app`-бандла и требованию кодовой подписи (`setCodeSigningRequirement`).
- **Модульность и декомпозиция**:
  - Крупные монолитные файлы разделены на модули: `SettingsView` → `GeneralSettingsView`, `MediaSettingsView`, `AppearanceSettingsView`, `AdvancedSettingsView`; `MusicManager` → `LyricsService`, `ArtworkService`; `ContentView` → `ContentView+Subviews`; `ShelfItemViewModel` → `ShelfItemContextMenu`.
- **Swift Concurrency и стабильность**:
  - Перевод менеджеров и делегата приложения (`MusicManager`, `AppDelegate`, `BoringViewModel`, `AppIconManager`) на `@MainActor` и структурированные `Task` вместо `DispatchWorkItem`.
  - Внедрение зависимостей через инициализаторы, удаление некорректных `@ObservedObject` вне SwiftUI `View`.
  - Корректное хранение `windowScreenDidChangeObservers` по каждому окну в мультимониторном режиме, замена `@retroactive Hashable` у `CGRect` на безопасную обёртку `ScreenFrameRect`.
  - Перевод отладочного вывода (`print`/`NSLog`) на системный `os.Logger` с категориями (`Logger.swift`) и устранение потенциально опасных force unwrap (`!`).

---

## 📦 Releases (Скачать)

Актуальные сборки и архивы исходного кода доступны в разделе **[GitHub Releases](https://github.com/satdarovvadim77-rgb/boring.notch/releases)** и в папке [`Releases/`](./Releases):

- 💿 **Установщик macOS (`.dmg`)**: [boringNotch.dmg (GitHub Release)](https://github.com/satdarovvadim77-rgb/boring.notch/releases/latest/download/boringNotch.dmg) · [Releases/boringNotch.dmg](./Releases/boringNotch.dmg)
- 🗂 **Архив с проектом (`.zip`)**: [boringNotch-project.zip (GitHub Release)](https://github.com/satdarovvadim77-rgb/boring.notch/releases/latest/download/boringNotch-project.zip) · [Releases/boringNotch-project.zip](./Releases/boringNotch-project.zip)
- 📦 **Собранное приложение (`.app.zip`)**: [boringNotch.app.zip (GitHub Release)](https://github.com/satdarovvadim77-rgb/boring.notch/releases/latest/download/boringNotch.app.zip) · [Releases/boringNotch.app.zip](./Releases/boringNotch.app.zip)

<h1 align="center">
  <br>
  <a href="http://thebored.name"><img src="https://framerusercontent.com/images/RFK4vs0kn8pRMuOO58JeyoemXA.png?scale-down-to=256" alt="Boring Notch" width="150"></a>
  <br>
  Boring Notch
  <br>
</h1>


<p align="center">
  <a title="Crowdin" target="_blank" href="https://crowdin.com/project/boring-notch"><img src="https://badges.crowdin.net/boring-notch/localized.svg"></a>
  <img src="https://github.com/TheBoredTeam/boring.notch/actions/workflows/cicd.yml/badge.svg" alt="TheBoringNotch Build & Test" style="margin-right: 10px;" />
  <a href="https://discord.gg/c8JXA7qrPm">
    <img src="https://dcbadge.limes.pink/api/server/https://discord.gg/c8JXA7qrPm?style=flat" alt="Discord Badge" />
  </a>
  <a href="ttps://ko-fi.com/brandonhimpfen">
    <img src="https://srv-cdn.himpfen.io/badges/kofi/kofi-flat.svg" alt="Ko-Fi" />
  </a>
</p>

<!--Welcome to **Boring.Notch**, the coolest way to make your MacBook's notch the star of the show! Forget about those boring status bars—our notch turns into a dynamic music control center, complete with a snazzy visualizer and all the music controls you need. It's like having a mini concert right at the top of your screen! -->

Say hello to **Boring Notch**, the coolest way to make your MacBook’s notch the star of the show! Say goodbye to boring status bars: with Boring Notch, your notch transforms into a dynamic music control center, complete with a vibrant visualizer and all the essential music controls you need. But that’s just the start! Boring Notch also offers calendar integration, a handy file shelf with AirDrop support, a complete MacOS HUD replacement and more!

<p align="center">
  <img src="https://github.com/user-attachments/assets/2d5f69c1-6e7b-4bc2-a6f1-bb9e27cf88a8" alt="Demo GIF" />
</p>

<!--https://github.com/user-attachments/assets/19b87973-4b3a-4853-b532-7e82d1d6b040-->
---
<!--## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Roadmap](#-roadmap)
- [Building from Source](#building-from-source)
- [Contributing](#-contributing)
- [Join our Discord Server](#join-our-discord-server)
- [Star History](#star-history)
- [Buy us a coffee!](#buy-us-a-coffee)
- [Acknowledgments](#-acknowledgments)-->

## Installation

**System Requirements:**  
- macOS **14 Sonoma** or later  
- Apple Silicon or Intel Mac

---
> [!IMPORTANT]
> We don't have an Apple Developer account yet. The application will show a popup on first launch that the app is from an unidentified developer.
> 1. Click **OK** to close the popup.
> 2. Open **System Settings** > **Privacy & Security**.
> 3. Scroll down and click **Open Anyway** next to the warning about the app.
> 4. Confirm your choice if prompted.
>
> You only need to do this once.


### Option 1: Download and Install Manually
<a href="https://github.com/satdarovvadim77-rgb/boring.notch/releases/latest/download/boringNotch.dmg" target="_self"><img width="200" src="https://github.com/user-attachments/assets/e3179be1-8416-4b8a-b417-743e1ecc67d6" alt="Download for macOS" /></a>

---

### Option 2: Install via Homebrew

You can also install the app using [Homebrew](https://brew.sh):

```bash
brew install --cask TheBoredTeam/boring-notch/boring-notch --no-quarantine
```

## Usage

- Launch the app, and voilà—your notch is now the coolest part of your screen.
- Hover over the notch to see it expand and reveal all its secrets.
- Use the controls to manage your music like a rockstar.
- Click the star in your menu bar to customize your notch to your heart's content.

## 📋 Roadmap
- [x] Playback live activity 🎧
- [x] Calendar integration 📆
- [x] Reminders integration ☑️
- [x] Mirror 📷
- [x] Charging indicator and current percentage 🔋
- [x] Customizable gesture control 👆🏻
- [x] Shelf functionality with AirDrop 📚
- [x] Notch sizing customization, finetuning on different display sizes 🖥️
- [x] System HUD replacements (volume, brightness, backlight) 🎚️💡⌨️
- [ ] Bluetooth Live Activity (connect/disconnect for bluetooth devices) 
- [ ] Weather integration ⛅️
- [ ] Customizable Layout options 🛠️
- [ ] Lock Screen Widgets 🔒
- [ ] Extension system 🧩
- [ ] Notifications (under consideration) 🔔
<!-- - [ ] Clipboard history manager 📌 `Extension` -->
<!-- - [ ] Download indicator of different browsers (Safari, Chromium browsers, Firefox) 🌍 `Extension`-->
<!-- - [ ] Customizable function buttons 🎛️ -->
<!-- - [ ] App switcher 🪄 -->

<!-- ## 🧩 Extensions
> [!NOTE]
> We’re hard at work on some awesome extensions! Stay tuned, and we’ll keep you updated as soon as they’re released. -->

## Building from Source

### Prerequisites

- **macOS 14 or later**: If you’re not on the latest macOS, we might need to send a search party.
- **Xcode 16 or later**: This is where the magic happens, so make sure it’s up-to-date.

### Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/TheBoredTeam/boring.notch.git
   cd boring.notch
   ```

2. **Open the Project in Xcode**:
   ```bash
   open boringNotch.xcodeproj
   ```

3. **Build and Run**:
    - Click the "Run" button or press `Cmd + R`. Watch the magic unfold!

## 🤝 Contributing

We’re all about good vibes and awesome contributions! Here’s how you can join the fun:

1. **Fork the Repo**: Click that shiny "Fork" button and make your own version.
2. **Clone Your Fork**:
   ```bash
   git clone https://github.com/{your-name}/boring.notch.git
   # Replace {your-name} with your GitHub username
   ```
3. **Make sure to use the `dev` branch as base.**
4. **Create a New Branch**:
   ```bash
   git checkout -b feature/{your-feature-name}
   # Replace {your-feature-name} with a descriptive and concise name for your branch
   # It is best practice to use only alphanumeric characters, write words in lowercase
   # and seperate words with a single hyphen
   ```
5. **Make Your Changes**: Add that feature or fix that bug.
6. **Commit Your Changes**:
   ```bash
   git commit -m "insert descriptive message here"
   ```
7. **Push to Your Fork**:
   ```bash
   git push origin feature/{your-feature-name}
   # Remember to replace {your-feature-name} with the name you chose
   ```
8. **Create a Pull Request**: Head to the original repository and click on "New Pull Request." Fill in the required details, **make sure the base branch is set to `dev`**, and submit your PR. Let’s see what you’ve got!

## Join our Discord Server

<a href="https://discord.gg/GvYcYpAKTu" target="_blank"><img src="https://iili.io/28m3GHv.png" alt="Join The Boring Server!" style="height: 60px !important;width: 217px !important;" ></a>

## Star History

<a href="https://www.star-history.com/#TheBoredTeam/boring.notch&Timeline">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=TheBoredTeam/boring.notch&type=Timeline&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=TheBoredTeam/boring.notch&type=Timeline" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=TheBoredTeam/boring.notch&type=Timeline" />
 </picture>
</a>

## Support us on Ko-fi!
<!-- <a href="https://www.buymeacoffee.com/jfxh67wvfxq" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-red.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a> -->
<a href="https://www.ko-fi.com/alexander5015" target="_blank"><img src="https://github.com/user-attachments/assets//a76175ef-7e93-475a-8b67-4922ba5964c2" alt="Support us on Ko-fi" style="height: 70px !important;width: 346px !important;" ></a>

## 🎉 Acknowledgments

We would like to express our gratitude to the authors and maintainers of the open-source projects that made this possible. 

## Notable Projects
- **[MediaRemoteAdapter](https://github.com/ungive/mediaremote-adapter)** –  An open-source project that allowed us to use the Now Playing source in macOS 15.4+
- **[NotchDrop](https://github.com/Lakr233/NotchDrop)** – An open-source project that has been instrumental in developing the first version of the "Shelf" feature in Boring Notch.

For a full list of licenses and attributions, please see the [Third-Party Licenses](./THIRD_PARTY_LICENSES.md) file.

### Icon credits: [@maxtron95](https://github.com/maxtron95)
### Website credits: [@himanshhhhuv](https://github.com/himanshhhhuv)

- **SwiftUI**: For making us look like coding wizards.
- **You**: For being awesome and checking out **boring.notch**!


