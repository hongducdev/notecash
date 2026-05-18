````md
# NoteCash

Minimal expense tracking app built with Flutter.

---

## Overview

NoteCash is a modern expense tracking mobile app focused on speed, simplicity, and clean user experience.

Instead of filling complex forms, users can quickly type expenses naturally:

```txt
cf 35k
grab 120k
ăn sáng 45k
````

NoteCash automatically parses the amount, categorizes the expense, and saves it instantly.

The app is designed to feel lightweight, fast, and distraction-free.

---

# Core Philosophy

* Fast input over complicated forms
* Minimal UI over overloaded dashboards
* Offline-first experience
* Smooth animations and premium interactions
* Dark mode first

---

# Features

## Quick Expense Input

Natural text-based expense logging.

Example:

```txt
cf 35k
```

Automatically becomes:

* Category: Food & Drink
* Amount: ₫35,000

---

## Smart Categorization

Automatic category detection using:

* keyword matching
* parser rules
* future AI categorization support

Categories include:

* Food & Drink
* Transport
* Shopping
* Bills
* Entertainment

---

## Dashboard

Simple and clean overview:

* Today spending
* Monthly spending
* Weekly chart
* Recent transactions

---

## Offline First

All data is stored locally for:

* instant performance
* offline usage
* better privacy

---

## Beautiful Dark Mode

Minimal dark interface inspired by modern fintech products.

Features:

* soft gradients
* smooth transitions
* subtle blur effects
* typography-focused layout

---

# Tech Stack

## Frontend

* Flutter

## State Management

* Riverpod

## Local Database

* Isar Database

## Navigation

* go_router

## Charts

* fl_chart

---

# UI Style

Inspired by:

* Linear
* Notion
* Copilot Money
* Monarch Money

Design principles:

* large typography
* spacious layout
* minimal cards
* smooth micro animations

---

# App Structure

```txt
lib/
 ├── core/
 ├── features/
 │    ├── expense/
 │    ├── dashboard/
 │    ├── settings/
 │
 ├── services/
 ├── shared/
 └── main.dart
```

---

# Expense Model

```dart
class Expense {
  Id id;

  String note;

  double amount;

  DateTime createdAt;

  ExpenseCategory category;

  bool isIncome;
}
```

---

# Future Features

## V2

* Cloud sync
* Budget planning
* Widgets
* Recurring expenses
* Export Excel

## V3

* AI spending insights
* OCR receipt scanner
* Voice input
* Smart monthly summaries

---

# Branding

## Name

NoteCash

## Tagline

Track money effortlessly.

---

# Goals

NoteCash aims to make expense tracking:

* fast
* personal
* elegant
* enjoyable to use daily

Instead of behaving like accounting software, NoteCash focuses on delivering a smooth and modern mobile experience.

```
```
