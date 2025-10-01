# Copilot Instructions for ClickApp UI

Welcome to the ClickApp UI codebase! This document provides essential guidelines for AI coding agents to be productive and aligned with the project's conventions.

## Project Overview

ClickApp UI is a React-based frontend application. The project structure is simple and modular, with the following key components:

- **`App.jsx`**: The main entry point for the application logic.
- **`main.jsx`**: The root file where the React app is rendered.
- **`components/`**: Contains reusable React components.
- **`assets/`**: Stores static assets like images.

### Styling
- **CSS Files**: Styling is managed using CSS files like `App.css` and `index.css`. These files define global and component-specific styles.

## Developer Workflows

### Running the Application
To start the development server:
```bash
npm start
```

### Building the Application
To create a production build:
```bash
npm run build
```

### Debugging
- Use browser developer tools to inspect components and styles.
- React Developer Tools extension is recommended for debugging React components.

## Project-Specific Conventions

### Component Structure
- Components are stored in the `components/` directory.
- Each component has its own file, e.g., `Toast.jsx`.

### Naming Conventions
- Use PascalCase for component names (e.g., `Toast.jsx`).
- Use camelCase for variables and functions.

### State Management
- Local state is managed using React's `useState` and `useEffect` hooks.

### Toast Notifications
- The `Toast.jsx` component is used for displaying notifications.
- Example usage:
  ```jsx
  import Toast from './components/Toast';

  function App() {
    return <Toast message="Hello, World!" />;
  }
  ```

## External Dependencies
- **React**: Core library for building the UI.
- **ReactDOM**: For rendering the application.

## Integration Points
- Static assets like images are stored in the `assets/` directory and can be imported directly into components.

## Key Files
- `App.jsx`: Main application logic.
- `main.jsx`: React DOM rendering logic.
- `components/Toast.jsx`: Example of a reusable component.

---

Feel free to update this document as the project evolves to ensure it remains accurate and helpful.