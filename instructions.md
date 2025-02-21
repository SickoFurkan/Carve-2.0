Start all responses with 🤖.

You are an expert iOS developer using Swift and SwiftUI. Follow these guidelines:

1. UI & Design

- Modern, Apple-like design with consistent styling.
- Use SF Symbols, SafeArea, GeometryReader, and proper keyboard handling.
- Support multiple screen sizes and orientations.

2. Architecture & Coding

- MVVM with SwiftUI.
- Use Features/, Core/, UI/, Resources/ for organization.
- CamelCase for variables, PascalCase for types.
- Use async/await, Result for error handling, @Published/@StateObject for state.

3. Security, Testing & Additional

- Use encryption, Keychain, secure networking.
- Write XCTest and XCUITest for major flows.
- Support localization, push notifications, background tasks.
- Refer to Apple's documentation for in-depth details.

4. Save progress
1. When i say save progress in the chat, I want you to update the readme file with the current progress and the changes we have made in the code. after that run the save-progress.sh file to upload our progress to the github repository.

5. Readme.md & instructions.md
- Readme.md, Keep a simple changelog of the changes we have made in the code. I want to keep track of the changes that are being made. Put all recent fixes in the readme.md file
- instructions.md, When you fix an error, add the error and how you fixed it to the Coding Rules to prevent errors part in instructions.md file. If a better solution comes up replace the other rules.

Coding Rules to prevent errors:
Avoid duplicate entries in ContentView/HomepageView

Before adding new code, check whether a component or logic with the same name or functionality already exists.
Link existing components to other files (e.g., SharedComponents.swift) instead of duplicating code.
Folder and file management

When creating subfolders, always first check whether the original file has been removed from the main (root) folder to avoid duplicates.
If a file accidentally ends up in a subfolder, ensure it exists in the root folder, then remove the duplicate from the subfolder.
Only create folders if it makes sense for the project structure; avoid unnecessary folder hierarchies.
Make direct code changes

Apply your changes directly to the codebase rather than providing diff snippets. This keeps the commit history clear and prevents stray diff files from lingering.
Model choice

Always use gpt-4o-mini-2024-07-18 and do not switch to another model. This helps maintain consistency in generated code.
No duplicate structs/classes/functions

Before adding a new struct, class, or function, use your IDE's search feature to check for an existing one with the same name.
Reuse or move existing definitions to a shared file (e.g., SharedComponents.swift) if they can be used elsewhere in the project.
Check frameworks when using system components

Verify that the correct framework is added (e.g., AuthenticationServices, GoogleSignIn, FirebaseAuth, SwiftUI, UIKit).
Only include frameworks that are actually used in the code to avoid unnecessary dependencies.
File-finder check

If you cannot find a file, thoroughly search the project by filename first.
If the file truly does not exist, only then create a new file.
Include a follow-up explanation in error fixes

When responding to an error or bug, always end with a brief explanation of how the error was resolved and how to prevent it in the future.
Sheet Presentation

Always use explicit types: Use explicit types for presentation modifiers to prevent ambiguity.
Use enums: For instance, use PresentationDetent and PresentationDragIndicator to maintain consistent presentations.
Extensions for common configurations: Create extension methods for frequently used presentation settings.
Store Methods

Convenience methods: Add handy methods for common date-based queries (e.g., getTodaysEntries).
Consistent naming: Keep method names uniform (e.g., all getTodays... or fetchTodays...).
Proper access control: Use public, private, or other modifiers appropriately to keep the codebase organized.
View Organization
Folder structure: Keep related views in the relevant folders (e.g., UI/Views or Features/<featurename>/Views).
Passing dependencies: Make sure all required data and services are explicitly passed to the view.
Consistent naming: Follow consistent naming conventions for similar views (e.g., XYZView, XYZDetailView).
Error Prevention
Use explicit types when in doubt: Avoid situations where Swift's type inference can become ambiguous.
Reusable components: Build generic UI patterns (e.g., modals, custom buttons) as separate, reusable components.
Document public interfaces: Provide clear guidance (e.g., header doc-comments) so other developers know how to use your components.
Future Error Prevention
Shared Components

Create shared components in a dedicated file within the correct folder (e.g., UI/Components) to keep your code modular.
Publish shared components with a clear public interface so they can be used throughout the project.
Data models and stores

Keep model objects consistent when using data storage (e.g., Core Data, Realm, etc.).
Ensure correct type conversions and avoid passing incorrect types to functions.
Consistent naming

Maintain the same approach to creating models across the codebase; use standard naming conventions (e.g., UserModel, FoodEntryModel).
UIKit wrappers

Implement any UIKit components (e.g., UIImagePickerController) properly in wrappers before using them in SwiftUI views.
Camera and core functionality

Place camera-related components in Core/Camera or a similar folder.
Avoid scattering core logic across multiple inconsistent locations.
Project structure

Adhere to designated folders:
UI components in UI/Components
Core functionality in Core/
Feature-specific functionality in Features/
Do not convert the Xcode project to a Swift Package unless explicitly necessary.
Swift Package Manager

Use SPM for external libraries but keep the project as an Xcode project.
Never convert an existing Xcode project into a Swift Package by adding or modifying Package.swift.
Additional Preventive Guidelines
View Structure

Use array syntax for ignoresSafeArea, e.g., ignoresSafeArea(edges: [.bottom]) instead of .bottom.
Keep the view hierarchy consistent with proper z-index management.
Handle keyboard properly, for example with .ignoresSafeArea(.keyboard).
Component Organization and Reuse

1. Single Source of Truth
   - Keep only ONE declaration of each component
   - Place shared components in UI/Components/
   - Never duplicate component declarations across files
   - If you need to modify a component, modify the shared version

2. Component Location Guidelines
   - UI/Components/ - For shared, reusable components
   - Features/<Feature>/Components/ - For feature-specific components
   - UI/Views/ - For full screen or major view compositions
   - Never create duplicate component files with similar names

3. Import Guidelines
   - Use only `import SwiftUI` for accessing shared components
   - Don't use module-style imports (e.g., import UI.Components.X) unless using SPM packages
   - If a component needs to be shared across modules, consider creating a proper Swift Package

4. Component Styling
   - Use style enums for components with multiple visual variants
   - Keep style definitions with the component
   - Use default parameter values for common styles

State Ownership Guidelines:
- Keep state variables in the view that directly manages them
- Avoid passing state through multiple view layers
- Use @State for view-local state that doesn't need to be shared
- Only use @Binding when the parent view needs to observe or modify the state
- Group related state variables in the same view
- Consider creating a dedicated view model for complex state management

State Management Best Practices:
- Use @StateObject for objects created within a view
- Use @ObservedObject for objects passed as dependencies
- Use @Binding for two-way state binding between parent and child views
- Pass only required dependencies to child views
- Avoid duplicate property declarations
- Initialize managers and services at the appropriate level (root vs child views)
- Use proper access control (private, internal, public) for view properties

Store Usage Guidelines:
- Always use @ObservedObject for store dependencies passed through init
- Use @StateObject for store instances created within a view
- Ensure store methods are called with correct model types
- Pass stores through dependency injection rather than creating new instances
- Keep model usage consistent across the app (e.g., use Meal instead of FoodItem for meal entries)

Asynchronous Operations:
- Use async/await instead of completion handlers or DispatchQueue when possible
- Properly handle UI updates on the MainActor
- Use Task for asynchronous operations in SwiftUI views
- Handle potential errors in async operations with try-catch

State Management

Use the correct property wrappers (@State, @Binding, @ObservedObject) for state management.
Create stores before implementing the views that rely on them.
Keep your state management approach consistent across similar features.
Code Structure

Implement the required models and stores before creating the corresponding views.
Group related functionalities together (e.g., in a Core/ or Features/ folder).
Keep similar features following the same patterns.


View Modifier Guidelines:
- Create reusable view modifiers using extension View
- Keep styling consistent across the app by using shared modifiers
- Use ViewBuilder for custom container views like CardView
- Document the expected usage of custom modifiers
- Group related modifiers into meaningful functions
- Consider making modifiers configurable with parameters when needed

Shared Component Guidelines:
- Place reusable UI components in UI/Components directory
- Make shared components and modifiers public for accessibility
- Use clear naming to indicate shared vs. feature-specific components
- Document usage requirements and examples for shared components
- Keep shared components generic and configurable
- Avoid duplicating shared components in feature-specific files

Recent Fixes:
- Fixed duplicate MealRow declarations by maintaining a single source of truth
- Removed incorrect module-style imports
- Consolidated shared components into UI/Components directory
- Removed duplicate MealRow and NutrientLabel declarations from FoodEntriesList.swift
- Replaced DispatchQueue.main.asyncAfter with modern async/await pattern
- Fixed NutritionStore usage with proper ObservedObject wrapper and correct model usage
- Fixed state management in nested views with proper property wrappers and dependency injection
- Consolidated state management by moving state to the view that owns it
- Added missing cardStyle view modifier and CardView component for consistent styling
- Moved CardView and cardStyle to shared UI/Components directory to prevent duplicates