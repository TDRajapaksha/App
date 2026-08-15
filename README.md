# 🎨 METAL ART - Handcrafted Metal Art E-Commerce App

**METAL ART** is a fully functional, cross-platform e-commerce mobile application built with **Flutter** and **Dart**, backed by **Supabase** as the BaaS (Backend-as-a-Service). The app serves as an online marketplace for unique, handcrafted steel and metal art pieces, providing a seamless shopping experience from browsing to checkout.

---

## 📖 Project Overview
This application simulates a real-world e-commerce environment. Users can browse through curated collections of metal art, view product details, manage their cart, place orders, and track their purchase history. The app integrates robust backend services for data persistence, user authentication, and real-time order management.

---

## 🚀 Key Features
*   **User Authentication**: Secure login and registration system with validation (passwords, email format, terms agreement).
*   **Dynamic Product Browsing**: Categorized product listings (Sales, New Arts, Animal Arts) displayed in horizontal scrollable cards.
*   **Product Details**: In-depth view of each art piece with high-quality images, pricing, and descriptions.
*   **Smart Shopping Cart**:
    *   Syncs cart items with Supabase for logged-in users.
    *   Local fallback cart mechanism ensures items remain saved even if Supabase connectivity is temporarily interrupted.
*   **Seamless Checkout**: Multi-step checkout process with support for multiple payment methods (Cash on Delivery, Credit/Debit Card, Mobile Wallet, Bank Transfer). Detailed breakdown of subtotal, taxes, and shipping fees.
*   **Order Management**: Users can view all placed orders, monitor order status (Pending, Shipped, Delivered), and cancel orders if they haven't been shipped.
*   **Address Management**: Full CRUD (Create, Read, Update, Delete) operations for user shipping addresses with the ability to set a "Default" address.
*   **Help & Support**: Integrated FAQ section (accordion style) and a ticket submission form for customer support.
*   **User Profile**: Personalized dashboard displaying user details, member since date, and quick access to orders, addresses, and support.

---

## 🛠️ Tech Stack & Tools
| Component | Technology |
| :--- | :--- |
| **Frontend** | Flutter (Dart) |
| **Backend Database** | Supabase (PostgreSQL) |
| **State Management** | Flutter Stateful Widgets & `setState` |
| **API Client** | `supabase_flutter` SDK |
| **Data Types** | JSON & Typed Models (e.g., `Product`, `UserSession`) |
| **Database Tables** | `users`, `itemsT`, `user_cart`, `orders`, `order_items`, `user_addresses`, `support_tickets` |

---

## 📸 Application Screenshots
*(To view these images, save your screenshots in a `screenshots/` folder in your GitHub repository with the exact names listed below)*

| Login & Registration | Home & Browsing |
| :---: | :---: |
| ![Login](screenshots/login.png) | ![Home](screenshots/home.png) |
| **Product Details & Cart** | **Checkout & Orders** |
| ![Product Details](screenshots/product_details.png) | ![Cart Checkout](screenshots/cart_checkout.png) |
| **Profile & Settings** | **Help & Support** |
| ![Profile](screenshots/profile.png) | ![Help & Support](screenshots/help_support.png) |
| **Address Management** | **Supabase Dashboard** |
| ![Address Form](screenshots/address_form.png) | ![Supabase Dashboard](screenshots/supabase_dashboard.png) |

---

## 🗄️ Database Schema (Supabase)
The project leverages a PostgreSQL database hosted on Supabase. The core tables utilized are:
*   **`users`**: Stores user credentials (`f_name`, `l_name`, `email`, `pw`, `phone`, `is_admin`, `is_active`).
*   **`itemsT`**: Contains inventory data for products (`item_name`, `price`, `description`, `image`).
*   **`user_cart`**: Links products to users (`user_id`, `product_id`, `quantity`).
*   **`orders`**: Stores order headers (`user_id`, `total_amount`, `order_status`, `shipping_address`, `payment_method`).
*   **`order_items`**: Stores line items for each order (`order_id`, `product_id`, `quantity`, `price`).
*   **`user_addresses`**: Stores shipping addresses (`address_line1`, `city`, `state`, `zip_code`, `phone`, `is_default`).
*   **`support_tickets`**: Logs user support requests (`subject`, `message`, `category`, `priority`).

*(Note: Row Level Security (RLS) policies should be configured in Supabase to protect user data).*

---

## 📂 Project Structure
```text
lib/
├── main.dart                 # App entry point & Supabase initialization
├── home.dart                 # Main homepage, navigation, and product lists
├── cart.dart                 # Local cart singleton & CartPage UI
├── product_details.dart      # Detailed view of a product & add to cart logic
├── orders_page.dart          # View order history and cancel orders
├── profile.dart              # User profile menu and logout
├── register.dart             # User registration page
├── saved_addresses_page.dart # CRUD operations for shipping addresses
├── help_support_page.dart    # FAQs and support ticket submission
├── user_session.dart         # Singleton for managing logged-in user data
├── wishlist_page.dart        # (Stub) Future wishlist integration
└── services/
    └── supabase_service.dart # Helper class for Supabase API interactions
