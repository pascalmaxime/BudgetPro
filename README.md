<div align="center">

# 💰 BudgetPro

### Personal finance & wealth management app — built with Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-Local%20DB-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.x-00BCD4?style=for-the-badge)](https://riverpod.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](LICENSE)

[![macOS](https://img.shields.io/badge/macOS-✓-000000?style=flat-square&logo=apple)](https://flutter.dev/desktop)
[![Windows](https://img.shields.io/badge/Windows-✓-0078D4?style=flat-square&logo=windows)](https://flutter.dev/desktop)
[![Linux](https://img.shields.io/badge/Linux-✓-FCC624?style=flat-square&logo=linux&logoColor=black)](https://flutter.dev/desktop)
[![Android](https://img.shields.io/badge/Android-✓-3DDC84?style=flat-square&logo=android&logoColor=white)](https://flutter.dev/mobile)
[![iOS](https://img.shields.io/badge/iOS-✓-000000?style=flat-square&logo=apple)](https://flutter.dev/mobile)

</div>

---

> 🇫🇷 [Lire en français](#-français) · 🇬🇧 [Read in English](#-english)

---

## 🇫🇷 Français

**BudgetPro** est une application de gestion budgétaire et patrimoniale **100 % locale**, multiplateforme, conçue pour les particuliers. Toutes vos données restent sur votre appareil — aucun compte, aucun cloud, aucun abonnement.

### ✨ Fonctionnalités

| Module | Détail |
|--------|--------|
| 📊 **Dashboard** | Vue mensuelle : revenus, dépenses fixes/variables, taux d'épargne réel vs objectif |
| 💳 **Transactions** | Ajout, édition, suppression — catégorisées (alimentation, transport, santé, loisirs…) |
| 🔁 **Récurrences auto** | Revenus et charges fixes injectés automatiquement chaque mois selon le jour configuré |
| 📅 **Abonnements** | Suivi des abonnements actifs avec alerte avant renouvellement |
| 🏦 **Comptes & Patrimoine** | 16 types de comptes (Livret A, PEA, assurance-vie, crypto…) + total patrimoine net |
| 🎯 **Objectif patrimoine** | Définissez un objectif + date d'échéance → l'app calcule la mensualité requise et la faisabilité |
| 🤖 **Conseiller IA** | Analyse personnalisée et conseils via **Groq (Llama 3.1)** — gratuit, sans restriction région |
| 📁 **Export Excel** | Export complet `.xlsx` (transactions, abonnements, comptes, profil) |
| 📥 **Import Excel** | Réimportez vos données sur n'importe quel appareil depuis un fichier export ou le modèle fourni |
| ⚙️ **Profil financier** | Situation pro, logement, sources de revenus, charges fixes, objectif d'épargne |
| 🔔 **Notifications** | Rappels configurables avant renouvellement d'abonnement |

### 🏗️ Architecture

```
lib/
├── core/
│   ├── config/          # Clés API (api_keys.dart — ignoré par git)
│   └── database/        # SQLite helper (v4)
├── data/
│   ├── repositories/    # Accès données (transactions, comptes, abonnements, profil)
│   └── services/        # Export Excel, Import Excel, Template Excel, Récurrences, IA
├── domain/
│   └── entities/        # Transaction, Compte, Abonnement, UserProfile
├── features/
│   ├── budget/          # Provider transactions par mois
│   ├── ia/              # Service Groq
│   └── profile/         # Provider profil utilisateur
└── presentation/
    ├── dashboard/        # Dashboard + ajout/édition transaction
    ├── comptes/          # Liste comptes + carte objectif patrimoine
    ├── abonnements/      # Gestion abonnements
    ├── historique/       # Historique par mois
    ├── ia/               # Interface conseiller IA
    └── settings/         # Paramètres + profil + import/export
```

### 🚀 Installation

#### Prérequis
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- Dart ≥ 3.0

#### Cloner et lancer

```bash
git clone https://github.com/pascalmaxime/BudgetPro.git
cd BudgetPro

# Copier le fichier de configuration
cp lib/core/config/api_keys.example.dart lib/core/config/api_keys.dart

# Éditer api_keys.dart et coller votre clé Groq (gratuit : console.groq.com)

# Installer les dépendances
flutter pub get

# Lancer (macOS / Windows / Linux / Android)
flutter run
```

#### Obtenir une clé Groq gratuite
1. Créez un compte sur [console.groq.com](https://console.groq.com) (connexion Google/GitHub)
2. **API Keys** → **Create API key**
3. Collez la clé dans `lib/core/config/api_keys.dart`

> Le conseiller IA fonctionne **sans la clé** — seule la fonctionnalité IA sera indisponible.

### 📦 Stack technique

| Couche | Technologie |
|--------|-------------|
| UI / Framework | Flutter 3 + Material 3 |
| State management | Riverpod 2 (AsyncNotifier, Provider.family) |
| Navigation | GoRouter (ShellRoute 6 onglets) |
| Base de données | SQLite via `sqflite_common_ffi` |
| IA | Groq API — `llama-3.1-8b-instant` |
| Export/Import | `excel 4.x` |
| Notifications | `flutter_local_notifications` |
| Persistance légère | `shared_preferences` |

### 🔒 Confidentialité

- ✅ **100 % local** — aucune donnée envoyée sur un serveur (sauf les requêtes IA si la clé est configurée)
- ✅ Pas de compte utilisateur, pas de télémétrie
- ✅ `api_keys.dart` exclu du dépôt git (`.gitignore`)

---

## 🇬🇧 English

**BudgetPro** is a **fully local**, cross-platform personal finance and wealth management app. All your data stays on your device — no account, no cloud, no subscription required.

### ✨ Features

| Module | Description |
|--------|-------------|
| 📊 **Dashboard** | Monthly overview: income, fixed/variable expenses, actual vs target savings rate |
| 💳 **Transactions** | Add, edit, delete — categorised (food, transport, health, leisure…) |
| 🔁 **Auto-recurring** | Income and fixed charges auto-injected each month on the configured day |
| 📅 **Subscriptions** | Track active subscriptions with renewal reminders |
| 🏦 **Accounts & Net Worth** | 16 account types (savings, PEA, life insurance, crypto…) + net worth total |
| 🎯 **Wealth goal** | Set a target amount + deadline → app calculates required monthly savings & feasibility |
| 🤖 **AI Advisor** | Personalised analysis via **Groq (Llama 3.1)** — free, no region restrictions |
| 📁 **Excel Export** | Full `.xlsx` export (transactions, subscriptions, accounts, profile) |
| 📥 **Excel Import** | Re-import data on any device from an export file or the provided template |
| ⚙️ **Financial profile** | Employment status, housing, income sources, fixed charges, savings goal |
| 🔔 **Notifications** | Configurable reminders before subscription renewal |

### 🚀 Getting Started

#### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- Dart ≥ 3.0

#### Clone & Run

```bash
git clone https://github.com/pascalmaxime/BudgetPro.git
cd BudgetPro

# Set up API keys
cp lib/core/config/api_keys.example.dart lib/core/config/api_keys.dart
# Edit api_keys.dart and paste your Groq key (free at console.groq.com)

# Install dependencies
flutter pub get

# Run (macOS / Windows / Linux / Android)
flutter run
```

#### Get a free Groq API key
1. Sign up at [console.groq.com](https://console.groq.com) (Google/GitHub login)
2. **API Keys** → **Create API key**
3. Paste the key into `lib/core/config/api_keys.dart`

> The app works **without a key** — only the AI advisor feature will be unavailable.

### 📦 Tech Stack

| Layer | Technology |
|-------|------------|
| UI / Framework | Flutter 3 + Material 3 |
| State management | Riverpod 2 (AsyncNotifier, Provider.family) |
| Navigation | GoRouter (ShellRoute 6 tabs) |
| Database | SQLite via `sqflite_common_ffi` |
| AI | Groq API — `llama-3.1-8b-instant` |
| Export/Import | `excel 4.x` |
| Notifications | `flutter_local_notifications` |
| Light persistence | `shared_preferences` |

### 🔒 Privacy

- ✅ **100% local** — no data sent to any server (except AI requests if a key is configured)
- ✅ No user account, no telemetry
- ✅ `api_keys.dart` excluded from git (`.gitignore`)

### 🤝 Contributing

Pull requests are welcome! For major changes, please open an issue first.

```bash
# Fork the repo, then:
git checkout -b feature/my-feature
git commit -m "feat: add my feature"
git push origin feature/my-feature
# Open a Pull Request
```

---

<div align="center">

Made with ❤️ using Flutter &nbsp;·&nbsp; [MIT License](LICENSE)

</div>
