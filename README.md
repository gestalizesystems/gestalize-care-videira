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

Gestalize Care is a multi-tenant platform designed to help healthcare providers manage shared workspaces, appointments and operational workflows.

The platform enables clinics to monetize underutilized consultation rooms while allowing independent professionals to reserve fully equipped spaces on demand through a seamless self-service experience.

From scheduling and payments to financial management and operational control, Gestalize Care centralizes the entire reservation lifecycle into a single platform.

## Core Concepts

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

Healthcare professionals increasingly prefer flexible workspaces instead of long-term office leases, while clinics often struggle with idle room capacity and fragmented scheduling processes.

Traditional workflows based on spreadsheets, messaging applications and phone calls frequently lead to booking conflicts, inconsistent payment tracking and unnecessary administrative overhead.

Gestalize Care addresses these challenges by providing an integrated platform for reservations, scheduling, online payments and clinic operations.

## Solution

The platform centralizes availability, booking, and payment in a single flow.

Professionals browse available shifts, add one or more to a cart, and complete the reservation with an online payment. A reservation and its payment are created in a single atomic transaction, which prevents concurrent double booking. If payment is not completed within the allowed window, the slot is automatically released and becomes available again.

Confirmation is handled in real time: once a payment is approved, the reservation is confirmed, the professional is notified, and the corresponding record is updated without manual intervention. Cancellations and changes are governed by clear rules, with balances handled through an internal credit wallet.

## Key Features

### Workspace Booking

- Room reservation management
- Shift-based scheduling
- Recurring availability
- Booking cart
- Automatic conflict prevention

### Payments

- Pix payment integration
- Webhook-based confirmation
- Automatic payment expiration
- Credit wallet
- Refund management

### Practice Management

- Professional management
- Pricing rules
- Resource catalog
- Calendar synchronization
- Administrative dashboard

### Platform

- Multi-tenant architecture
- Background processing
- Role-based authorization
- Audit trail
- Secure authentication

## Architecture Overview

The application follows a server-rendered architecture with real-time interface updates, avoiding the complexity of a separate frontend framework while preserving a responsive user experience.

- **Transactional booking.** Reservations and payments are created atomically with row-level locking to guarantee that a room cannot be booked twice under concurrent load.
- **Asynchronous processing.** Scheduled and background tasks handle payment expiration, recurring availability generation, and calendar synchronization independently of the request cycle.
- **Event-driven confirmation.** Payment status is confirmed through provider callbacks, keeping reservation state consistent with the payment gateway.
- **Domain-oriented services.** Business rules for booking, cancellation, pricing, and credit are encapsulated in dedicated service objects, keeping controllers thin and behavior testable.
- **Authorization and auditing.** Access is enforced per role, and changes to core records are versioned for traceability.

```text
                     Browser
                        │
              Ruby on Rails Application
                        │
        ┌───────────────┼───────────────┐
        │               │               │
 Booking Service   Payment Service   Admin Portal
        │               │               │
        └───────────────┼───────────────┘
                        │
                   PostgreSQL
                        │
             Redis + Sidekiq Workers
                        │
      Payment Gateway • Calendar APIs
```

## Technology Stack

| Layer | Technology |
|---|---|
| Application framework | Ruby on Rails |
| Database | PostgreSQL |
| Interface | Hotwire (Turbo and Stimulus), Tailwind CSS |
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
├── javascript/

config/

db/

spec/
```

## Screenshots

_Screenshots to be added._

## Roadmap

### Current

- Room reservations
- Online payments
- Credit wallet
- Financial dashboard
- Calendar synchronization

### Next

- Multi-tenant workspaces
- Notifications center
- Reporting module
- Public API
- Mobile application

## License

Proprietary. All rights reserved.
