<div align="center">

# Gestalize Care


### Healthcare Workspace Booking & Practice Management Platform

A unified platform for managing room reservations, scheduling, online payments and operational workflows for clinics and independent healthcare professionals.

<br>

![Ruby](https://img.shields.io/badge/RUBY-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Ruby on Rails](https://img.shields.io/badge/RAILS-CC0000?style=for-the-badge&logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/POSTGRESQL-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![Hotwire](https://img.shields.io/badge/HOTWIRE-FF5F1F?style=for-the-badge)
![Tailwind CSS](https://img.shields.io/badge/TAILWIND_CSS-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)

<br>

Developed by **Gestalize Systems**

</div>

---

## Overview

Gestalize Care is a multi-tenant SaaS platform that enables healthcare organizations to manage consultation rooms, workspace reservations and operational workflows through a unified system.

Designed for clinics and independent healthcare professionals, the platform combines scheduling, online payments, financial management and administrative tools into a seamless booking experience.

## Business Model

| Entity | Description |
|----------|-------------|
| Clinic | Healthcare organization offering consultation rooms |
| Professional | Independent healthcare provider |
| Workspace | Consultation room available for reservation |
| Shift | Time slot available for booking |
| Reservation | Booking made by a professional |
| Wallet | Internal balance used for credits and refunds |
| Payment | Transaction associated with a reservation |

## Why Gestalize Care?

Gestalize Care was designed around a simple idea: consultation rooms should be as easy to reserve as meeting rooms.

Instead of relying on spreadsheets, messaging applications and manual coordination, clinics can automate room availability, payments, reservations and operational workflows while maximizing workspace utilization.

Healthcare professionals benefit from a modern self-service booking experience, allowing them to reserve fully equipped consultation rooms whenever they need them.

## Solution

Professionals browse available consultation rooms, select one or more shifts, complete the reservation through an integrated payment flow and receive confirmation automatically.

Meanwhile, clinics manage availability, pricing, professionals, reservations and financial operations from a centralized administrative portal, reducing manual work and improving workspace utilization.

## Key Features

### Reservations

- Room reservation management
- Shift-based scheduling
- Recurring availability
- Booking cart
- Automatic conflict prevention

### Operations

- Professional management
- Pricing rules
- Resource catalog
- Calendar synchronization
- Administrative dashboard

### Payments

- Pix payment integration
- Webhook-based confirmation
- Automatic payment expiration
- Credit wallet
- Refund management

### Platform

- Multi-tenant architecture
- Background processing
- Role-based authorization
- Audit trail
- Secure authentication

## Architecture

The application follows a server-rendered architecture with real-time interface updates, avoiding the complexity of a separate frontend framework while preserving a responsive user experience.

- **Transactional booking.** Reservations and payments are created atomically with row-level locking to guarantee that a room cannot be booked twice under concurrent load.
- **Asynchronous processing.** Scheduled and background tasks handle payment expiration, recurring availability generation, and calendar synchronization independently of the request cycle.
- **Event-driven confirmation.** Payment status is confirmed through provider callbacks, keeping reservation state consistent with the payment gateway.
- **Domain-oriented services.** Business rules for booking, cancellation, pricing, and credit are encapsulated in dedicated service objects, keeping controllers thin and behavior testable.
- **Authorization and auditing.** Access is enforced per role, and changes to core records are versioned for traceability.

```text
                        Healthcare Professional
                                  │
                                  ▼
                     Ruby on Rails Application
                                  │
        ┌─────────────┬───────────┴─────────────┬─────────────┐
        │             │                         │             │
        ▼             ▼                         ▼             ▼
   Reservations    Payments              Administration   Scheduling
        │             │                         │
        └─────────────┴───────────┬─────────────┘
                                  ▼
                            PostgreSQL Database
                                  │
                 ┌────────────────┴────────────────┐
                 ▼                                 ▼
         Redis / Sidekiq                  External Services
                                                   │
                         ┌─────────────────────────┴─────────────────────────┐
                         ▼                                                   ▼
                  Payment Gateway                                   Calendar APIs
```

## Technology Stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails |
| Database | PostgreSQL |
| Frontend | Hotwire (Turbo and Stimulus), Tailwind CSS |
| Background processing | Sidekiq, Redis |
| Authentication | Devise, OmniAuth (Google) |
| Authorization | Pundit |
| Auditing | PaperTrail |
| Payments | Pix payment gateway integration |
| Testing | RSpec, Capybara |

## Project Structure

```text
app/
├── controllers/
├── models/
├── services/
├── policies/
├── jobs/
├── mailers/
├── views/
└── javascript/

config/
db/
spec/
```

## Screenshots

_Screenshots to be added._

## Roadmap

### Completed

- Room reservations
- Online payments
- Credit wallet
- Financial dashboard
- Calendar synchronization

### Plannd

- Multi-tenant workspaces
- Notifications center
- Reporting module
- Public API
- Mobile application

## License

Gestalize Care is proprietary software developed and maintained by Gestalize Systems. All rights reserved.
