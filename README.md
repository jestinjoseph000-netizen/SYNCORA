# internship_project

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# SYNCORA

### Smart Inventory & Order Management System

SYNCORA is a modern inventory and order management application developed to simplify business operations through centralized product management, inventory tracking, order processing, and sales monitoring.

Built using Flutter and Supabase, SYNCORA provides a responsive interface for desktop, tablet, and mobile devices, with separate dashboards and permissions for administrators and staff.

## Overview

The system helps businesses manage their daily inventory and operational activities efficiently. It combines product management, stock monitoring, order processing, customer records, and business insights in one application.

## Features

### 1. Authentication & Access Control

- User authentication and login.
- Role-based access control.
- Separate Admin and Staff dashboards.
- Secure logout functionality.

### 2. Dashboard

- Overview of business operations.
- Product and order statistics.
- Sales information.
- Low-stock indicators.
- Quick access to operational modules.

### 3. Product Management

- Add new products.
- Edit product information.
- Search and browse products.
- Barcode-based Quick Scan functionality.
- Role-based product management permissions.

### 4. Inventory Management

- Monitor available stock.
- Manage stock movements.
- Record inventory updates.
- Identify low-stock products.
- Track inventory activity.

### 5. Order Management

- Create and manage customer orders.
- Update order information.
- Automatically update inventory when orders are processed.
- Maintain order records.

### 6. Customer Management

- Maintain customer records.
- Add and manage customer information.
- View customer details.

### 7. Employee Management

- Create Staff accounts.
- View employee information.
- Manage Staff account records.
- Delete Staff accounts through authorized administration.

### 8. Reports & Smart Tools

- Product performance and forecasting.
- Smart Reorder Assistant.
- Sales and inventory insights.
- Low-stock monitoring.

### 9. Responsive Interface

- Modern dark-themed interface.
- Consistent SYNCORA design system.
- Responsive layouts for desktop, tablet, and mobile.
- Dedicated navigation for different user roles.

## Technology Stack

| Technology              | Usage                                   |
| ----------------------- | --------------------------------------- |
| Flutter                 | Frontend application development        |
| Dart                    | Application programming language        |
| Supabase                | Backend services                        |
| PostgreSQL              | Database                                |
| Supabase Authentication | User authentication                     |
| Supabase Edge Functions | Server-side operations                  |
| Netlify                 | Web application hosting                 |
| GitHub                  | Source code management and APK releases |

## User Roles

### Admin

The administrator has access to the main management features, including:

- Dashboard and business overview.
- Product management.
- Inventory management.
- Order management.
- Customer management.
- Employee management.
- Reports and smart inventory tools.

### Staff

Staff members can access operational features, including:

- Staff dashboard.
- Product catalogue and permitted product operations.
- Inventory management.
- Order management.
- Product performance.
- Smart Reorder Assistant.
- Profile management.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- A Supabase project configured for the application

### Installation

1. Clone the repository:

   ```bash
   git clone <https://github.com/jestinjoseph000-netizen/SYNCORA>
   ```

2. Navigate to the project directory:

   ```bash
   cd <internship_project>
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Ensure the Supabase configuration required by the application is set up.

5. Run the application:

   ```bash
   flutter run
   ```

### Build Android APK

To generate a release APK:

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Project Information

**Project Name:** SYNCORA

**Project Title:** Smart Inventory & Order Management System

**Project Type:** Individual Assessment Project

**Framework:** Flutter

**Backend:** Supabase

## Future Scope

- Enhanced inventory analytics.
- Additional reporting capabilities.
- Improved inventory forecasting.
- Further automation of stock management.
- Additional business management integrations.

---

**SYNCORA – Simplifying Inventory. Streamlining Operations.**
