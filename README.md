# Carve - iOS Health & Nutrition App

## Project Structure (as of 2025-02-22)

The project follows a clean architecture with the following directory structure:

- `Features/`: Contains feature-specific implementations
- `Core/`: Core functionality and shared business logic
- `UI/`: Reusable UI components
- `Resources/`: App resources and assets
- `Assets.xcassets/`: Image assets and app icons
- `Preview Content/`: SwiftUI preview assets

## Implementation Details

### Architecture
- Built with SwiftUI using MVVM architecture
- Protocol-oriented programming approach
- Follows Apple's Human Interface Guidelines

### Core Features
1. Fork Downs (Homepage)
   - Daily food intake tracking
   - AI-powered food recognition
   - Nutritional value analysis
   - Daily food diary

2. Muscle Ups
   - Health and fitness tracking

3. Live Feed
   - Community progress tracking
   - Social interaction features

### Technical Stack
- Swift and SwiftUI for UI
- OpenAI API integration for food analysis
- Firebase for backend services
- CoreData for local data persistence

### Dependencies
- OpenAI API for food analysis
- Firebase Authentication
- Google Sign In
- Apple Sign In

## Setup Requirements
1. OpenAI API Key required
2. GoogleService-Info.plist must be placed in the project
3. Proper Firebase configuration

## Getting Started
1. Clone the repository
2. Add required API keys and configuration files
3. Run `pod install` if using CocoaPods
4. Open the .xcworkspace file
5. Build and run

## Recent Changes
- Initial project structure setup
- Core directory organization
- Basic app architecture implementation
- Integration with OpenAI API
- Firebase setup

# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes (21-02-2025-1830)

### New Features
- 🌐 Reorganized tab bar structure with improved navigation flow

### Bug Fixes
- 🛠️ Removed redundant Live tab for cleaner navigation

### Code Optimizations
- ⚡️ Streamlined tab navigation implementation
- ⚡️ Optimized tab order for better user experience

### UI/UX Changes
- 🎨 Moved Home tab to leftmost position for easier access
- 🎨 Repositioned Knowledge tab to rightmost position
- 🎨 Simplified navigation with four essential tabs

# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes (21-02-2025-1756)

### New Features
- 🌐 ⚡️ Improved HomePageView structure with better component organization

### Bug Fixes
- 🛠️ 

### Code Optimizations
- ⚡️ 

### UI/UX Changes
- 🎨 

# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes (21-02-2025-1800)

### New Features
- 🌐 Added food diary list with quick add/remove functionality
- 🌐 Implemented animated calorie counter with slide animation

### Bug Fixes
- 🛠️ Fixed layout issues in nutrition card

### Code Optimizations
- ⚡️ Improved HomePageView structure with better component organization
- ⚡️ Enhanced animated counter performance
- ⚡️ Optimized macro progress bars display

### UI/UX Changes
- 🎨 Redesigned nutrition card with modern card-based layout
- 🎨 Added food diary with intuitive plus/minus controls
- 🎨 Updated calorie display with cleaner typography
- 🎨 Improved macro progress bars visualization

# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes (21-02-2025-1651)

### New Features
- 🌐 ⚡️ Improved macro progress bar component reusability

### Bug Fixes
- 🛠️ 

### Code Optimizations
- ⚡️ 

### UI/UX Changes
- 🎨 

# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes (21-02-2025-1700)

### New Features
- 🌐 

### Bug Fixes
- 🛠️ 

### Code Optimizations
- ⚡️ Optimized top navigation bar spacing and layout
- ⚡️ Fine-tuned content padding for better visual hierarchy

### UI/UX Changes
- 🎨 Adjusted spacing between navigation bar and content for better visual flow
- 🎨 Reduced unnecessary padding in main content area

# Carve - iOS Health & Fitness App

Een AI-powered gezondheids- en fitness-app die je dagelijkse voedselinname bijhoudt met behulp van AI. De app kan voedsel identificeren via foto's of handmatige invoer, en geeft je een gedetailleerd overzicht van je voedingswaarden.

## Latest Changes (21-02-2025-1419)

### New Features
- 🌐 

### Bug Fixes
- 🛠️ 

### Code Optimizations
- ⚡️ Simplified nutrition card component structure
- ⚡️ Improved macro progress bar component reusability
- ⚡️ Enhanced layout consistency with fixed widths and proper spacing

### UI/UX Changes
- 🎨 Updated nutrition card layout in HomePageView:
  - Removed unnecessary text elements ("Eaten", "Burned", "See Stats")
  - Streamlined calorie display with large number format
  - Added vertical macro progress bars (Protein, Fat, Carbs) with targets
  - Improved visual hierarchy and spacing
  - Cleaner, more focused design matching modern UI standards

📌 Changelog
📅 21-02-2025
🆕 Nieuwe Features
🎨 UI Updates
- Removed white background from navigation bar for cleaner look
- Integrated date selection into top section for better visual flow
- Fixed incorrect Charts import in MuscleUpsView
- Improved transparency in top navigation elements

🌐 Betere codeorganisatie met gestructureerde methodengroepen
🔄 Geoptimaliseerde NutritionStore-implementatie
📊 Verbeterde voedingswaardetracking en data-persistentie
🛠 Bugfixes
🧹 Verwijderd: dubbele NutritionStore-implementatie
🔧 Opgelost: onduidelijke type-referentie in NutritionStore
🔍 Fixed: Workout type ambiguity
⚡ Code-optimalisaties
📂 Verbeterde bestandstructuur voor onderhoudbaarheid
🎯 Minder code-duplicatie in voedingsberekeningen
🚀 Singleton-instantie toegevoegd voor betere state management
🎨 UI/UX Updates
✨ Uniforme workout-selectie interface
📱 Consistente styling voor voedingswaardetracking
📅 20-02-2025
🆕 Nieuwe Features
🔄 MuscleGroupButton geconsolideerd tot gedeeld component
🎯 Verbeterde component-herbruikbaarheid
🛠 Bugfixes
🧹 Verwijderd: dubbele CameraPreview-implementatie
🔍 Fixed: MuscleGroupButton redeclaratieproblemen
⚡ Code-optimalisaties
📂 Centrale opslag van gedeelde componenten
🎯 Redundante code verwijderd
⚡ Beter gestructureerde bestanden
🎨 UI/UX Updates
🎨 Uniforme MuscleGroupButton-styling
✨ Verbeterde profielbewerkingsinterface
📅 19-02-2025
🆕 Nieuwe Features
🌐 Meertalige ondersteuning (Engels & Nederlands)
📱 Verbeterde Profiel UI met nieuwe componenten
🔄 Netwerkmonitoring functionaliteit toegevoegd
📊 Geoptimaliseerde voedingswaardetracking
🛠 Bugfixes
🔧 Betere foutafhandeling in authenticatieflow
🏗️ Verbeterde validatie bij invoerformulieren
⚡ Code-optimalisaties
📂 Betere bestandsorganisatie
🔍 Geconsolideerde componenten (EditableInfoRow → InfoRow)
🚀 Verbeterde state-management en netwerkverbinding
🎨 UI/UX Updates
✨ Verbeterde validatie-meldingen
📊 Overzichtelijkere voedingsdoelen-sectie
📱 Geoptimaliseerde componentindeling
📖 Setup & Installatie
Vereisten
📱 iOS 17.0+, Xcode 15.0+, Swift 5.9+
🔑 Firebase & OpenAI API-sleutels vereist
Installatie
Repo klonen:
bash
Kopiëren
Bewerken
git clone https://github.com/SickoFurkan/Carve.git
Vereiste configuratiebestanden toevoegen (niet in Git)
Project openen in Xcode & runnen
⚠️ Belangrijke Notitie
De volgende bestanden NIET uploaden naar Git:

GoogleService-Info.plist
Config.swift (API-sleutels)
📩 Contact
🔧 Ontwikkeld door Furkan Çeliker  # Append previous README content  # Append previous README content  # Append previous README content  # Append previous README content
