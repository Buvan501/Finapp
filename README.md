# 💰 Financial Buddy – AI-Powered Personal Finance Tracker

> A smart, lightweight, privacy-friendly personal finance app built with Flutter and Flask, powered by on-device AI for financial insights.

---

## 🧩 Overview

**Financial Buddy** is a cross-platform personal finance management app that enables users to:
- Track income & expenses
- Set budgets & savings goals
- Analyze spending habits
- Receive personalized AI-generated financial insights
- (Optional) Auto-extract transactions from SMS like Microsoft SMS Organizer

The app uses a **Flutter frontend**, a **Flask + SQLite backend**, and a **local NLP model (DistilGPT2)** to generate contextual insights based on monthly transaction trends.

---

## 🛠️ Tech Stack

| Layer        | Technologies                           |
|--------------|----------------------------------------|
| Frontend     | Flutter, Dart                          |
| Backend      | Python Flask, SQLite, JWT              |
| AI/NLP       | HuggingFace Transformers (`distilgpt2`)|
| SMS Parsing  | `telephony` plugin (Android)           |
| Security     | JWT Auth, bcrypt password hashing      |
| Hosting      | Local / EC2 / Azure VM (Optional)      |

---

## ⚙️ Features

- 📊 Add and track income & expenses
- 🏷️ Categorize transactions
- 📅 Monthly summary with savings calculation
- 🧠 AI-generated financial insights
- 🎯 Budget & goal setting
- 📩 SMS parsing for auto transaction import (Android)
- 🔒 JWT-based authentication

---

## 🧠 AI Insight Module

The backend compares **previous vs current month**:
- Income & expense trends
- Top spending categories
- Generates one-line insight using `distilgpt2`:

_Example Output_:
> “Your food spending increased this month. Try reducing takeout orders.”

---

## 📲 Screenshots

| Dashboard                        | Add Transaction                     | AI Insight                      |
|----------------------------------|-------------------------------------|---------------------------------|
| ![Dashboard](screenshots/home.png) | ![Add Tx](screenshots/add_tx.png)  | ![Insight](screenshots/insight.png) |

---

## 🗄️ Database Schema

### `User`
- `id`, `name`, `email`, `phone`, `password_hash`

### `Transaction`
- `id`, `user_id`, `type`, `category`, `amount`, `date`, `notes`

### `BudgetCategory`
- `id`, `user_id`, `category`, `budget`

### `Goal`
- `id`, `user_id`, `title`, `target`, `saved`, `date`

---

## 🚀 Getting Started

### ✅ Prerequisites
- Python 3.10+
- Flutter SDK
- Android Studio (for emulator or device testing)

### ⚙️ Backend Setup

```bash
git clone https://github.com/yourusername/financial-buddy.git
cd backend/
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python app.py