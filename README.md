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

Videira Clinic is a booking and management platform that enables dental professionals to rent fully equipped clinic rooms by shift. It covers the complete workflow: browsing availability, building a booking, paying online, and receiving automatic confirmation.

Clinic administrators manage schedules, pricing, clients, add-on items, and finances through a dedicated administrative area. The platform is designed for reliability under concurrent access, ensuring that a room is never booked twice and that a reservation is only confirmed once payment is settled.

## Business Problem

Independent dental professionals frequently need occasional access to a fully equipped office without committing to a long-term lease. At the same time, clinics have idle capacity during shifts that are not fully booked.

Traditional coordination relies on messaging apps and manual agendas, which introduces recurring problems:

- Double bookings and scheduling conflicts.
- No guarantee of payment before the appointment.
- No structured record of reservations, cancellations, or refunds.
- Time-consuming manual management of availability and pricing.

## Solution

The platform centralizes availability, booking, and payment in a single flow.

Professionals browse available shifts, add one or more to a cart, and complete the reservation with an online payment. A reservation and its payment are created in a single atomic transaction, which prevents concurrent double booking. If payment is not completed within the allowed window, the slot is automatically released and becomes available again.

Confirmation is handled in real time: once a payment is approved, the reservation is confirmed, the professional is notified, and the corresponding record is updated without manual intervention. Cancellations and changes are governed by clear rules, with balances handled through an internal credit wallet.

## Key Features

- **Shift-based scheduling.** Availability organized by shift, with recurring templates that generate future availability automatically.
- **Cart and single-transaction checkout.** Multiple shifts booked and paid in one operation.
- **Online payments via Pix.** Automatic, webhook-driven confirmation.
- **Automatic slot release.** Unpaid reservations expire and free the room without manual action.
- **Credit wallet.** Cancellations and adjustments are settled as account credit, applied automatically to future bookings.
- **Add-on catalog.** Optional items and consumables that can be attached to a reservation.
- **Flexible discounts.** Volume-based rules and individual per-client discounts.
- **Booking changes and cancellations.** Rule-based windows, with automatic credit or additional charge for price differences.
- **Calendar integration.** Confirmed reservations are synced to the clinic calendar and shared with the client.
- **Financial dashboard.** Monthly view of revenue by category and outstanding credit.
- **Administrative area.** Management of clinics, schedules, clients, pricing, add-ons, reservations, and payments.
- **Audit trail.** Full history of changes across core records.
- **Authentication.** Email and social sign-in, with mandatory email verification.
- **Security controls.** Rate limiting, request protection, and enforced transport security.

## Architecture Overview

The application follows a server-rendered architecture with real-time interface updates, avoiding the complexity of a separate frontend framework while preserving a responsive user experience.

- **Transactional booking.** Reservations and payments are created atomically with row-level locking to guarantee that a room cannot be booked twice under concurrent load.
- **Asynchronous processing.** Scheduled and background tasks handle payment expiration, recurring availability generation, and calendar synchronization independently of the request cycle.
- **Event-driven confirmation.** Payment status is confirmed through provider callbacks, keeping reservation state consistent with the payment gateway.
- **Domain-oriented services.** Business rules for booking, cancellation, pricing, and credit are encapsulated in dedicated service objects, keeping controllers thin and behavior testable.
- **Authorization and auditing.** Access is enforced per role, and changes to core records are versioned for traceability.

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

High-level organization of the application:

```
app/
  controllers/    Request handling for public, client, and administrative areas
  models/         Domain entities and validations
  services/       Business logic (booking, pricing, cancellation, credit, payments)
  jobs/           Background and scheduled tasks
  views/          Server-rendered interface with real-time components
```

## Screenshots

_Screenshots to be added._

## Future Improvements

- Multi-clinic support with isolated administration per tenant.
- Reporting and export tools for financial reconciliation.
- Configurable notification channels.
- Public API for third-party integrations.

## License

Proprietary. All rights reserved.
