# ⚔️ Syllabus RPG: Quest for Knowledge ⚔️

![Syllabus RPG Hero](./assets/readme_hero.png)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Google Gemini](https://img.shields.io/badge/Google%20Gemini-8E75C2?style=for-the-badge&logo=google-cloud&logoColor=white)](https://ai.google.dev/)

**Syllabus RPG** is a gamified education app that transforms your boring academic scrolls (PDF syllabi) into an epic 8-bit RPG adventure. Battle monsters, gain XP, and climb the Hall of Fame by mastering your coursework!

---

## 🕹️ The Game Loop

1. **Summon the Quest**: Upload any PDF syllabus.
2. **AI Magic**: Google Gemini AI parses the "scroll" and generates tricky questions based on the content.
3. **Internal Battle**: Fight through levels of enemies:
   - 🟢 **Trolls** (Level 1)
   - 🔵 **Guards** (Level 5)
   - 🟠 **Knights** (Level 10)
   - 🔴 **BOSSES** (Critical Finals!)
4. **Loot & Level Up**: Earn XP for correct answers, survive with 3 Hearts, and rank up on the global leaderboard.

---

## ✨ Features

- **Pixel-Perfect HUD**: Track your XP and Health in a retro-style interface.
- **AI-Powered Quests**: No two battles are the same! Gemini creates dynamic quiz questions from your own study materials.
- **Hall of Fame**: Compete with other students in the Daily, Weekly, and Monthly leaderboards.
- **Retro Aesthetic**: Powered by custom pixel art palettes and nostalgic fonts like _Press Start 2P_ and _VT323_.
- **Supabase Integration**: Your progress is safely stored in the clouds (the literal ones).

---

## 📸 Screenshots

|                                   Home Camp                                   |                                    Battle Stage                                    |
| :---------------------------------------------------------------------------: | :--------------------------------------------------------------------------------: |
| ![Home Screenshot](https://via.placeholder.com/300x600.png?text=Home+Camp+UI) | ![Battle Screenshot](https://via.placeholder.com/300x600.png?text=Battle+Stage+UI) |
|                      _Manage your hero and pick quests._                      |                        _Slay monsters with your knowledge!_                        |

---

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend/Auth**: Supabase
- **AI Engine**: Google Generative AI (Gemini 1.5 Flash/Pro)
- **State Management**: Provider
- **Animations**: `flutter_animate`
- **Fonts**: Google Fonts (`Press Start 2P`, `VT323`)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK installed
- A Supabase Project (with `profiles` table)
- A Google Gemini API Key

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/Syllabus-RPG.git
   ```
2. Create a `.env` file in the root:
   ```env
   SUPABASE_URL=your_url
   SUPABASE_ANON_KEY=your_key
   GEMINI_API_KEY=your_api_key
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the game:
   ```bash
   flutter run
   ```

---

## 🎭 Credits

_Made with ❤️ by Ahmad Khan

---

## 📜 License

This project is for educational (and adventuring) purposes. Build, play, and learn!
